import { z } from "zod";

export const inboxSchema = z.object({
  title: z.string().trim().min(1, "제목을 입력하세요.").max(160),
  description: z.string().trim().max(2000).optional(),
  category: z.string().default("ETC")
});

export const inboxUpdateSchema = inboxSchema.extend({
  id: z.string().uuid()
});

export const projectConversionSchema = z.object({
  inboxId: z.string().uuid(),
  title: z.string().trim().min(1).max(160),
  reason: z.string().trim().max(1000).optional(),
  desiredOutcome: z.string().trim().max(1000).optional(),
  activateNow: z.coerce.boolean().default(false)
});

const actionBaseSchema = z.object({
  projectId: z.string().uuid(),
  parentActionId: z.preprocess(
    (value) => (value === "" || value === null ? undefined : value),
    z.string().uuid().optional()
  ),
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().max(1000).optional(),
  estimatedMinutes: z.coerce.number().int().positive().max(480).default(30),
  status: z.enum(["TODO", "PLANNED", "IN_PROGRESS", "WAITING", "DONE", "SKIPPED", "CANCELED"]).default("TODO"),
  dueDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().or(z.literal("")),
  startedDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().or(z.literal("")),
  scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().or(z.literal("")),
  scheduledTime: z.string().regex(/^\d{2}:\d{2}$/).optional().or(z.literal("")),
  scheduledEndTime: z.string().regex(/^\d{2}:\d{2}$/).optional().or(z.literal("")),
  isAllDay: z.coerce.boolean().default(true),
  isStage: z.coerce.boolean().default(false),
  actualMinutes: z.preprocess((value) => (value === "" || value === null ? undefined : value), z.coerce.number().int().min(0).max(1440).optional())
});

function validateActionSchedule(value: z.infer<typeof actionBaseSchema>, context: z.RefinementCtx) {
  if (value.scheduledTime && value.scheduledEndTime && value.scheduledEndTime <= value.scheduledTime) {
    context.addIssue({ code: z.ZodIssueCode.custom, message: "종료 시간은 시작 시간 이후여야 합니다.", path: ["scheduledEndTime"] });
  }
}

export const actionSchema = actionBaseSchema.superRefine(validateActionSchedule);

export const actionUpdateSchema = actionBaseSchema.extend({
  actionId: z.string().uuid()
}).superRefine(validateActionSchedule);

const optionalDate = z.preprocess(
  (value) => (value === "" || value === null ? undefined : value),
  z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()
);

const projectPlanBaseSchema = z.object({
    sourceInboxId: z.preprocess((value) => (value === "" || value === null ? undefined : value), z.string().uuid().optional()),
    title: z.string().trim().min(1, "프로젝트 제목을 입력하세요.").max(160),
    description: z.string().trim().max(2000).optional(),
    goal: z.string().trim().max(2000).optional(),
    completionCriteria: z.string().trim().max(2000).optional(),
    startedDate: optionalDate,
    targetDate: optionalDate,
    status: z.enum(["DRAFT", "ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED", "ARCHIVED"]).default("DRAFT"),
    stages: z.array(z.string().trim().max(160)).max(20).default([]),
    firstActionTitle: z.string().trim().max(160).optional()
  });

function validateProjectDates(value: { startedDate?: string; targetDate?: string }, context: z.RefinementCtx) {
    if (value.startedDate && value.targetDate && value.targetDate < value.startedDate) {
      context.addIssue({ code: z.ZodIssueCode.custom, message: "목표 완료일은 시작일보다 빠를 수 없습니다.", path: ["targetDate"] });
    }
}

export const projectPlanSchema = projectPlanBaseSchema.superRefine(validateProjectDates);

export const projectUpdateSchema = projectPlanBaseSchema.pick({
  title: true,
  description: true,
  goal: true,
  completionCriteria: true,
  startedDate: true,
  targetDate: true,
  status: true
}).extend({ id: z.string().uuid() }).superRefine(validateProjectDates);

export const milestoneSchema = z.object({
  id: z.string().uuid().optional(),
  projectId: z.string().uuid(),
  actionItemId: z.preprocess((value) => (value === "" || value === null ? undefined : value), z.string().uuid().optional()),
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().max(1000).optional(),
  targetDate: optionalDate,
  sortOrder: z.coerce.number().int().min(0).default(0)
});

export const projectRecordSchema = z.object({
  id: z.string().uuid().optional(),
  projectId: z.string().uuid(),
  content: z.string().trim().min(1).max(4000)
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
