import { describe, expect, it } from "vitest";
import {
  assertActiveProjectLimit,
  canTransitionProject,
  getActionSizeWarning,
  getActionSpecificityWarning,
  getRecommendedCoreActionRange
} from "@/lib/domain/rules";
import { getKoreanWeekStart, toDateOnlyInKorea } from "@/lib/dates/korea";
import { actionSchema, inboxSchema } from "@/lib/validation/schemas";
import { calculateHealthAdherence, generateHealthFeedback } from "@/lib/domain/health";

describe("LifeOS domain rules", () => {
  it("warns when an action is larger than the recommended 30 minutes", () => {
    expect(getActionSizeWarning(31)).toContain("조금 커 보입니다");
    expect(getActionSizeWarning(30)).toBeNull();
  });

  it("warns for vague action titles", () => {
    expect(getActionSpecificityWarning("공부하기")).toContain("구체적인");
    expect(getActionSpecificityWarning("채용 공고 2개 읽기")).toBeNull();
  });

  it("recommends core action ranges by energy", () => {
    expect(getRecommendedCoreActionRange("LOW")).toEqual({ min: 0, max: 1 });
    expect(getRecommendedCoreActionRange("MEDIUM")).toEqual({ min: 1, max: 2 });
    expect(getRecommendedCoreActionRange("HIGH")).toEqual({ min: 1, max: 3 });
  });

  it("keeps project state transitions deliberate", () => {
    expect(canTransitionProject("ACTIVE", "PAUSED")).toBe(true);
    expect(canTransitionProject("COMPLETED", "ACTIVE")).toBe(false);
    expect(canTransitionProject("ARCHIVED", "ACTIVE")).toBe(false);
  });

  it("detects active project limit", () => {
    expect(assertActiveProjectLimit(2, 3).ok).toBe(true);
    expect(assertActiveProjectLimit(3, 3)).toMatchObject({
      ok: false,
      code: "ACTIVE_PROJECT_LIMIT_EXCEEDED"
    });
  });

  it("handles Korea date-only formatting", () => {
    expect(toDateOnlyInKorea(new Date("2026-07-14T15:30:00.000Z"))).toBe("2026-07-15");
    expect(getKoreanWeekStart(new Date("2026-07-15T12:00:00+09:00"))).toBe("2026-07-13");
  });

  it("validates forms with zod", () => {
    expect(inboxSchema.safeParse({ title: "", category: "ETC" }).success).toBe(false);
    expect(actionSchema.safeParse({ projectId: crypto.randomUUID(), title: "20분 걷기", estimatedMinutes: 20 }).success).toBe(true);
  });
});

describe("LifeOS health rules", () => {
  it("does not treat missing days as failures in health adherence", () => {
    const rows = calculateHealthAdherence(
      [
        {
          check_in_date: "2026-07-13",
          weight_kg: 72,
          steps: null,
          brisk_walk_status: "DONE",
          planned_snack_done: true,
          dinner_overeating: false,
          exercise_completion: "NOT_DONE",
          low_energy_mode: false
        }
      ],
      { snack_weekdays: [1, 2, 3, 4, 5] },
      new Date("2026-07-15T12:00:00+09:00")
    );

    expect(rows.find((row) => row.key === "weight")).toMatchObject({ done: 1, planned: 1, rate: 100 });
    expect(rows.find((row) => row.key === "steps")).toMatchObject({ done: 0, planned: 1, rate: 0 });
  });

  it("returns data none when no planned health records exist", () => {
    const rows = calculateHealthAdherence([], null, new Date("2026-07-15T12:00:00+09:00"));
    expect(rows.every((row) => row.rate === null)).toBe(true);
  });

  it("generates non-punitive health feedback", () => {
    const feedback = generateHealthFeedback([], null, new Date("2026-07-15T12:00:00+09:00"));
    expect(feedback).toContain("단정");
    expect(feedback).not.toContain("실패");
  });
});
