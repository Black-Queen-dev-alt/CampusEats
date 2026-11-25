import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env'; // adapter selon votre config

/**
 * Middleware d'autorisation JWT.
 * `allowedRoles` = tableau des rôles autorisés pour la route.
 */
export const authorize = (allowedRoles: string[]) => (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing token' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, config.JWT_SECRET) as any;
    // on attache un objet user minimal à la requête
    req.user = { id: payload.sub, role: payload.role };
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    next();
  } catch (e) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};
