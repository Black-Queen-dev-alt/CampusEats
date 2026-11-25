import mongoose, { Schema, Document, Types } from 'mongoose';
import { IDish } from '../dishes/dish.model';

export interface IMenuItem {
  dishId: Types.ObjectId | IDish;
  isAvailable: boolean;
  dailyStockLimit?: number;
  dailyStockUsed: number;
}

export interface IMenu extends Document {
  date: string; // Format 'YYYY-MM-DD'
  items: IMenuItem[];
  isPublished: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const MenuItemSchema = new Schema<IMenuItem>(
  {
    dishId: {
      type: Schema.Types.ObjectId,
      ref: 'Dish',
      required: true,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
    dailyStockLimit: {
      type: Number,
      min: 0,
    },
    dailyStockUsed: {
      type: Number,
      min: 0,
      default: 0,
      validate: Number.isInteger,
    },
  },
  { _id: false }
);

const MenuSchema = new Schema<IMenu>(
  {
    date: {
      type: String,
      required: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
    },
    items: {
      type: [MenuItemSchema],
      validate: {
        validator: (items: IMenuItem[]) => items && items.length > 0,
        message: 'Un menu doit comporter au moins un plat.',
      },
    },
    isPublished: {
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

MenuSchema.index({ date: 1 }, { unique: true });

export const Menu = mongoose.model<IMenu>('Menu', MenuSchema);
