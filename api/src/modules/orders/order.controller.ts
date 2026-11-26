import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { OrderService } from './order.service';
import { asyncHandler } from '../../utils/asyncHandler';

/**
 * POST /orders – crée une commande (étudiant uniquement).
 */
export const createOrder = asyncHandler(async (req: Request, res: Response) => {
  const studentId = req.user!.id;
  const { slotId, menuId, lines } = req.body;
  const order = await OrderService.createOrder({
    studentId: new Types.ObjectId(studentId),
    slotId: new Types.ObjectId(slotId),
    menuId: new Types.ObjectId(menuId),
    lines: lines.map((line: { dishId: string; quantity: number }) => ({
      dishId: new Types.ObjectId(line.dishId),
      quantity: line.quantity,
    })),
  });
  res.status(201).json({ success: true, data: order });
});

/** GET /orders – historique paginé de l'étudiant */
export const getMyOrders = asyncHandler(async (req: Request, res: Response) => {
  const studentId = req.user!.id;
  const { page, limit } = req.query as unknown as { page: number; limit: number };
  const result = await OrderService.getStudentOrders({
    studentId: new Types.ObjectId(studentId),
    page,
    limit,
  });
  res.status(200).json({
    success: true,
    data: result.orders,
    pagination: {
      page: result.page,
      limit: result.limit,
      total: result.total,
      totalPages: Math.ceil(result.total / result.limit),
    },
  });
});

/** GET /orders/:id – détail d’une commande appartenant à l’étudiant */
export const getMyOrder = asyncHandler(async (req: Request, res: Response) => {
  const studentId = req.user!.id;
  const orderId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const order = await OrderService.getStudentOrder({
    orderId: new Types.ObjectId(orderId),
    studentId: new Types.ObjectId(studentId),
  });
  res.status(200).json({ success: true, data: order });
});

/** POST /orders/:id/cancel – annulation par le propriétaire */
export const cancelOrder = asyncHandler(async (req: Request, res: Response) => {
  const requesterId = req.user!.id;
  const orderId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const order = await OrderService.cancelOrder({
    orderId: new Types.ObjectId(orderId),
    requesterId: new Types.ObjectId(requesterId),
  });
  res.status(200).json({ success: true, data: order });
});

/** GET /time-slots/:id/orders – vue du personnel */
export const getSlotOrders = asyncHandler(async (req: Request, res: Response) => {
  const { status, page, limit } = req.query as unknown as {
    status?: string;
    page: number;
    limit: number;
  };
  const slotId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const result = await OrderService.getSlotOrders({
    slotId: new Types.ObjectId(slotId),
    status: status as string | undefined,
    page,
    limit,
  });
  res.status(200).json({
    success: true,
    data: result.orders,
    pagination: {
      page: result.page,
      limit: result.limit,
      total: result.total,
      totalPages: Math.ceil(result.total / result.limit),
    },
  });
});

/** PATCH /orders/:id/status – changement de statut (personnel) */
export const updateOrderStatus = asyncHandler(async (req: Request, res: Response) => {
  const { status: newStatus } = req.body;
  const orderId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const order = await OrderService.updateStatus({
    orderId: new Types.ObjectId(orderId),
    newStatus,
  });
  res.status(200).json({ success: true, data: order });
});
