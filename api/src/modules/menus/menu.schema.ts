import { z } from 'zod';

export const createMenuSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format de date invalide (YYYY-MM-DD attendu)'),
  items: z
    .array(
      z.object({
        dishId: z.string().regex(/^[0-9a-fA-F]{24}$/, 'ID de plat invalide (ObjectId attendu)'),
        isAvailable: z.boolean().default(true),
        dailyStockLimit: z.number().int().min(0).optional(),
      })
    )
    .min(1, 'Le menu doit contenir au moins un plat'),
  isPublished: z.boolean().default(true),
});

export const updateMenuSchema = z.object({
  isPublished: z.boolean().optional(),
  items: z
    .array(
      z.object({
        dishId: z.string().regex(/^[0-9a-fA-F]{24}$/, 'ID de plat invalide'),
        isAvailable: z.boolean(),
        dailyStockLimit: z.number().int().min(0).optional(),
      })
    )
    .optional(),
});

export type CreateMenuDTO = z.infer<typeof createMenuSchema>;
export type UpdateMenuDTO = z.infer<typeof updateMenuSchema>;
