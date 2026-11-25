import { z } from 'zod';

export const createMenuSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format de date invalide (YYYY-MM-DD attendu)')
    .refine((value) => {
      const date = new Date(`${value}T00:00:00.000Z`);
      return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
    }, 'La date doit être une date réelle'),
  items: z
    .array(
      z.object({
        dishId: z.string().regex(/^[0-9a-fA-F]{24}$/, 'ID de plat invalide (ObjectId attendu)'),
        isAvailable: z.boolean().default(true),
        dailyStockLimit: z.number().int().min(0).max(10000).optional(),
      })
    )
    .min(1, 'Le menu doit contenir au moins un plat')
    .max(100, 'Un menu ne peut contenir que 100 plats')
    .refine((items) => new Set(items.map((item) => item.dishId.toLowerCase())).size === items.length, {
      message: 'Un même plat ne peut apparaître qu’une fois dans le menu',
    }),
  isPublished: z.boolean().default(true),
});

export const updateMenuSchema = z.object({
  isPublished: z.boolean().optional(),
  items: z
    .array(
      z.object({
        dishId: z.string().regex(/^[0-9a-fA-F]{24}$/, 'ID de plat invalide'),
        isAvailable: z.boolean(),
        dailyStockLimit: z.number().int().min(0).max(10000).optional(),
      })
    )
    .max(100, 'Un menu ne peut contenir que 100 plats')
    .refine((items) => new Set(items.map((item) => item.dishId.toLowerCase())).size === items.length, {
      message: 'Un même plat ne peut apparaître qu’une fois dans le menu',
    })
    .optional(),
}).refine((value) => Object.keys(value).length > 0, {
  message: 'Au moins un champ doit être fourni',
});

export const menuDateQuerySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine((value) => {
    const date = new Date(`${value}T00:00:00.000Z`);
    return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
  }, 'La date doit être une date réelle').optional(),
});

export const menuIdParamsSchema = z.object({
  id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Identifiant de menu invalide'),
});

export type CreateMenuDTO = z.infer<typeof createMenuSchema>;
export type UpdateMenuDTO = z.infer<typeof updateMenuSchema>;
