import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { errorHandler } from './common/middlewares/error.middleware';
import { authRoutes } from './modules/auth/auth.routes';
import { userRoutes } from './modules/users/user.routes';
import { dishRoutes } from './modules/dishes/dish.routes';
import { menuRoutes } from './modules/menus/menu.routes';
import { timeSlotRoutes } from './modules/time-slots/time-slot.routes';
import ordersRouter, { slotOrdersRouter } from './routes/orders';
import devicesRouter from './routes/devices';

export const app = express();

// 1. Middlewares de sécurité de base (Exigence A11)
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// 2. Limitation de débit pour l'authentification (Exigence A11)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Trop de requêtes, veuillez réessayer dans quelques minutes.',
      details: null,
    },
  },
});
app.use('/auth', authLimiter);

// 3. Health Check
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 4. Routes des modules (Tout le monde connecté !)
app.use('/auth', authRoutes);
app.use('/', userRoutes);
app.use('/dishes', dishRoutes);
app.use('/menus', menuRoutes);
app.use('/time-slots', timeSlotRoutes);
app.use('/time-slots', slotOrdersRouter);
app.use('/orders', ordersRouter);
app.use('/devices', devicesRouter);

// 5. Gestionnaire d'erreurs centralisé unique (Exigence A5)
app.use(errorHandler);