import mongoose, { Document, Schema } from "mongoose";

export interface ITimeSlot extends Document {
  date: string;
  startTime: string;
  endTime: string;
  capacity: number;
  reservedCount: number;
  createdAt: Date;
  updatedAt: Date;
}

const TimeSlotSchema = new Schema<ITimeSlot>(
  {
    date: { type: String, required: true, match: /^\d{4}-\d{2}-\d{2}$/ },
    startTime: {
      type: String,
      required: true,
      match: /^([01]\d|2[0-3]):[0-5]\d$/,
    },
    endTime: {
      type: String,
      required: true,
      match: /^([01]\d|2[0-3]):[0-5]\d$/,
    },
    capacity: {
      type: Number,
      required: true,
      min: 1,
      validate: Number.isInteger,
    },
    reservedCount: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
      validate: Number.isInteger,
    },
  },
  { timestamps: true },
);

TimeSlotSchema.index({ date: 1, startTime: 1 }, { unique: true });

export const TimeSlot = mongoose.model<ITimeSlot>("TimeSlot", TimeSlotSchema);
