import { z } from 'zod';

// RG10 : Le rôle n'est jamais modifiable par l'utilisateur lui-même
export const updateProfileSchema = z
  .object({
    fullName: z
      .string()
      .trim()
      .min(2, 'Le nom complet doit comporter au moins 2 caractères')
      .max(100, 'Le nom complet ne doit pas dépasser 100 caractères')
      .optional(),
    phone: z
      .string()
      .trim()
      .min(1, 'Le numéro de téléphone ne peut pas être vide')
      .max(30, 'Le numéro de téléphone ne doit pas dépasser 30 caractères')
      .optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Au moins un champ doit être fourni',
  });

// Création d'utilisateurs par un administrateur (Personnel ou autre Admin)
export const createStaffOrAdminSchema = z.object({
  email: z.string().trim().toLowerCase().email('Format email invalide'),
  password: z
    .string()
    .min(8, 'Mot de passe minimum 8 caractères')
    .max(128, 'Mot de passe maximum 128 caractères'),
  fullName: z
    .string()
    .trim()
    .min(2, 'Nom complet requis')
    .max(100, 'Le nom complet ne doit pas dépasser 100 caractères'),
  role: z.enum(['personnel', 'admin'], {
    error: 'Le rôle doit être personnel ou admin',
  }),
  phone: z
    .string()
    .trim()
    .min(1, 'Le numéro de téléphone ne peut pas être vide')
    .max(30, 'Le numéro de téléphone ne doit pas dépasser 30 caractères')
    .optional(),
});

export const updateUserStatusSchema = z.object({
  status: z.enum(['actif', 'suspendu'], {
    error: 'Le statut doit être actif ou suspendu',
  }),
});

export const userIdParamsSchema = z.object({
  id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Identifiant utilisateur invalide'),
});

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>;
export type CreateStaffOrAdminDTO = z.infer<typeof createStaffOrAdminSchema>;
export type UpdateUserStatusDTO = z.infer<typeof updateUserStatusSchema>;
