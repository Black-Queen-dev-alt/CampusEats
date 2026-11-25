import { z } from 'zod';

export const createDishSchema = z.object({
  name: z.string().trim().min(2, 'Le nom doit comporter au moins 2 caractères').max(100),
  description: z
    .string()
    .trim()
    .min(5, 'La description doit comporter au moins 5 caractères')
    .max(1000, 'La description ne doit pas dépasser 1000 caractères'),
  priceInCents: z
    .number()
    .finite('Le prix doit être un nombre valide')
    .int('Le prix doit être un nombre entier')
    .min(0, 'Le prix ne peut pas être négatif'),
  category: z.enum(['entree', 'plat', 'dessert', 'boisson'], {
    error: 'Catégorie invalide (entree, plat, dessert, boisson)',
  }),
  photoUrl: z.string().trim().url('Format URL invalide').optional().nullable(),
  allergens: z
    .array(z.string().trim().toLowerCase().min(1, 'Un allergène ne peut pas être vide').max(50))
    .max(20)
    .default([]),
  isVegetarian: z.boolean().default(false),
  isActive: z.boolean().default(true),
});

export const updateDishSchema = z
  .object({
    name: z.string().trim().min(2).max(100).optional(),
    description: z.string().trim().min(5).max(1000).optional(),
    priceInCents: z.number().finite().int().min(0).optional(),
    category: z.enum(['entree', 'plat', 'dessert', 'boisson']).optional(),
    photoUrl: z.string().trim().url().optional().nullable(),
    allergens: z
      .array(z.string().trim().toLowerCase().min(1).max(50))
      .max(20)
      .optional(),
    isVegetarian: z.boolean().optional(),
    isActive: z.boolean().optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Au moins un champ doit être fourni',
  });

export const dishIdParamsSchema = z.object({
  id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Identifiant de plat invalide'),
});

export const listDishesQuerySchema = z.object({
  category: z.enum(['entree', 'plat', 'dessert', 'boisson']).optional(),
  isVegetarian: z.enum(['true', 'false']).optional(),
  allergen: z.string().trim().toLowerCase().min(1).max(50).optional(),
  search: z.string().trim().min(1).max(100).optional(),
  page: z.coerce.number().int().min(1).max(1_000_000).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type CreateDishDTO = z.infer<typeof createDishSchema>;
export type UpdateDishDTO = z.infer<typeof updateDishSchema>;
