import { Router } from 'express';
import { AuthController } from './auth.controller';
import { validate } from '../../common/middlewares/validate.middleware';
import { registerSchema, loginSchema, refreshTokenSchema, logoutSchema } from './auth.schema';

export const authRoutes = Router();

authRoutes.post('/register', validate(registerSchema), AuthController.register);
authRoutes.post('/login', validate(loginSchema), AuthController.login);
authRoutes.post('/refresh', validate(refreshTokenSchema), AuthController.refresh);
authRoutes.post('/logout', validate(logoutSchema), AuthController.logout);
