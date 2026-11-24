import { User, IUser } from '../users/user.model';
import { RefreshToken } from './refreshToken.model';
import { hashPassword, verifyPassword, hashToken, generateRandomToken } from '../../common/utils/hash';
import { signAccessToken } from '../../common/utils/jwt';
import { AppError } from '../../common/errors/app-error';
import { env } from '../../config/env';
import { RegisterDTO, LoginDTO } from './auth.schema';

export class AuthService {
  private static async createSession(user: IUser) {
    const accessToken = signAccessToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    const rawRefreshToken = generateRandomToken();
    const tokenHash = hashToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);

    await RefreshToken.create({
      userId: user._id,
      tokenHash,
      expiresAt,
    });

    return {
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        status: user.status,
      },
      accessToken,
      refreshToken: rawRefreshToken,
    };
  }

  static async register(dto: RegisterDTO) {
    const existing = await User.findOne({ email: dto.email });
    if (existing) {
      throw AppError.conflict('Cette adresse email est déjà enregistrée.', 'EMAIL_ALREADY_EXISTS');
    }

    const hashedPassword = await hashPassword(dto.password);

    // RG02 : L'inscription publique crée UNIQUEMENT des comptes 'etudiant'
    const user = await User.create({
      email: dto.email,
      password: hashedPassword,
      fullName: dto.fullName,
      phone: dto.phone,
      role: 'etudiant',
      status: 'actif',
    });

    return this.createSession(user);
  }

  static async login(dto: LoginDTO) {
    const user = await User.findOne({ email: dto.email });
    if (!user) {
      throw AppError.unauthorized('Email ou mot de passe incorrect.');
    }

    const isValid = await verifyPassword(user.password, dto.password);
    if (!isValid) {
      throw AppError.unauthorized('Email ou mot de passe incorrect.');
    }

    // RG13 : Un compte suspendu ne peut plus se connecter
    if (user.status === 'suspendu') {
      throw AppError.forbidden('Votre compte est suspendu. Veuillez contacter l\'administration.');
    }

    return this.createSession(user);
  }

  // Rotation stricte du refresh token (Exigence A6)
  static async refresh(rawRefreshToken: string) {
    const tokenHash = hashToken(rawRefreshToken);
    const storedToken = await RefreshToken.findOne({ tokenHash });

    if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
      throw AppError.unauthorized('Jeton de rafraîchissement invalide ou expiré.');
    }

    // Invalider l'ancien token pour empêcher le rejeu
    storedToken.revoked = true;
    await storedToken.save();

    const user = await User.findById(storedToken.userId);
    if (!user || user.status === 'suspendu') {
      throw AppError.unauthorized('Session révoquée ou utilisateur inactif.');
    }

    return this.createSession(user);
  }

  static async logout(rawRefreshToken?: string) {
    if (rawRefreshToken) {
      const tokenHash = hashToken(rawRefreshToken);
      await RefreshToken.updateOne({ tokenHash }, { revoked: true });
    }
  }
}
