import { Request, Response, NextFunction } from 'express';
import { DishService } from './dish.service';

export class DishController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await DishService.listDishes(req.query);
      res.status(200).json({
        success: true,
        data: result.dishes,
        pagination: result.pagination,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const dish = await DishService.getDishById(id, req.user?.role === 'admin');
      res.status(200).json({
        success: true,
        data: dish,
      });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const dish = await DishService.createDish(req.body);
      res.status(201).json({
        success: true,
        data: dish,
      });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const dish = await DishService.updateDish(id, req.body);
      res.status(200).json({
        success: true,
        data: dish,
      });
    } catch (error) {
      next(error);
    }
  }
}
