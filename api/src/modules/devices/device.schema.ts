import { z } from 'zod';

export const registerDeviceSchema = z.object({
  fcmToken: z.string().trim().min(1, 'Le jeton FCM est requis').max(4096),
});
