import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middlewares/auth.middleware';
import { authorize as roleAuthorize } from '../../common/middlewares/role.middleware';
import { UserRole } from '../users/user.model';

/**
 * Middleware d'autorisation compatible avec les routes orders / devices
 */
export const authorize = (allowedRoles: string[]) => {
  return [authenticate, roleAuthorize(...(allowedRoles as UserRole[]))];
};
