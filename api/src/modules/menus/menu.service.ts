import { Types } from 'mongoose';
import { Menu, IMenu } from './menu.model';
import { Dish } from '../dishes/dish.model';
import { CreateMenuDTO, UpdateMenuDTO } from './menu.schema';
import { AppError } from '../../common/errors/app-error';

export class MenuService {
  /**
   * Consultation du menu pour une date (par défaut aujourd'hui)
   * Popule les informations détaillées des plats
   */
  static async getMenuByDate(date?: string, isAdminOrStaff = false): Promise<IMenu> {
    const targetDate = date || new Date().toISOString().split('T')[0];

    const filter: Record<string, unknown> = { date: targetDate };
    if (!isAdminOrStaff) {
      filter.isPublished = true;
    }

    const menu = await Menu.findOne(filter).populate({
      path: 'items.dishId',
      select: 'name description priceInCents category photoUrl allergens isVegetarian isActive',
    });

    if (!menu) {
      throw AppError.notFound(`Aucun menu disponible pour la date du ${targetDate}`);
    }

    return menu;
  }

  /**
   * Publication d'un menu quotidien (Réservé admin)
   * Garantit l'unicité de la date (RG08 / Section 8)
   */
  static async createMenu(data: CreateMenuDTO): Promise<IMenu> {
    // 1. Unicité stricte de la date
    const existing = await Menu.findOne({ date: data.date });
    if (existing) {
      throw AppError.conflict(
        `Un menu a déjà été configuré pour le ${data.date}. Utilisez PATCH pour le modifier.`,
        'MENU_ALREADY_EXISTS'
      );
    }

    // 2. Vérification que les plats existent et sont actifs
    const dishIds = data.items.map((i) => new Types.ObjectId(i.dishId));
    const activeDishes = await Dish.find({ _id: { $in: dishIds }, isActive: true });

    if (activeDishes.length !== dishIds.length) {
      throw AppError.unprocessable('Certains plats sélectionnés sont introuvables ou inactifs');
    }

    const menu = new Menu({
      date: data.date,
      items: data.items.map((i) => ({
        dishId: new Types.ObjectId(i.dishId),
        isAvailable: i.isAvailable,
        dailyStockLimit: i.dailyStockLimit,
      })),
      isPublished: data.isPublished,
    });

    return await (await menu.save()).populate('items.dishId');
  }

  /**
   * Mise à jour d'un menu (Réservé admin)
   */
  static async updateMenu(id: string, data: UpdateMenuDTO): Promise<IMenu> {
    const menu = await Menu.findById(id);
    if (!menu) {
      throw AppError.notFound('Menu introuvable');
    }

    if (data.items) {
      const dishIds = data.items.map((i) => new Types.ObjectId(i.dishId));
      const activeDishes = await Dish.find({ _id: { $in: dishIds }, isActive: true });

      if (activeDishes.length !== dishIds.length) {
        throw AppError.unprocessable('Certains plats sélectionnés sont introuvables ou inactifs');
      }

      menu.items = data.items.map((i) => ({
        dishId: new Types.ObjectId(i.dishId),
        isAvailable: i.isAvailable,
        dailyStockLimit: i.dailyStockLimit,
      }));
    }

    if (typeof data.isPublished === 'boolean') {
      menu.isPublished = data.isPublished;
    }

    await menu.save();
    return await menu.populate('items.dishId');
  }
}
