import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email('Format d\'email universitaire invalide'),
  password: z.string().min(8, 'Le mot de passe doit contenir au moins 8 caractères').max(128),
  fullName: z.string().trim().min(2, 'Le nom complet doit contenir au moins 2 caractères').max(100),
  phone: z.string().trim().min(1).max(30).optional(),
});

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Email invalide'),
  password: z.string().min(1, 'Le mot de passe est requis').max(128),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Le jeton de rafraîchissement est requis'),
});

export const logoutSchema = z.object({
  refreshToken: z.string().min(1, 'Le jeton de rafraîchissement est requis'),
});

export type RegisterDTO = z.infer<typeof registerSchema>;
export type LoginDTO = z.infer<typeof loginSchema>;
export type RefreshTokenDTO = z.infer<typeof refreshTokenSchema>;
