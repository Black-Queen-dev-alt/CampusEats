import { UserRole } from '../modules/users/user.model';

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        id: string;
        role: UserRole;
        email?: string;
      };
    }
  }
}

export {};