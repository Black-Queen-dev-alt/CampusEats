import { Router } from 'express';
import { UserController } from './user.controller';
import { authenticate } from '../../common/middlewares/auth.middleware';
import { authorize } from '../../common/middlewares/role.middleware';
import { validate } from '../../common/middlewares/validate.middleware';
import { updateProfileSchema, createStaffOrAdminSchema, updateUserStatusSchema } from './user.schema';

export const userRoutes = Router();

// Routes pour l'utilisateur connecté
userRoutes.get('/me', authenticate, UserController.getMe);
userRoutes.patch('/me', authenticate, validate(updateProfileSchema), UserController.updateMe);

// Routes d'administration (réservées au rôle 'admin')
userRoutes.post(
  '/admin/users',
  authenticate,
  authorize('admin'),
  validate(createStaffOrAdminSchema),
  UserController.createStaff
);

userRoutes.patch(
  '/admin/users/:id/status',
  authenticate,
  authorize('admin'),
  validate(updateUserStatusSchema),
  UserController.updateStatus
);
