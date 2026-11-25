import { Router } from 'express';
import { MenuController } from './menu.controller';
import { authenticate } from '../../common/middlewares/auth.middleware';
import { authorize } from '../../common/middlewares/role.middleware';
import { validate } from '../../common/middlewares/validate.middleware';
import { createMenuSchema, updateMenuSchema } from './menu.schema';

export const menuRoutes = Router();

// Consultation du menu (Tous les utilisateurs authentifiés)
menuRoutes.get('/', authenticate, MenuController.getByDate);

// Création et publication (Réservé administrateur - Règle RG11)
menuRoutes.post('/', authenticate, authorize('admin'), validate(createMenuSchema), MenuController.create);
menuRoutes.patch('/:id', authenticate, authorize('admin'), validate(updateMenuSchema), MenuController.update);
