import { Router } from 'express';
import {
  createOrder,
  getMyOrders,
  cancelOrder,
  getSlotOrders,
  updateOrderStatus,
} from '../modules/orders/order.controller';
import { authorize } from '../modules/auth/auth.middleware';

const router = Router();

/* Étudiant – créer une commande */
router.post('/', authorize(['student']), createOrder);

/* Étudiant – historique paginé */
router.get('/', authorize(['student']), getMyOrders);

/* Étudiant – annuler sa propre commande */
router.post('/:id/cancel', authorize(['student']), cancelOrder);

/* Personnel / admin – lister les commandes d’un créneau */
router.get(
  '/time-slots/:id/orders',
  authorize(['personnel', 'admin']),
  getSlotOrders
);

/* Personnel / admin – changer le statut d’une commande */
router.patch('/:id/status', authorize(['personnel', 'admin']), updateOrderStatus);

export default router;
