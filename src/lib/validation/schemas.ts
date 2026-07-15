import { z } from "zod";

export const inboxSchema = z.object({
  title: z.string().trim().min(1, "제목을 입력하세요.").max(160),
  description: z.string().trim().max(2000).optional(),
  category: z.string().default("ETC")
});

export const projectConversionSchema = z.object({
  inboxId: z.string().uuid(),
  title: z.string().trim().min(1).max(160),
  reason: z.string().trim().max(1000).optional(),
  desiredOutcome: z.string().trim().max(1000).optional(),
  activateNow: z.coerce.boolean().default(false)
});

export const actionSchema = z.object({
  projectId: z.string().uuid(),
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().max(1000).optional(),
  estimatedMinutes: z.coerce.number().int().positive().max(480).default(30)
});

export const dailyPlanSchema = z.object({
  planDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  energyLevel: z.enum(["LOW", "MEDIUM", "HIGH"]),
  dayMode: z.enum(["NORMAL", "REST", "RECOVERY", "TRAVEL", "BUSY"]),
  note: z.string().trim().max(2000).optional(),
  restReason: z.string().trim().max(1000).optional()
});

const optionalNumber = z.preprocess((value) => (value === "" || value === null ? undefined : value), z.coerce.number().optional());
const optionalInt = z.preprocess((value) => (value === "" || value === null ? undefined : value), z.coerce.number().int().optional());

export const healthProfileSchema = z.object({
  heightCm: optionalNumber,
  birthYear: optionalInt,
  currentWeightKg: z.coerce.number().positive("현재 체중을 입력하세요."),
  targetWeightKg: z.coerce.number().positive("최종 목표 체중을 입력하세요."),
  goalDescription: z.string().trim().max(1000).optional(),
  activityLevel: z.enum(["", "LOW", "LIGHT", "MODERATE", "HIGH"]).default(""),
  usualWeighInTime: z.enum(["", "MORNING", "AFTER_WORK", "EVENING", "BEFORE_SLEEP", "OTHER"]).default(""),
  weeklyLossRateKg: z.coerce.number().positive().max(2).default(0.5),
  weekdayBriskWalkMinutes: z.coerce.number().int().positive().default(20),
  lowEnergyWalkMinutes: z.coerce.number().int().positive().default(5),
  snackReminderEnabled: z.coerce.boolean().default(false),
  snackReminderTime: z.string().regex(/^\d{2}:\d{2}$/).default("17:30"),
  snackWeekdays: z.array(z.coerce.number().int().min(0).max(6)).default([1, 2, 3, 4, 5]),
  defaultSnackName: z.string().trim().min(1).max(120).default("퇴근 전 계획된 간식"),
  defaultSnackNote: z.string().trim().max(1000).optional()
});

export const healthWeightGoalSchema = z.object({
  id: z.string().uuid().optional(),
  targetWeightKg: z.coerce.number().positive(),
  goalName: z.string().trim().min(1).max(120),
  sortOrder: z.coerce.number().int().min(0).default(0),
  achieved: z.coerce.boolean().default(false),
  achievedDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().or(z.literal(""))
});

export const healthCheckInSchema = z.object({
  checkInDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  weightKg: optionalNumber,
  steps: optionalInt,
  briskWalkStatus: z.enum(["DONE", "PARTIAL", "ALTERNATIVE", "REST", "UNRECORDED"]).default("UNRECORDED"),
  plannedSnackDone: z.enum(["", "true", "false"]).default(""),
  unplannedSnack: z.coerce.boolean().default(false),
  dinnerOvereating: z.coerce.boolean().default(false),
  freeMeal: z.coerce.boolean().default(false),
  alcohol: z.coerce.boolean().default(false),
  exerciseCompletion: z.enum(["NOT_DONE", "FULL", "MINIMUM", "ALTERNATIVE", "REST"]).default("NOT_DONE"),
  sleepHours: optionalNumber,
  conditionLevel: z.enum(["", "VERY_LOW", "LOW", "NORMAL", "GOOD", "VERY_GOOD"]).default(""),
  stressLevel: z.enum(["", "LOW", "NORMAL", "HIGH"]).default(""),
  lowEnergyMode: z.coerce.boolean().default(false),
  note: z.string().trim().max(1000).optional()
});
