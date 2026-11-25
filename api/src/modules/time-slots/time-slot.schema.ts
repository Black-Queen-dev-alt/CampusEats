import { z } from "zod";

const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .refine((value) => {
    const parsed = new Date(`${value}T00:00:00.000Z`);
    return (
      !Number.isNaN(parsed.getTime()) &&
      parsed.toISOString().slice(0, 10) === value
    );
  }, "La date doit être une date réelle au format YYYY-MM-DD");

const timeSchema = z
  .string()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Heure invalide (HH:mm)");
const capacitySchema = z.number().int().min(1).max(10000);

export const listTimeSlotsQuerySchema = z.object({ date: dateSchema }).strict();

export const createTimeSlotSchema = z
  .object({
    date: dateSchema,
    startTime: timeSchema,
    endTime: timeSchema,
    capacity: capacitySchema,
  })
  .strict()
  .refine((value) => value.startTime < value.endTime, {
    message: "L’heure de fin doit être postérieure à l’heure de début",
    path: ["endTime"],
  });

export const updateTimeSlotSchema = z
  .object({
    date: dateSchema.optional(),
    startTime: timeSchema.optional(),
    endTime: timeSchema.optional(),
    capacity: capacitySchema.optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "Au moins un champ doit être fourni",
  })
  .refine(
    (value) =>
      !value.startTime || !value.endTime || value.startTime < value.endTime,
    {
      message: "L’heure de fin doit être postérieure à l’heure de début",
      path: ["endTime"],
    },
  );

export const timeSlotIdSchema = z.object({
  id: z.string().regex(/^[a-f\d]{24}$/i, "Identifiant invalide"),
});

export type CreateTimeSlotDTO = z.infer<typeof createTimeSlotSchema>;
export type UpdateTimeSlotDTO = z.infer<typeof updateTimeSlotSchema>;
