// src/modules/orders/order.model.ts
import { Schema, model, Document, Types } from 'mongoose';

export interface OrderLine {
  dishId: Types.ObjectId;
  quantity: number;
}

export type OrderStatus = 'received' | 'preparing' | 'ready' | 'withdrawn' | 'cancelled';

export interface OrderDocument extends Document {
  studentId: Types.ObjectId;
  slotId: Types.ObjectId;
  menuId: Types.ObjectId;
  lines: OrderLine[];
  status: OrderStatus;
  createdAt: Date;
  updatedAt: Date;
}

const OrderSchema = new Schema<OrderDocument>(
  {
    studentId: { type: Schema.Types.ObjectId, required: true, ref: 'User' },
    slotId: { type: Schema.Types.ObjectId, required: true, ref: 'TimeSlot' },
    menuId: { type: Schema.Types.ObjectId, required: true, ref: 'Menu' },
    lines: [
      {
        dishId: { type: Schema.Types.ObjectId, required: true, ref: 'Dish' },
        quantity: { type: Number, required: true, min: 1 },
      },
    ],
    status: {
      type: String,
      enum: ['received', 'preparing', 'ready', 'withdrawn', 'cancelled'],
      default: 'received',
    },
  },
  { timestamps: true }
);

export const Order = model<OrderDocument>('Order', OrderSchema);
