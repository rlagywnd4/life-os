export type ProgressAction = {
  id: string;
  parent_action_id: string | null;
  status: string;
  deleted_at?: string | null;
  is_stage?: boolean;
};

export type ProgressMilestone = { completed_at: string | null };

/**
 * Count only executable leaf activities. Containers/stages are not counted,
 * avoiding the double-counting that occurs when a parent and its children are
 * all displayed in the tree. Milestones are the fallback for a plan with no
 * executable activity yet; a completed project is always complete.
 */
export function calculateProjectProgress(
  actions: ProgressAction[],
  milestones: ProgressMilestone[] = [],
  projectStatus?: string
) {
  if (projectStatus === "COMPLETED") return { completed: 1, total: 1, percentage: 100, basis: "project" as const };
  const activeActions = actions.filter((action) => !action.deleted_at);
  const parentIds = new Set(activeActions.flatMap((action) => action.parent_action_id ? [action.parent_action_id] : []));
  const leaves = activeActions.filter((action) => !action.is_stage && !parentIds.has(action.id));
  if (leaves.length > 0) {
    const completed = leaves.filter((action) => action.status === "DONE").length;
    return { completed, total: leaves.length, percentage: Math.round((completed / leaves.length) * 100), basis: "actions" as const };
  }
  if (milestones.length > 0) {
    const completed = milestones.filter((milestone) => Boolean(milestone.completed_at)).length;
    return { completed, total: milestones.length, percentage: Math.round((completed / milestones.length) * 100), basis: "milestones" as const };
  }
  return { completed: 0, total: 0, percentage: 0, basis: "empty" as const };
}

export function getSuggestedNextAction<T extends ProgressAction>(actions: T[]): T | null {
  const activeActions = actions.filter((action) => !action.deleted_at && !action.is_stage && !["DONE", "SKIPPED", "CANCELED"].includes(action.status));
  const parentIds = new Set(activeActions.flatMap((action) => action.parent_action_id ? [action.parent_action_id] : []));
  return activeActions.find((action) => !parentIds.has(action.id)) ?? activeActions[0] ?? null;
}

export function getProjectPlanningGaps(project: {
  goal: string | null;
  completion_criteria: string | null;
  target_date: string | null;
  next_action_id: string | null;
}, actions: ProgressAction[]) {
  return [
    !project.goal ? "목표가 설정되지 않음" : null,
    !project.completion_criteria ? "완료 기준이 설정되지 않음" : null,
    !actions.some((action) => action.is_stage && !action.deleted_at) ? "단계가 없음" : null,
    !project.next_action_id ? "다음 행동이 없음" : null,
    !project.target_date ? "목표일이 없음" : null
  ].filter((gap): gap is string => Boolean(gap));
}
