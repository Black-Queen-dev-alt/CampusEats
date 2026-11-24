import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Format d\'email universitaire invalide').toLowerCase().trim(),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
  fullName: z.string().min(2, 'Le nom complet doit contenir au moins 2 caractères').trim(),
  phone: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email('Email invalide').toLowerCase().trim(),
  password: z.string().min(1, 'Le mot de passe est requis'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Le jeton de rafraîchissement est requis'),
});

export type RegisterDTO = z.infer<typeof registerSchema>;
export type LoginDTO = z.infer<typeof loginSchema>;
export type RefreshTokenDTO = z.infer<typeof refreshTokenSchema>;
