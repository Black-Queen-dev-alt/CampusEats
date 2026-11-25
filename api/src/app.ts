import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { errorHandler } from './common/middlewares/error.middleware';
import { authRoutes } from './modules/auth/auth.routes';
import { userRoutes } from './modules/users/user.routes';
import { dishRoutes } from './modules/dishes/dish.routes';
import { menuRoutes } from './modules/menus/menu.routes';

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

// 4. Routes des modules
app.use('/auth', authRoutes);
import ordersRouter from './routes/orders';
import devicesRouter from './routes/devices';
app.use('/orders', ordersRouter);
app.use('/devices', devicesRouter);

app.use('/', userRoutes);

// Modules du Développeur 2
app.use('/dishes', dishRoutes);
app.use('/menus', menuRoutes);

// Futurs modules de vos camarades (Développeurs 3 et 4)
// app.use('/time-slots', timeSlotRoutes);
// app.use('/orders', orderRoutes);

// 5. Gestionnaire d'erreurs centralisé unique (Exigence A5)
app.use(errorHandler);
