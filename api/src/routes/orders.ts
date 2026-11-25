import { Router } from 'express';
import {
  createOrder,
  getMyOrders,
  cancelOrder,
  getSlotOrders,
  updateOrderStatus,
} from '../modules/orders/order.controller';
import { authorize } from '../modules/auth/auth.middleware';
import { validate, validateParams, validateQuery } from '../common/middlewares/validate.middleware';
import {
  createOrderSchema,
  listOrdersQuerySchema,
  listSlotOrdersQuerySchema,
  orderIdParamsSchema,
  updateOrderStatusSchema,
} from '../modules/orders/order.schema';

const router = Router();
export const slotOrdersRouter = Router();

/* Étudiant – créer une commande */
router.post('/', ...authorize(['etudiant']), validate(createOrderSchema), createOrder);

/* Étudiant – historique paginé */
router.get('/', ...authorize(['etudiant']), validateQuery(listOrdersQuerySchema), getMyOrders);

/* Étudiant – annuler sa propre commande */
router.post(
  '/:id/cancel',
  ...authorize(['etudiant']),
  validateParams(orderIdParamsSchema),
  cancelOrder,
);

/* Personnel / admin – lister les commandes d’un créneau */
slotOrdersRouter.get(
  '/:id/orders',
  ...authorize(['personnel', 'admin']),
  validateParams(orderIdParamsSchema),
  validateQuery(listSlotOrdersQuerySchema),
  getSlotOrders,
);

/* Personnel / admin – changer le statut d’une commande */
router.patch(
  '/:id/status',
  ...authorize(['personnel', 'admin']),
  validateParams(orderIdParamsSchema),
  validate(updateOrderStatusSchema),
  updateOrderStatus,
);

export default router;
