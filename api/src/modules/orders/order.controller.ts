// src/modules/orders/order.controller.ts
import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { OrderService } from './order.service';
import { asyncHandler } from '../../utils/asyncHandler';

/**
 * POST /orders – crée une commande (étudiant uniquement).
 */
export const createOrder = asyncHandler(async (req: Request, res: Response) => {
  const studentId = req.user.id; // middleware auth ajoute user
  const { slotId, menuId, lines } = req.body; // lines = [{ dishId, quantity }]
  const order = await OrderService.createOrder({
    studentId: new Types.ObjectId(studentId),
    slotId: new Types.ObjectId(slotId),
    menuId: new Types.ObjectId(menuId),
    lines,
  });
  res.status(201).json(order);
});

/** GET /orders – historique paginé de l'étudiant */
export const getMyOrders = asyncHandler(async (req: Request, res: Response) => {
  const studentId = req.user.id;
  const { page = 1, limit = 20 } = req.query as any;
  const result = await OrderService.getStudentOrders({
    studentId: new Types.ObjectId(studentId),
    page: Number(page),
    limit: Number(limit),
  });
  res.json(result);
});

/** POST /orders/:id/cancel – annulation par le propriétaire */
export const cancelOrder = asyncHandler(async (req: Request, res: Response) => {
  const requesterId = req.user.id;
  await OrderService.cancelOrder({
    orderId: new Types.ObjectId(req.params.id),
    requesterId: new Types.ObjectId(requesterId),
  });
  res.status(200).json({ message: 'Order cancelled' });
});

/** GET /time-slots/:id/orders – vue du personnel */
export const getSlotOrders = asyncHandler(async (req: Request, res: Response) => {
  const { status, page = 1, limit = 20 } = req.query as any;
  const result = await OrderService.getSlotOrders({
    slotId: new Types.ObjectId(req.params.id),
    status: status as string | undefined,
    page: Number(page),
    limit: Number(limit),
  });
  res.json(result);
});

/** PATCH /orders/:id/status – changement de statut (personnel) */
export const updateOrderStatus = asyncHandler(async (req: Request, res: Response) => {
  const requesterId = req.user.id;
  const { status: newStatus } = req.body;
  const order = await OrderService.updateStatus({
    orderId: new Types.ObjectId(req.params.id),
    newStatus,
    requesterId: new Types.ObjectId(requesterId),
  });
  res.json(order);
});
