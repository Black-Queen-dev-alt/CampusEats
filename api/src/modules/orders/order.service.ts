// src/modules/orders/order.service.ts
import { Types } from 'mongoose';
import { Order, OrderDocument, OrderStatus } from './order.model';
import { sendPushNotification } from '../../utils/notifications';
import { AppError } from '../../common/errors/app-error';
import { Menu } from '../menus/menu.model';
import { TimeSlot } from '../time-slots/time-slot.model';
import { reserveSlotAtomically, releaseSlotAtomically } from '../time-slots/time-slot.service';
import { Dish } from '../dishes/dish.model';
import { releaseMenuStock, reserveMenuStockAtomically } from '../menus/menu.service';
import { Device } from '../devices/device.model';

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
export interface GetStudentOrderParams {
  orderId: Types.ObjectId;
  studentId: Types.ObjectId;
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
}

export const OrderService = {
  /** Crée une nouvelle commande */
  async createOrder({ studentId, slotId, menuId, lines }: CreateOrderParams) {
    const menu = await Menu.findById(menuId);
    if (!menu) throw AppError.notFound('Menu introuvable.');
    if (!menu.isPublished) throw AppError.conflict('Ce menu n’est pas publié.', 'MENU_NOT_PUBLISHED');

    const quantitiesByDish = new Map<string, { dishId: Types.ObjectId; quantity: number }>();
    for (const line of lines) {
      const key = line.dishId.toHexString();
      const existing = quantitiesByDish.get(key);
      quantitiesByDish.set(key, {
        dishId: line.dishId,
        quantity: (existing?.quantity ?? 0) + line.quantity,
      });
    }

    const menuDishIds = menu.items.map((item) =>
      item.dishId instanceof Types.ObjectId ? item.dishId : item.dishId._id,
    );
    const dishes = await Dish.find({
      _id: { $in: [...quantitiesByDish.values()].map(({ dishId }) => dishId) },
      isActive: true,
    })
      .select('_id name priceInCents')
      .lean();
    if (dishes.length !== quantitiesByDish.size) {
      throw AppError.unprocessable('Un ou plusieurs plats sont introuvables ou inactifs.');
    }
    const dishesById = new Map(dishes.map((dish) => [dish._id.toString(), dish]));

    for (const { dishId } of quantitiesByDish.values()) {
      if (!menuDishIds.some((menuDishId) => menuDishId.equals(dishId))) {
        throw new AppError(
          422,
          'Un plat demandé ne figure pas dans le menu.',
          'DISH_NOT_IN_MENU',
        );
      }
    }
    const orderLines = lines.map((line) => {
      const dish = dishesById.get(line.dishId.toHexString());
      if (!dish) {
        throw AppError.unprocessable('Un ou plusieurs plats sont introuvables ou inactifs.');
      }
      return {
        ...line,
        dishName: dish.name,
        unitPriceInCents: dish.priceInCents,
      };
    });

    const slot = await reserveSlotAtomically(slotId.toHexString());
    if (slot.date !== menu.date) {
      await releaseSlotAtomically(slotId.toHexString());
      throw new AppError(
        422,
        'Le créneau ne correspond pas à la date du menu.',
        'SLOT_MENU_DATE_MISMATCH',
      );
    }

    const reservedDishes: { dishId: Types.ObjectId; quantity: number }[] = [];
    try {
      for (const reservation of quantitiesByDish.values()) {
        await reserveMenuStockAtomically(menuId, reservation.dishId, reservation.quantity);
        reservedDishes.push(reservation);
      }
      return await Order.create({ studentId, slotId, menuId, lines: orderLines });
    } catch (error) {
      for (const reservation of reservedDishes) {
        await releaseMenuStock(menuId, reservation.dishId, reservation.quantity);
      }
      await releaseSlotAtomically(slotId.toHexString());
      throw error;
    }
  },

  /** Récupère les commandes d’un étudiant avec pagination */
  async getStudentOrders({ studentId, page, limit }: GetStudentOrdersParams) {
    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      Order.find({ studentId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('slotId', 'date startTime endTime')
        .lean(),
      Order.countDocuments({ studentId }),
    ]);
    return {
      orders: orders.map((order) => ({
        ...order,
        canCancel: this.canCancel(order.status, order.slotId),
      })),
      total,
      page,
      limit,
    };
  },

  /** Récupère une commande appartenant à l'étudiant connecté. */
  async getStudentOrder({ orderId, studentId }: GetStudentOrderParams) {
    const order = await Order.findOne({ _id: orderId, studentId })
      .populate('slotId', 'date startTime endTime')
      .lean();
    if (!order) throw AppError.notFound('Commande introuvable.');
    return {
      ...order,
      canCancel: this.canCancel(order.status, order.slotId),
    };
  },

  canCancel(status: OrderStatus, slot: unknown) {
    if (status !== 'received' && status !== 'preparing') return false;
    if (slot === null || typeof slot !== 'object') return false;
    const slotDetails = slot as Record<string, unknown>;
    if (
      typeof slotDetails.date !== 'string' ||
      typeof slotDetails.startTime !== 'string'
    ) {
      return false;
    }
    const deadline = new Date(
      `${slotDetails.date}T${slotDetails.startTime}:00.000Z`,
    );
    return deadline.getTime() > Date.now();
  },

  /** Annule une commande (seul le propriétaire peut le faire) */
  async cancelOrder({ orderId, requesterId }: CancelOrderParams) {
    const order = await Order.findById(orderId);
    if (!order) throw AppError.notFound('Commande introuvable.');
    if (!order.studentId.equals(requesterId)) {
      throw AppError.forbidden('Vous ne pouvez annuler que vos propres commandes.');
    }
    if (order.status === 'cancelled') {
      throw AppError.conflict('Cette commande est déjà annulée.', 'ORDER_ALREADY_CANCELLED');
    }
    if (order.status === 'ready' || order.status === 'withdrawn') {
      throw AppError.conflict(
        'Cette commande ne peut plus être annulée.',
        'ORDER_CANCELLATION_CLOSED',
      );
    }

    const slot = await TimeSlot.findById(order.slotId).lean();
    if (!slot) throw AppError.notFound('Créneau introuvable.');
    const deadline = new Date(`${slot.date}T${slot.startTime}:00.000Z`);
    if (deadline <= new Date()) {
      throw AppError.conflict(
        'Le délai d’annulation est dépassé.',
        'CANCELLATION_DEADLINE_PASSED',
      );
    }
    const cancelledOrder = await Order.findOneAndUpdate(
      { _id: orderId, studentId: requesterId, status: order.status },
      { $set: { status: 'cancelled' } },
      { new: true },
    );
    if (!cancelledOrder) {
      throw AppError.conflict('La commande a été modifiée simultanément. Réessayez.');
    }
    await this.releaseOrderReservations(cancelledOrder);
    return cancelledOrder;
  },

  /** Liste les commandes d’un créneau, éventuellement filtrées par statut */
  async getSlotOrders({ slotId, status, page, limit }: GetSlotOrdersParams) {
    const query: Record<string, unknown> = { slotId };
    if (status) query.status = status;
    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      Order.find(query).skip(skip).limit(limit).lean(),
      Order.countDocuments(query),
    ]);
    return { orders, total, page, limit };
  },

  /** Met à jour le statut d’une commande en respectant le workflow strict */
  async updateStatus({ orderId, newStatus }: UpdateStatusParams) {
    const order = await Order.findById(orderId);
    if (!order) throw AppError.notFound('Commande introuvable.');

    const allowedTransitions: Record<OrderStatus, OrderStatus[]> = {
      received: ['preparing', 'cancelled'],
      preparing: ['ready', 'cancelled'],
      ready: ['withdrawn'],
      withdrawn: [],
      cancelled: [],
    };
    if (!allowedTransitions[order.status].includes(newStatus)) {
      throw AppError.conflict(
        `Transition de statut interdite : ${order.status} vers ${newStatus}.`,
        'INVALID_ORDER_TRANSITION',
      );
    }

    const updatedOrder = await Order.findOneAndUpdate(
      { _id: orderId, status: order.status },
      { $set: { status: newStatus } },
      { new: true, runValidators: true },
    );
    if (!updatedOrder) {
      throw AppError.conflict('La commande a été modifiée simultanément. Réessayez.');
    }

    // Envoi de la notification push quand le statut devient « ready »
    if (newStatus === 'ready') {
      const device = await Device.findOne({ userId: updatedOrder.studentId }).lean();
      if (!device) {
        console.warn('Aucun appareil enregistré pour la notification de commande prête.', {
          orderId: updatedOrder.id,
          userId: updatedOrder.studentId.toHexString(),
        });
      } else {
        try {
          await sendPushNotification(device.fcmToken, {
            title: 'Votre repas est prêt !',
            body: 'Rendez‑vous à la cantine pour le récupérer.',
          });
        } catch (error) {
          console.error('Échec de l’envoi de la notification de commande prête.', {
            orderId: updatedOrder.id,
            error,
          });
        }
      }
    }

    if (newStatus === 'cancelled') await this.releaseOrderReservations(updatedOrder);
    return updatedOrder;
  },

  async releaseOrderReservations(order: OrderDocument) {
    await releaseSlotAtomically(order.slotId.toHexString());
    const quantitiesByDish = new Map<string, { dishId: Types.ObjectId; quantity: number }>();
    for (const line of order.lines) {
      const key = line.dishId.toHexString();
      const existing = quantitiesByDish.get(key);
      quantitiesByDish.set(key, {
        dishId: line.dishId,
        quantity: (existing?.quantity ?? 0) + line.quantity,
      });
    }
    for (const reservation of quantitiesByDish.values()) {
      await releaseMenuStock(order.menuId, reservation.dishId, reservation.quantity);
    }
  },
};
