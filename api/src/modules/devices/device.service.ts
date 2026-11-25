import { Types } from 'mongoose';
import { Device } from './device.model';

export class DeviceService {
  static registerForUser(userId: string, fcmToken: string) {
    return Device.findOneAndUpdate(
      { userId: new Types.ObjectId(userId) },
      { fcmToken },
      { upsert: true, new: true, runValidators: true },
    );
  }
}
