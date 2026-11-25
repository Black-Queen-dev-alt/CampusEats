import { Dish, IDish } from './dish.model';
import { CreateDishDTO, UpdateDishDTO } from './dish.schema';
import { AppError } from '../../common/errors/app-error';

export interface DishQueryParams {
  category?: string;
  isVegetarian?: string;
  allergen?: string;
  search?: string;
  page?: string;
  limit?: string;
}

export class DishService {
  /**
   * Liste paginée des plats avec filtres (Règle A9)
   */
  static async listDishes(query: DishQueryParams) {
    const filter: Record<string, unknown> = { isActive: true };

    if (query.category) {
      filter.category = query.category;
    }

    if (query.isVegetarian !== undefined) {
      filter.isVegetarian = query.isVegetarian === 'true';
    }

    if (query.allergen) {
      // Exclure l'allergène spécifié par l'étudiant
      filter.allergens = { $nin: [query.allergen.toLowerCase().trim()] };
    }

    if (query.search) {
      filter.name = { $regex: query.search.trim(), $options: 'i' };
    }

    const page = Math.max(1, parseInt(query.page || '1', 10));
    const limit = Math.min(Math.max(1, parseInt(query.limit || '20', 10)), 50); // Capped at 50
    const skip = (page - 1) * limit;

    const [dishes, total] = await Promise.all([
      Dish.find(filter).sort({ category: 1, name: 1 }).skip(skip).limit(limit),
      Dish.countDocuments(filter),
    ]);

    return {
      dishes,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  static async getDishById(id: string): Promise<IDish> {
    const dish = await Dish.findById(id);
    if (!dish) {
      throw AppError.notFound('Plat introuvable');
    }
    return dish;
  }

  static async createDish(data: CreateDishDTO): Promise<IDish> {
    const existing = await Dish.findOne({
      name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') },
    });

    if (existing) {
      throw AppError.conflict(`Un plat nommé "${data.name}" existe déjà.`);
    }

    const dish = new Dish(data);
    return await dish.save();
  }

  static async updateDish(id: string, data: UpdateDishDTO): Promise<IDish> {
    if (data.name) {
      const existing = await Dish.findOne({
        _id: { $ne: id },
        name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') },
      });
      if (existing) {
        throw AppError.conflict(`Un autre plat nommé "${data.name}" existe déjà.`);
      }
    }

    const dish = await Dish.findByIdAndUpdate(id, { $set: data }, { new: true, runValidators: true });
    if (!dish) {
      throw AppError.notFound('Plat introuvable');
    }
    return dish;
  }
}
