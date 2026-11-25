import { describe, expect, it } from 'vitest';
import {
  createOrderSchema,
  listOrdersQuerySchema,
  updateOrderStatusSchema,
} from '../modules/orders/order.schema';
import { createDishSchema } from '../modules/dishes/dish.schema';

const validId = '507f1f77bcf86cd799439011';

describe('Order request schemas', () => {
  it('rejects dish names that become empty after trimming', () => {
    const result = createDishSchema.safeParse({
      name: '   ',
      description: 'Description valide',
      priceInCents: 500,
      category: 'plat',
    });

    expect(result.success).toBe(false);
  });

  it('rejects duplicate dish lines so clients cannot bypass the per-item quantity limit', () => {
    const result = createOrderSchema.safeParse({
      slotId: validId,
      menuId: validId,
      lines: [
        { dishId: validId, quantity: 20 },
        { dishId: validId, quantity: 20 },
      ],
    });

    expect(result.success).toBe(false);
  });

  it('defaults pagination and caps the requested page size', () => {
    expect(listOrdersQuerySchema.parse({})).toEqual({ page: 1, limit: 20 });
    expect(listOrdersQuerySchema.safeParse({ limit: '51' }).success).toBe(false);
  });

  it('accepts known statuses so the service can enforce workflow transitions', () => {
    expect(updateOrderStatusSchema.safeParse({ status: 'received' }).success).toBe(true);
    expect(updateOrderStatusSchema.safeParse({ status: 'unknown' }).success).toBe(false);
  });
});
