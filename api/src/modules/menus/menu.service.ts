import { Types } from 'mongoose';
import { Menu, IMenu } from './menu.model';
import { Dish } from '../dishes/dish.model';
import { CreateMenuDTO, UpdateMenuDTO } from './menu.schema';
import { AppError } from '../../common/errors/app-error';

export async function reserveMenuStockAtomically(
  menuId: Types.ObjectId,
  dishId: Types.ObjectId,
  quantity: number,
): Promise<void> {
  const dishMatches = {
    $and: [
      { $eq: ['$$item.dishId', dishId] },
      { $eq: ['$$item.isAvailable', true] },
      {
        $or: [
          { $eq: [{ $ifNull: ['$$item.dailyStockLimit', null] }, null] },
          {
            $lte: [
              { $add: [{ $ifNull: ['$$item.dailyStockUsed', 0] }, quantity] },
              '$$item.dailyStockLimit',
            ],
          },
        ],
      },
    ],
  };
  const result = await Menu.updateOne(
    {
      _id: menuId,
      isPublished: true,
      $expr: {
        $gt: [
          {
            $size: {
              $filter: {
                input: '$items',
                as: 'item',
                cond: dishMatches,
              },
            },
          },
          0,
        ],
      },
    },
    [
      {
        $set: {
          items: {
            $map: {
              input: '$items',
              as: 'item',
              in: {
                $cond: [
                  {
                    $and: [
                      { $eq: ['$$item.dishId', dishId] },
                      { $eq: ['$$item.isAvailable', true] },
                    ],
                  },
                  {
                    $mergeObjects: [
                      '$$item',
                      {
                        dailyStockUsed: {
                          $add: [{ $ifNull: ['$$item.dailyStockUsed', 0] }, quantity],
                        },
                      },
                    ],
                  },
                  '$$item',
                ],
              },
            },
          },
        },
      },
    ],
  );
  if (result.matchedCount !== 1) {
    throw AppError.conflict(
      'Le plat n’est plus disponible ou son stock quotidien est épuisé.',
      'DAILY_STOCK_LIMIT',
    );
  }
}

export async function releaseMenuStock(
  menuId: Types.ObjectId,
  dishId: Types.ObjectId,
  quantity: number,
): Promise<void> {
  await Menu.updateOne(
    {
      _id: menuId,
      items: {
        $elemMatch: {
          dishId,
          dailyStockUsed: { $gte: quantity },
        },
      },
    },
    { $inc: { 'items.$.dailyStockUsed': -quantity } },
  );
}

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
    if (data.items) {
      const dishIds = data.items.map((i) => new Types.ObjectId(i.dishId));
      const activeDishes = await Dish.find({ _id: { $in: dishIds }, isActive: true });

      if (activeDishes.length !== dishIds.length) {
        throw AppError.unprocessable('Certains plats sélectionnés sont introuvables ou inactifs');
      }

      const desiredItems = data.items.map((item) => ({
        dishId: new Types.ObjectId(item.dishId),
        isAvailable: item.isAvailable,
        dailyStockLimit: item.dailyStockLimit,
      }));
      const desiredDishIds = desiredItems.map((item) => item.dishId);
      const filter: Record<string, unknown> = {
        _id: id,
        $expr: {
          $and: [
            {
              $eq: [
                {
                  $size: {
                    $filter: {
                      input: '$items',
                      as: 'current',
                      cond: {
                        $and: [
                          { $gt: [{ $ifNull: ['$$current.dailyStockUsed', 0] }, 0] },
                          { $not: [{ $in: ['$$current.dishId', desiredDishIds] }] },
                        ],
                      },
                    },
                  },
                },
                0,
              ],
            },
            {
              $eq: [
                {
                  $size: {
                    $filter: {
                      input: desiredItems,
                      as: 'desired',
                      cond: {
                        $let: {
                          vars: {
                            current: {
                              $arrayElemAt: [
                                {
                                  $filter: {
                                    input: '$items',
                                    as: 'item',
                                    cond: { $eq: ['$$item.dishId', '$$desired.dishId'] },
                                  },
                                },
                                0,
                              ],
                            },
                          },
                          in: {
                            $and: [
                              {
                                $ne: [
                                  { $ifNull: ['$$desired.dailyStockLimit', null] },
                                  null,
                                ],
                              },
                              {
                                $gt: [
                                  { $ifNull: ['$$current.dailyStockUsed', 0] },
                                  '$$desired.dailyStockLimit',
                                ],
                              },
                            ],
                          },
                        },
                      },
                    },
                  },
                },
                0,
              ],
            },
          ],
        },
      };
      const setStage: Record<string, unknown> = {
        items: {
          $map: {
            input: desiredItems,
            as: 'desired',
            in: {
              $let: {
                vars: {
                  current: {
                    $arrayElemAt: [
                      {
                        $filter: {
                          input: '$items',
                          as: 'item',
                          cond: { $eq: ['$$item.dishId', '$$desired.dishId'] },
                        },
                      },
                      0,
                    ],
                  },
                },
                in: {
                  $mergeObjects: [
                    '$$desired',
                    { dailyStockUsed: { $ifNull: ['$$current.dailyStockUsed', 0] } },
                  ],
                },
              },
            },
          },
        },
      };
      if (data.isPublished !== undefined) setStage.isPublished = data.isPublished;

      const result = await Menu.updateOne(filter, [{ $set: setStage }]);
      if (result.matchedCount !== 1) {
        const exists = await Menu.exists({ _id: id });
        if (!exists) throw AppError.notFound('Menu introuvable');
        throw AppError.conflict(
          'Les modifications ne peuvent pas réduire le stock réservé ni retirer un plat commandé.',
          'MENU_STOCK_BELOW_RESERVED',
        );
      }
      const updatedMenu = await Menu.findById(id);
      if (!updatedMenu) throw AppError.notFound('Menu introuvable');
      return updatedMenu.populate('items.dishId');
    }

    const update: Record<string, unknown> = {};
    if (data.isPublished !== undefined) update.isPublished = data.isPublished;
    const menu = await Menu.findByIdAndUpdate(id, { $set: update }, {
      new: true,
      runValidators: true,
    });
    if (!menu) {
      throw AppError.notFound('Menu introuvable');
    }
    return menu.populate('items.dishId');
  }
}
