import { Request, Response, NextFunction } from 'express';
import { MenuService } from './menu.service';

export class MenuController {
  static async getByDate(req: Request, res: Response, next: NextFunction) {
    try {
      const date = typeof req.query.date === 'string' ? req.query.date : undefined;
      const isAdminOrStaff = req.user?.role === 'admin' || req.user?.role === 'personnel';
      const menu = await MenuService.getMenuByDate(date, isAdminOrStaff);

      res.status(200).json({
        success: true,
        data: menu,
      });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const menu = await MenuService.createMenu(req.body);
      res.status(201).json({
        success: true,
        data: menu,
      });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const menu = await MenuService.updateMenu(id, req.body);
      res.status(200).json({
        success: true,
        data: menu,
      });
    } catch (error) {
      next(error);
    }
  }
}
