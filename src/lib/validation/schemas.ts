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
