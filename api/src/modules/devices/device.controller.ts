import { Request, Response } from 'express';
import { Device } from './device.model';
import { Types } from 'mongoose';
import { asyncHandler } from '../../utils/asyncHandler';

/** Enregistre ou met à jour le token FCM d’un utilisateur */
export const registerDevice = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { fcmToken } = req.body;

  if (!fcmToken) {
    return res.status(400).json({ message: 'FCM token is required' });
  }

  const device = await Device.findOneAndUpdate(
    { userId: new Types.ObjectId(userId) },
    { fcmToken },
    { upsert: true, new: true }
  );

  res.status(201).json(device);
});
