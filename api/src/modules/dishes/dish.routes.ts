import { Router } from 'express';
import { DishController } from './dish.controller';
import { authenticate } from '../../common/middlewares/auth.middleware';
import { authorize } from '../../common/middlewares/role.middleware';
import { validate } from '../../common/middlewares/validate.middleware';
import { createDishSchema, updateDishSchema } from './dish.schema';

export const dishRoutes = Router();

// 1. Lecture du catalogue (Utilisateurs connectés : étudiants, personnel, admin)
dishRoutes.get('/', authenticate, DishController.list);
dishRoutes.get('/:id', authenticate, DishController.getById);

// 2. Gestion du catalogue (Réservé strictement à l'Administrateur - Règle RG11)
dishRoutes.post('/', authenticate, authorize('admin'), validate(createDishSchema), DishController.create);
dishRoutes.patch('/:id', authenticate, authorize('admin'), validate(updateDishSchema), DishController.update);
