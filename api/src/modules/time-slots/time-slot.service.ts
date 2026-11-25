import { AppError } from '../../common/errors/app-error';
import { CreateTimeSlotDTO, UpdateTimeSlotDTO } from './time-slot.schema';
import { ITimeSlot, TimeSlot } from './time-slot.model';

function currentDateAndTime() {
  const now = new Date();
  return {
    date: now.toISOString().slice(0, 10),
    time: now.toISOString().slice(11, 16),
  };
}

function isBookable(slot: Pick<ITimeSlot, 'date' | 'startTime'>) {
  const now = currentDateAndTime();
  return slot.date > now.date || (slot.date === now.date && slot.startTime > now.time);
}

export class TimeSlotService {
  static async listByDate(date: string) {
    const slots = await TimeSlot.find({ date }).sort({ startTime: 1 }).lean();
    return slots.map((slot) => ({
      ...slot,
      id: slot._id.toString(),
      remainingPlaces: Math.max(0, slot.capacity - slot.reservedCount),
    }));
  }

  static async create(input: CreateTimeSlotDTO): Promise<ITimeSlot> {
    try {
      return await TimeSlot.create(input);
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        throw AppError.conflict('Un créneau existe déjà à cette date et heure.', 'TIME_SLOT_EXISTS');
      }
      throw error;
    }
  }

  static async update(id: string, input: UpdateTimeSlotDTO): Promise<ITimeSlot> {
    const current = await TimeSlot.findById(id);
    if (!current) throw AppError.notFound('Créneau introuvable.');

    const nextStartTime = input.startTime ?? current.startTime;
    const nextEndTime = input.endTime ?? current.endTime;
    if (nextStartTime >= nextEndTime) {
      throw AppError.unprocessable('L’heure de fin doit être postérieure à l’heure de début.');
    }

    const filter: Record<string, unknown> = { _id: id };
    if (input.capacity !== undefined) {
      // La capacité ne peut jamais être abaissée sous le nombre déjà réservé.
      filter.$expr = { $lte: ['$reservedCount', input.capacity] };
    }

    try {
      const updated = await TimeSlot.findOneAndUpdate(filter, { $set: input }, {
        new: true,
        runValidators: true,
      });
      if (updated) return updated;

      const stillExists = await TimeSlot.exists({ _id: id });
      if (!stillExists) throw AppError.notFound('Créneau introuvable.');
      throw AppError.conflict('La capacité ne peut pas être inférieure aux réservations existantes.', 'CAPACITY_BELOW_RESERVED');
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        throw AppError.conflict('Un créneau existe déjà à cette date et heure.', 'TIME_SLOT_EXISTS');
      }
      throw error;
    }
  }

  /** Réservation atomique utilisée par la création de commande (RG03). */
  static async reserveSlotAtomically(slotId: string): Promise<ITimeSlot> {
    const now = currentDateAndTime();
    const slot = await TimeSlot.findOneAndUpdate(
      {
        _id: slotId,
        $expr: { $lt: ['$reservedCount', '$capacity'] },
        $or: [
          { date: { $gt: now.date } },
          { date: now.date, startTime: { $gt: now.time } },
        ],
      },
      { $inc: { reservedCount: 1 } },
      { new: true }
    );

    if (slot) return slot;

    const existing = await TimeSlot.findById(slotId).lean();
    if (!existing) throw AppError.notFound('Créneau introuvable.');
    if (!isBookable(existing)) {
      throw AppError.conflict('Ce créneau est déjà commencé ou passé.', 'SLOT_STARTED');
    }
    throw AppError.conflict('Ce créneau horaire est complet.', 'SLOT_FULL');
  }

  /** Libération atomique sans jamais autoriser reservedCount à devenir négatif. */
  static async releaseSlotAtomically(slotId: string): Promise<void> {
    await TimeSlot.findOneAndUpdate(
      { _id: slotId, reservedCount: { $gt: 0 } },
      { $inc: { reservedCount: -1 } }
    );
  }
}

function isDuplicateKeyError(error: unknown): error is { code: number } {
  return typeof error === 'object' && error !== null && 'code' in error && error.code === 11000;
}

// Export these named helpers for direct use by the orders module.
export const reserveSlotAtomically = TimeSlotService.reserveSlotAtomically;
export const releaseSlotAtomically = TimeSlotService.releaseSlotAtomically;