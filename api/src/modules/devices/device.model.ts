import { Schema, model, Document, Types } from 'mongoose';

export interface DeviceDocument extends Document {
  userId: Types.ObjectId;
  fcmToken: string;
  createdAt: Date;
  updatedAt: Date;
}

const DeviceSchema = new Schema<DeviceDocument>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    fcmToken: { type: String, required: true },
  },
  { timestamps: true }
);

export const Device = model<DeviceDocument>('Device', DeviceSchema);
