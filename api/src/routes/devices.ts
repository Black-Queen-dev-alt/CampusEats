import { Router } from 'express';
import { registerDevice } from '../modules/devices/device.controller';
import { authorize } from '../modules/auth/auth.middleware';

const router = Router();

/**
 * POST /devices
 *  - rôles autorisés : student, personnel, admin
 *  - body : { fcmToken: string }
 */
router.post('/', authorize(['student', 'personnel', 'admin']), registerDevice);

export default router;
