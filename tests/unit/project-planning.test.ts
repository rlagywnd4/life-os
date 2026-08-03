import { describe, expect, it } from "vitest";
import { calculateProjectProgress, getProjectPlanningGaps, getSuggestedNextAction } from "@/lib/domain/project-planning";
import { projectPlanSchema } from "@/lib/validation/schemas";

describe("project planning domain", () => {
  const actions = [
    { id: "stage", parent_action_id: null, status: "TODO", is_stage: true },
    { id: "parent", parent_action_id: "stage", status: "TODO", is_stage: false },
    { id: "done-leaf", parent_action_id: "parent", status: "DONE", is_stage: false },
    { id: "open-leaf", parent_action_id: "parent", status: "TODO", is_stage: false }
  ];

  it("uses executable leaf actions so parents do not double count", () => {
    expect(calculateProjectProgress(actions)).toMatchObject({ completed: 1, total: 2, percentage: 50, basis: "actions" });
    expect(calculateProjectProgress(actions, [], "COMPLETED")).toMatchObject({ percentage: 100, basis: "project" });
  });

  it("falls back to milestones only when there are no executable activities", () => {
    expect(calculateProjectProgress([], [{ completed_at: null }, { completed_at: "2026-08-03T00:00:00Z" }])).toMatchObject({ completed: 1, total: 2, percentage: 50, basis: "milestones" });
  });

  it("suggests an unfinished leaf action without overwriting an explicit choice", () => {
    expect(getSuggestedNextAction(actions)?.id).toBe("open-leaf");
  });

  it("reports the important plan gaps", () => {
    expect(getProjectPlanningGaps({ goal: null, completion_criteria: null, target_date: null, next_action_id: null }, [])).toEqual([
      "목표가 설정되지 않음", "완료 기준이 설정되지 않음", "단계가 없음", "다음 행동이 없음", "목표일이 없음"
    ]);
  });

  it("rejects an inverted project date range", () => {
    expect(projectPlanSchema.safeParse({ title: "AI 공부", status: "DRAFT", stages: [], startedDate: "2026-09-30", targetDate: "2026-09-01" }).success).toBe(false);
  });
});
