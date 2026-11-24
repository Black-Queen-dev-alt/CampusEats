import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt';
import { User } from '../../modules/users/user.model';
import { AppError } from '../errors/app-error';

export async function authenticate(req: Request, _res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw AppError.unauthorized('Jeton d\'authentification manquant ou malformé.');
    }

    const token = authHeader.split(' ')[1];
    const payload = verifyAccessToken(token);

    // Vérifier que l'utilisateur existe toujours et est actif (RG13)
    const user = await User.findById(payload.userId);
    if (!user) {
      throw AppError.unauthorized('Utilisateur introuvable.');
    }

    if (user.status === 'suspendu') {
      throw AppError.forbidden('Votre compte a été suspendu par un administrateur.');
    }

    req.user = {
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    };

    next();
  } catch (error) {
    next(error);
  }
}
