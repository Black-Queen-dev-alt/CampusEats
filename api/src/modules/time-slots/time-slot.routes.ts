import { Router } from "express";
import { authenticate } from "../../common/middlewares/auth.middleware";
import { authorize } from "../../common/middlewares/role.middleware";
import {
  validate,
  validateParams,
  validateQuery,
} from "../../common/middlewares/validate.middleware";
import { TimeSlotController } from "./time-slot.controller";
import {
  createTimeSlotSchema,
  listTimeSlotsQuerySchema,
  timeSlotIdSchema,
  updateTimeSlotSchema,
} from "./time-slot.schema";

export const timeSlotRoutes = Router();

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
