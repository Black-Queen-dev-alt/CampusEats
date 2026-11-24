import { NextFunction, Request, Response } from "express";
import { TimeSlotService } from "./time-slot.service";

export class TimeSlotController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const slots = await TimeSlotService.listByDate(req.query.date as string);
      res.status(200).json({ success: true, data: slots });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const slot = await TimeSlotService.create(req.body);
      res.status(201).json({ success: true, data: slot });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Array.isArray(req.params.id)
        ? req.params.id[0]
        : req.params.id;
      const slot = await TimeSlotService.update(id, req.body);
      res.status(200).json({ success: true, data: slot });
    } catch (error) {
      next(error);
    }
  }
}
