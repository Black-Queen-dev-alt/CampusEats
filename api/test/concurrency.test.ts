import mongoose from "mongoose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { MongoMemoryServer } from "mongodb-memory-server";
import { AppError } from "../src/common/errors/app-error";
import { TimeSlot } from "../src/modules/time-slots/time-slot.model";
import { reserveSlotAtomically } from "../src/modules/time-slots/time-slot.service";

let mongo: MongoMemoryServer;

describe("TimeSlot atomic concurrency (MongoDB integration)", () => {
  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    await mongoose.connect(mongo.getUri());
    await TimeSlot.init();
  }, 60_000);

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  it("ne dépasse jamais la capacité avec 50 réservations simultanées", async () => {
    const date = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
    const slot = await TimeSlot.create({
      date,
      startTime: "12:00",
      endTime: "12:15",
      capacity: 9,
    });

    try {
      const results = await Promise.allSettled(
        Array.from({ length: 50 }, () => reserveSlotAtomically(slot.id)),
      );
      const successes = results.filter(
        (result) => result.status === "fulfilled",
      );
      const failures = results.filter(
        (result) => result.status === "rejected",
      );
      const rejectedWithFull = failures.filter(
        (result) =>
          result.status === "rejected" &&
          result.reason instanceof AppError &&
          result.reason.code === "SLOT_FULL",
      );
      const persisted = await TimeSlot.findById(slot.id).orFail();

      expect(successes).toHaveLength(slot.capacity);
      expect(failures).toHaveLength(50 - slot.capacity);
      expect(rejectedWithFull).toHaveLength(failures.length);
      expect(persisted.reservedCount).toBe(slot.capacity);
      expect(persisted.reservedCount).toBeLessThanOrEqual(persisted.capacity);
    } finally {
      await TimeSlot.deleteOne({ _id: slot._id });
    }
  }, 30_000);
});
