import { Request, Response } from 'express';
import { asyncHandler } from '../../utils/asyncHandler';
import { DeviceService } from './device.service';

/** Enregistre ou met à jour le token FCM d’un utilisateur */
export const registerDevice = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { fcmToken } = req.body;
  const device = await DeviceService.registerForUser(userId, fcmToken);

  res.status(200).json({ success: true, data: device });
});
