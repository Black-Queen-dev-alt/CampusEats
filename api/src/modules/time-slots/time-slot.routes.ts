import { NextFunction, Request, Response, Router } from "express";
import { ZodSchema, ZodError } from "zod";
import { AppError } from "../../common/errors/app-error";
import { authenticate } from "../../common/middlewares/auth.middleware";
import { authorize } from "../../common/middlewares/role.middleware";
import { validate } from "../../common/middlewares/validate.middleware";
import { TimeSlotController } from "./time-slot.controller";
import {
  createTimeSlotSchema,
  listTimeSlotsQuerySchema,
  timeSlotIdSchema,
  updateTimeSlotSchema,
} from "./time-slot.schema";

export const timeSlotRoutes = Router();

function validateQuery(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.query);
    if (!parsed.success) return next(toValidationError(parsed.error));
    req.query = parsed.data as Request["query"];
    next();
  };
}

function validateParams(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.params);
    if (!parsed.success) return next(toValidationError(parsed.error));
    next();
  };
}

function toValidationError(error: ZodError) {
  return AppError.unprocessable(
    "Données de formulaire invalides",
    error.issues.map((issue) => ({
      field: issue.path.join("."),
      message: issue.message,
    })),
  );
}

timeSlotRoutes.get(
  "/",
  authenticate,
  validateQuery(listTimeSlotsQuerySchema),
  TimeSlotController.list,
);
timeSlotRoutes.post(
  "/",
  authenticate,
  authorize("admin"),
  validate(createTimeSlotSchema),
  TimeSlotController.create,
);
timeSlotRoutes.patch(
  "/:id",
  authenticate,
  authorize("admin"),
  validateParams(timeSlotIdSchema),
  validate(updateTimeSlotSchema),
  TimeSlotController.update,
);
