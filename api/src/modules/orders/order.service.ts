// src/modules/orders/order.service.ts
import { Types } from 'mongoose';
import { Order, OrderDocument, OrderStatus } from './order.model';
import { sendPushNotification } from '../../utils/notifications';

// Types d’entrée pour chaque méthode du service
export interface CreateOrderParams {
  studentId: Types.ObjectId;
  slotId: Types.ObjectId;
  menuId: Types.ObjectId;
  lines: { dishId: Types.ObjectId; quantity: number }[];
}
export interface GetStudentOrdersParams {
  studentId: Types.ObjectId;
  page: number;
  limit: number;
}
export interface CancelOrderParams {
  orderId: Types.ObjectId;
  requesterId: Types.ObjectId;
}
export interface GetSlotOrdersParams {
  slotId: Types.ObjectId;
  status?: string;
  page: number;
  limit: number;
}
export interface UpdateStatusParams {
  orderId: Types.ObjectId;
  newStatus: OrderStatus;
  requesterId: Types.ObjectId;
}

export const OrderService = {
  /** Crée une nouvelle commande */
  async createOrder({ studentId, slotId, menuId, lines }: CreateOrderParams) {
    const order = await Order.create({ studentId, slotId, menuId, lines });
    return order;
  },

  /** Récupère les commandes d’un étudiant avec pagination */
  async getStudentOrders({ studentId, page, limit }: GetStudentOrdersParams) {
    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      Order.find({ studentId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments({ studentId }),
    ]);
    return { orders, total, page, limit };
  },

  /** Annule une commande (seul le propriétaire peut le faire) */
  async cancelOrder({ orderId, requesterId }: CancelOrderParams) {
    const order = await Order.findById(orderId);
    if (!order) throw new Error('Order not found');
    if (!order.studentId.equals(requesterId)) {
      throw new Error('Not authorized to cancel this order');
    }
    order.status = 'cancelled';
    await order.save();
    // TODO: libérer la capacité du créneau si besoin
  },

  /** Liste les commandes d’un créneau, éventuellement filtrées par statut */
  async getSlotOrders({ slotId, status, page, limit }: GetSlotOrdersParams) {
    const query: any = { slotId };
    if (status) query.status = status;
    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      Order.find(query).skip(skip).limit(limit).lean(),
      Order.countDocuments(query),
    ]);
    return { orders, total, page, limit };
  },

  /** Met à jour le statut d’une commande en respectant le workflow strict */
  async updateStatus({ orderId, newStatus, requesterId }: UpdateStatusParams) {
    const order = await Order.findById(orderId);
    if (!order) throw new Error('Order not found');

    const allowedTransitions: Record<OrderStatus, OrderStatus[]> = {
      received: ['preparing', 'cancelled'],
      preparing: ['ready', 'cancelled'],
      ready: ['withdrawn'],
      withdrawn: [],
      cancelled: [],
    };
    if (!allowedTransitions[order.status].includes(newStatus)) {
      throw new Error(`Transition from ${order.status} to ${newStatus} not allowed`);
    }

    order.status = newStatus;
    await order.save();

    // Envoi de la notification push quand le statut devient « ready »
    if (newStatus === 'ready') {
      await sendPushNotification({
        token: order.studentId.toHexString(), // ici on utilise l’id étudiant comme token factice
        title: 'Votre repas est prêt !',
        body: 'Rendez‑vous à la cantine pour le récupérer.',
      });
    }

    return order;
  },
};
