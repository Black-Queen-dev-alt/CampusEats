import { z } from 'zod';

export const createDishSchema = z.object({
  name: z.string().min(2, 'Le nom doit comporter au moins 2 caractères').max(100).trim(),
  description: z.string().min(5, 'La description doit comporter au moins 5 caractères').trim(),
  priceInCents: z.number().int('Le prix doit être un nombre entier').min(0, 'Le prix ne peut pas être négatif'),
  category: z.enum(['entree', 'plat', 'dessert', 'boisson'], {
    error: 'Catégorie invalide (entree, plat, dessert, boisson)',
  }),
  photoUrl: z.string().url('Format URL invalide').optional().nullable(),
  allergens: z.array(z.string().toLowerCase().trim()).default([]),
  isVegetarian: z.boolean().default(false),
  isActive: z.boolean().default(true),
});

export const updateDishSchema = z.object({
  name: z.string().min(2).max(100).trim().optional(),
  description: z.string().min(5).trim().optional(),
  priceInCents: z.number().int().min(0).optional(),
  category: z.enum(['entree', 'plat', 'dessert', 'boisson']).optional(),
  photoUrl: z.string().url().optional().nullable(),
  allergens: z.array(z.string().toLowerCase().trim()).optional(),
  isVegetarian: z.boolean().optional(),
  isActive: z.boolean().optional(),
});

export type CreateDishDTO = z.infer<typeof createDishSchema>;
export type UpdateDishDTO = z.infer<typeof updateDishSchema>;
