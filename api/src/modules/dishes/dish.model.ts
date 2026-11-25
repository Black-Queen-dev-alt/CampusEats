import mongoose, { Schema, Document, Types } from 'mongoose';

export type DishCategory = 'entree' | 'plat' | 'dessert' | 'boisson';

export interface IDish extends Document {
  name: string;
  description: string;
  priceInCents: number; // RG09: Montants stockés en entiers
  category: DishCategory;
  photoUrl?: string;
  allergens: string[];
  isVegetarian: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const DishSchema = new Schema<IDish>(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    priceInCents: {
      type: Number,
      required: true,
      min: 0,
      validate: {
        validator: Number.isInteger,
        message: 'Le prix doit être un entier strict en centimes',
      },
    },
    category: {
      type: String,
      enum: ['entree', 'plat', 'dessert', 'boisson'],
      default: 'plat',
      required: true,
      index: true,
    },
    photoUrl: {
      type: String,
      default: null,
    },
    allergens: {
      type: [{ type: String, trim: true, lowercase: true }],
      default: [],
    },
    isVegetarian: {
      type: Boolean,
      default: false,
      index: true,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret: Record<string, any>) => {
        delete ret.__v;
        ret.id = ret._id;
        delete ret._id;
        return ret;
      },
    },
  }
);

DishSchema.index({ category: 1, isActive: 1 });

export const Dish = mongoose.model<IDish>('Dish', DishSchema);
