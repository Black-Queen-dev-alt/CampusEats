import { Router } from 'express';
import { registerDevice } from '../modules/devices/device.controller';
import { authorize } from '../modules/auth/auth.middleware';
import { validate } from '../common/middlewares/validate.middleware';
import { registerDeviceSchema } from '../modules/devices/device.schema';

const router = Router();

/**
 * POST /devices
 *  - rôles autorisés : student, personnel, admin
 *  - body : { fcmToken: string }
 */
router.post(
  '/',
  ...authorize(['etudiant', 'personnel', 'admin']),
  validate(registerDeviceSchema),
  registerDevice,
);

export default router;
