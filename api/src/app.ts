import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { errorHandler } from './common/middlewares/error.middleware';

export const app = express();

// 1. Middlewares de sécurité de base
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// 2. Limitation de débit pour l'authentification
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Trop de tentatives de connexion, veuillez réessayer plus tard.',
      details: null,
    },
  },
});
app.use('/auth', authLimiter);

// 3. Health Check
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 4. Routes des modules (Seront branchées au fur et à mesure des merges)
// app.use('/auth', authRoutes);
// app.use('/users', userRoutes);
// app.use('/dishes', dishRoutes);
// app.use('/menus', menuRoutes);
// app.use('/time-slots', timeSlotRoutes);
// app.use('/orders', orderRoutes);

// 5. Gestionnaire d'erreurs centralisé unique (Exigence A5)
app.use(errorHandler);
