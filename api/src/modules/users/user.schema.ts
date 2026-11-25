import { z } from 'zod';

// RG10 : Le rôle n'est jamais modifiable par l'utilisateur lui-même
export const updateProfileSchema = z.object({
  fullName: z.string().min(2, 'Le nom complet doit comporter au moins 2 caractères').optional(),
  phone: z.string().optional(),
});

// Création d'utilisateurs par un administrateur (Personnel ou autre Admin)
export const createStaffOrAdminSchema = z.object({
  email: z.string().email('Format email invalide').toLowerCase().trim(),
  password: z.string().min(6, 'Mot de passe minimum 6 caractères'),
  fullName: z.string().min(2, 'Nom complet requis').trim(),
  role: z.enum(['personnel', 'admin'], {
    error: 'Le rôle doit être personnel ou admin',
  }),
  phone: z.string().optional(),
});

export const updateUserStatusSchema = z.object({
  status: z.enum(['actif', 'suspendu'], {
    error: 'Le statut doit être actif ou suspendu',
  }),
});

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>;
export type CreateStaffOrAdminDTO = z.infer<typeof createStaffOrAdminSchema>;
export type UpdateUserStatusDTO = z.infer<typeof updateUserStatusSchema>;
