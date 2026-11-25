import { User } from './user.model';
import { RefreshToken } from '../auth/refreshToken.model';
import { hashPassword } from '../../common/utils/hash';
import { AppError } from '../../common/errors/app-error';
import { UpdateProfileDTO, CreateStaffOrAdminDTO, UpdateUserStatusDTO } from './user.schema';

export class UserService {
  static async getProfile(userId: string) {
    const user = await User.findById(userId);
    if (!user) throw AppError.notFound('Utilisateur introuvable.');
    return user;
  }

  static async updateProfile(userId: string, dto: UpdateProfileDTO) {
    const user = await User.findByIdAndUpdate(userId, dto, {
      new: true,
      runValidators: true,
    });
    if (!user) throw AppError.notFound('Utilisateur introuvable.');
    return user;
  }

  static async createStaffUser(dto: CreateStaffOrAdminDTO) {
    const existing = await User.findOne({ email: dto.email });
    if (existing) {
      throw AppError.conflict('Cette adresse email est déjà utilisée.');
    }

    const hashedPassword = await hashPassword(dto.password);
    const user = await User.create({
      email: dto.email,
      password: hashedPassword,
      fullName: dto.fullName,
      role: dto.role,
      phone: dto.phone,
      status: 'actif',
    });

    return user;
  }

  static async updateUserStatus(userId: string, dto: UpdateUserStatusDTO) {
    const user = await User.findByIdAndUpdate(
      userId,
      { status: dto.status },
      { new: true, runValidators: true }
    );

    if (!user) throw AppError.notFound('Utilisateur introuvable.');

    // Si on suspend le compte, on révoque immédiatement tous ses refresh tokens (RG13)
    if (dto.status === 'suspendu') {
      await RefreshToken.updateMany({ userId: user._id }, { revoked: true });
    }

    return user;
  }
}
