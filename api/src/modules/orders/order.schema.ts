import { z } from 'zod';

const objectIdSchema = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Identifiant MongoDB invalide');

export const createOrderSchema = z.object({
  slotId: objectIdSchema,
  menuId: objectIdSchema,
  lines: z
    .array(
      z.object({
        dishId: objectIdSchema,
        quantity: z.number().int().min(1).max(20),
      }),
    )
    .min(1, 'Une commande doit contenir au moins un plat')
    .max(20, 'Une commande ne peut contenir que 20 lignes')
    .refine(
      (lines) => new Set(lines.map((line) => line.dishId.toLowerCase())).size === lines.length,
      'Un plat ne peut apparaître qu’une fois dans une commande',
    ),
});

const paginationQuerySchema = {
  page: z.coerce.number().int().min(1).max(1_000_000).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
};

export const listOrdersQuerySchema = z.object(paginationQuerySchema);

export const listSlotOrdersQuerySchema = z.object({
  ...paginationQuerySchema,
  status: z
    .enum(['received', 'preparing', 'ready', 'withdrawn', 'cancelled'])
    .optional(),
});

export const orderIdParamsSchema = z.object({
  id: objectIdSchema,
});

export const updateOrderStatusSchema = z.object({
  status: z.enum(['received', 'preparing', 'ready', 'withdrawn', 'cancelled']),
});

export type CreateOrderDTO = z.infer<typeof createOrderSchema>;
