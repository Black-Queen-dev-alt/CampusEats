import mongoose, { Schema, Document } from 'mongoose';

export type UserRole = 'etudiant' | 'personnel' | 'admin';
export type UserStatus = 'actif' | 'suspendu';

export interface IUser extends Document {
  email: string;
  password: string;
  fullName: string;
  role: UserRole;
  status: UserStatus;
  phone?: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    role: {
      type: String,
      enum: ['etudiant', 'personnel', 'admin'],
      default: 'etudiant',
      required: true,
    },
    status: {
      type: String,
      enum: ['actif', 'suspendu'],
      default: 'actif',
      required: true,
    },
    phone: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret: Record<string, any>) => {
        delete ret.password;
        delete ret.__v;
        ret.id = ret._id;
        delete ret._id;
        return ret;
      },
    },
  }
);

export const User = mongoose.model<IUser>('User', UserSchema);
