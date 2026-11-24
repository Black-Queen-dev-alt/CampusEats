import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../../modules/users/user.model';
import { AppError } from '../errors/app-error';

export function authorize(...allowedRoles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(AppError.unauthorized('Authentification requise.'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        AppError.forbidden(
          `Accès interdit : cette ressource nécessite le rôle ${allowedRoles.join(' ou ')}.`
        )
      );
    }

    next();
  };
}
