"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  actionSchema,
  actionUpdateSchema,
  milestoneSchema,
  projectPlanSchema,
  projectRecordSchema,
  projectUpdateSchema
} from "@/lib/validation/schemas";

function requiredSupabase() {
  return createClient().then((supabase) => {
    if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
    return supabase;
  });
}

function getActionErrorMessage(message: string) {
  if (message.includes("ACTION_HIERARCHY_CYCLE")) return "자기 자신이나 자신의 하위 활동으로는 이동할 수 없습니다.";
  if (message.includes("ACTION_PARENT_NOT_FOUND") || message.includes("ACTION_PARENT_NOT_AVAILABLE")) return "선택한 부모 활동을 사용할 수 없습니다.";
  if (message.includes("PROJECT_DATE_RANGE_INVALID")) return "목표 완료일은 시작일보다 빠를 수 없습니다.";
  if (message.includes("INBOX_ALREADY")) return "이미 처리된 Inbox 항목입니다. 새로고침 후 다시 확인해주세요.";
  return message;
}

function revalidateProjectPaths(projectId: string, actionId?: string) {
  revalidatePath("/projects");
  revalidatePath(`/projects/${projectId}`);
  revalidatePath("/today");
  revalidatePath("/history");
  if (actionId) revalidatePath(`/projects/${projectId}/actions/${actionId}`);
}

function formActionInput(formData: FormData) {
  return {
    projectId: formData.get("projectId"),
    parentActionId: formData.get("parentActionId"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    estimatedMinutes: formData.get("estimatedMinutes") ?? 30,
    status: formData.get("status") ?? "TODO",
    dueDate: formData.get("dueDate") ?? "",
    startedDate: formData.get("startedDate") ?? "",
    scheduledDate: formData.get("scheduledDate") ?? "",
    scheduledTime: formData.get("scheduledTime") ?? "",
    scheduledEndTime: formData.get("scheduledEndTime") ?? "",
    isAllDay: formData.get("isAllDay") === "on",
    isStage: formData.get("isStage") === "on",
    actualMinutes: formData.get("actualMinutes") ?? ""
  };
}

export async function createProjectPlan(formData: FormData) {
  const parsed = projectPlanSchema.safeParse({
    sourceInboxId: formData.get("sourceInboxId"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    goal: formData.get("goal") ?? "",
    completionCriteria: formData.get("completionCriteria") ?? "",
    startedDate: formData.get("startedDate") ?? "",
    targetDate: formData.get("targetDate") ?? "",
    status: formData.get("status") ?? "DRAFT",
    stages: formData.getAll("stages").map(String).filter(Boolean),
    firstActionTitle: formData.get("firstActionTitle") ?? ""
  });
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "프로젝트 입력을 확인해주세요.");

  const supabase = await requiredSupabase();
  const { data, error } = await supabase.rpc("create_project_plan", {
    p_title: parsed.data.title,
    p_description: parsed.data.description || null,
    p_goal: parsed.data.goal || null,
    p_completion_criteria: parsed.data.completionCriteria || null,
    p_started_date: parsed.data.startedDate || null,
    p_target_date: parsed.data.targetDate || null,
    p_status: parsed.data.status,
    p_stage_titles: parsed.data.stages.filter((stage) => stage.trim()),
    p_first_action_title: parsed.data.firstActionTitle || null,
    p_source_inbox_id: parsed.data.sourceInboxId ?? null
  });
  if (error || !data) throw new Error(getActionErrorMessage(error?.message ?? "프로젝트를 만들지 못했습니다."));

  revalidatePath("/inbox");
  revalidatePath("/projects");
  redirect(`/projects/${data}`);
}

export async function updateProject(formData: FormData) {
  const parsed = projectUpdateSchema.safeParse({
    id: formData.get("id"), title: formData.get("title"), description: formData.get("description") ?? "",
    goal: formData.get("goal") ?? "", completionCriteria: formData.get("completionCriteria") ?? "",
    startedDate: formData.get("startedDate") ?? "", targetDate: formData.get("targetDate") ?? "",
    status: formData.get("status")
  });
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "프로젝트 입력을 확인해주세요.");
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("projects").update({
    title: parsed.data.title, description: parsed.data.description || null,
    goal: parsed.data.goal || null, completion_criteria: parsed.data.completionCriteria || null,
    reason: parsed.data.goal || null, desired_outcome: parsed.data.completionCriteria || null,
    started_at: parsed.data.startedDate ? new Date(`${parsed.data.startedDate}T00:00:00+09:00`).toISOString() : null,
    target_date: parsed.data.targetDate || null, status: parsed.data.status,
    completed_at: parsed.data.status === "COMPLETED" ? new Date().toISOString() : null,
    archived_at: parsed.data.status === "ARCHIVED" ? new Date().toISOString() : null
  }).eq("id", parsed.data.id);
  if (error) throw new Error(error.message);
  await supabase.from("project_records").insert({ project_id: parsed.data.id, record_type: "PLAN_CHANGED", content: "프로젝트 기본 정보를 수정했습니다.", is_system: true });
  revalidateProjectPaths(parsed.data.id);
}

export async function createActionItem(formData: FormData) {
  const parsed = actionSchema.safeParse(formActionInput(formData));
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "활동 입력을 확인해주세요.");
  const supabase = await requiredSupabase();
  let siblingQuery = supabase.from("action_items").select("sort_order").eq("project_id", parsed.data.projectId).is("deleted_at", null);
  siblingQuery = parsed.data.parentActionId ? siblingQuery.eq("parent_action_id", parsed.data.parentActionId) : siblingQuery.is("parent_action_id", null);
  const { data: siblings, error: siblingError } = await siblingQuery;
  if (siblingError) throw new Error(siblingError.message);
  const nextSortOrder = Math.max(-1, ...(siblings ?? []).map((sibling) => sibling.sort_order)) + 1;
  const { error } = await supabase.from("action_items").insert({
    project_id: parsed.data.projectId, parent_action_id: parsed.data.parentActionId ?? null,
    title: parsed.data.title, description: parsed.data.description || null, estimated_minutes: parsed.data.estimatedMinutes,
    status: parsed.data.status, due_date: parsed.data.dueDate || null, started_date: parsed.data.startedDate || null, scheduled_date: parsed.data.scheduledDate || null,
    scheduled_time: parsed.data.scheduledTime || null, scheduled_end_time: parsed.data.scheduledEndTime || null,
    is_all_day: parsed.data.isAllDay, is_stage: parsed.data.isStage, sort_order: nextSortOrder
  });
  if (error) throw new Error(getActionErrorMessage(error.message));
  await supabase.from("project_records").insert({ project_id: parsed.data.projectId, record_type: "PLAN_CHANGED", content: `활동 “${parsed.data.title}”을 추가했습니다.`, is_system: true });
  revalidateProjectPaths(parsed.data.projectId);
}

export async function updateActionItem(formData: FormData) {
  const parsed = actionUpdateSchema.safeParse({ actionId: formData.get("actionId"), ...formActionInput(formData) });
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "활동 입력을 확인해주세요.");
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("action_items").update({
    parent_action_id: parsed.data.parentActionId ?? null, title: parsed.data.title, description: parsed.data.description || null,
    estimated_minutes: parsed.data.estimatedMinutes, status: parsed.data.status, due_date: parsed.data.dueDate || null, started_date: parsed.data.startedDate || null, actual_minutes: parsed.data.actualMinutes ?? null,
    scheduled_date: parsed.data.scheduledDate || null, scheduled_time: parsed.data.scheduledTime || null,
    scheduled_end_time: parsed.data.scheduledEndTime || null, is_all_day: parsed.data.isAllDay
  }).eq("id", parsed.data.actionId).eq("project_id", parsed.data.projectId);
  if (error) throw new Error(getActionErrorMessage(error.message));
  revalidateProjectPaths(parsed.data.projectId, parsed.data.actionId);
}

export async function updateActionCompletion(actionId: string, projectId: string, completed: boolean) {
  const supabase = await requiredSupabase();
  const { data: action, error: lookupError } = await supabase.from("action_items").select("title").eq("id", actionId).eq("project_id", projectId).single();
  if (lookupError || !action) throw new Error("활동을 찾을 수 없습니다.");
  const { error } = await supabase.from("action_items").update({ status: completed ? "DONE" : "TODO", completed_at: completed ? new Date().toISOString() : null }).eq("id", actionId).eq("project_id", projectId);
  if (error) throw new Error(error.message);
  if (completed) await supabase.from("project_records").insert({ project_id: projectId, action_item_id: actionId, record_type: "ACTION_COMPLETED", content: `활동 “${action.title}”을 완료했습니다.`, is_system: true });
  revalidateProjectPaths(projectId, actionId);
}

export async function setNextAction(projectId: string, actionId: string | null) {
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("projects").update({ next_action_id: actionId }).eq("id", projectId);
  if (error) throw new Error(getActionErrorMessage(error.message));
  revalidateProjectPaths(projectId, actionId ?? undefined);
}

export async function deleteActionItem(actionId: string, projectId: string, strategy: "REPARENT" | "CASCADE") {
  const supabase = await requiredSupabase();
  const { error } = await supabase.rpc("delete_action_item", { p_action_id: actionId, p_strategy: strategy });
  if (error) throw new Error(getActionErrorMessage(error.message));
  await supabase.from("project_records").insert({ project_id: projectId, record_type: "PLAN_CHANGED", content: "활동을 삭제했습니다.", is_system: true });
  revalidateProjectPaths(projectId, actionId);
}

export async function moveActionItem(actionId: string, projectId: string, direction: "UP" | "DOWN") {
  const supabase = await requiredSupabase();
  const { data: current, error: currentError } = await supabase.from("action_items").select("id,parent_action_id,sort_order").eq("id", actionId).eq("project_id", projectId).is("deleted_at", null).single();
  if (currentError || !current) throw new Error("활동을 찾을 수 없습니다.");
  let siblingsQuery = supabase.from("action_items").select("id,sort_order").eq("project_id", projectId).is("deleted_at", null).order("sort_order").order("created_at");
  siblingsQuery = current.parent_action_id ? siblingsQuery.eq("parent_action_id", current.parent_action_id) : siblingsQuery.is("parent_action_id", null);
  const { data: siblings, error: siblingError } = await siblingsQuery;
  if (siblingError) throw new Error(siblingError.message);
  const index = (siblings ?? []).findIndex((sibling) => sibling.id === actionId);
  const other = (siblings ?? [])[index + (direction === "UP" ? -1 : 1)];
  if (!other) return;
  const [{ error: currentUpdateError }, { error: otherUpdateError }] = await Promise.all([
    supabase.from("action_items").update({ sort_order: other.sort_order }).eq("id", current.id),
    supabase.from("action_items").update({ sort_order: current.sort_order }).eq("id", other.id)
  ]);
  if (currentUpdateError || otherUpdateError) throw new Error(currentUpdateError?.message ?? otherUpdateError?.message ?? "순서를 변경하지 못했습니다.");
  await supabase.from("project_records").insert({ project_id: projectId, record_type: "PLAN_CHANGED", content: "활동 순서를 변경했습니다.", is_system: true });
  revalidateProjectPaths(projectId, actionId);
}

export async function saveMilestone(formData: FormData) {
  const parsed = milestoneSchema.safeParse({ id: formData.get("id") || undefined, projectId: formData.get("projectId"), actionItemId: formData.get("actionItemId"), title: formData.get("title"), description: formData.get("description") ?? "", targetDate: formData.get("targetDate") ?? "", sortOrder: formData.get("sortOrder") ?? 0 });
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "마일스톤 입력을 확인해주세요.");
  const supabase = await requiredSupabase();
  const values = { project_id: parsed.data.projectId, action_item_id: parsed.data.actionItemId ?? null, title: parsed.data.title, description: parsed.data.description || null, target_date: parsed.data.targetDate || null, sort_order: parsed.data.sortOrder };
  const request = parsed.data.id ? supabase.from("project_milestones").update(values).eq("id", parsed.data.id) : supabase.from("project_milestones").insert(values);
  const { error } = await request;
  if (error) throw new Error(error.message);
  revalidateProjectPaths(parsed.data.projectId);
}

export async function toggleMilestone(milestoneId: string, projectId: string, completed: boolean) {
  const supabase = await requiredSupabase();
  const { data: milestone, error: lookupError } = await supabase.from("project_milestones").select("title").eq("id", milestoneId).eq("project_id", projectId).single();
  if (lookupError || !milestone) throw new Error("마일스톤을 찾을 수 없습니다.");
  const { error } = await supabase.from("project_milestones").update({ completed_at: completed ? new Date().toISOString() : null }).eq("id", milestoneId);
  if (error) throw new Error(error.message);
  if (completed) await supabase.from("project_records").insert({ project_id: projectId, milestone_id: milestoneId, record_type: "MILESTONE_COMPLETED", content: `마일스톤 “${milestone.title}”을 완료했습니다.`, is_system: true });
  revalidateProjectPaths(projectId);
}

export async function deleteMilestone(milestoneId: string, projectId: string) {
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("project_milestones").delete().eq("id", milestoneId).eq("project_id", projectId);
  if (error) throw new Error(error.message);
  revalidateProjectPaths(projectId);
}

export async function saveProjectNote(formData: FormData) {
  const parsed = projectRecordSchema.safeParse({ id: formData.get("id") || undefined, projectId: formData.get("projectId"), content: formData.get("content") });
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "기록 내용을 확인해주세요.");
  const supabase = await requiredSupabase();
  const request = parsed.data.id ? supabase.from("project_records").update({ content: parsed.data.content }).eq("id", parsed.data.id).eq("is_system", false) : supabase.from("project_records").insert({ project_id: parsed.data.projectId, record_type: "NOTE", content: parsed.data.content, is_system: false });
  const { error } = await request;
  if (error) throw new Error(error.message);
  revalidateProjectPaths(parsed.data.projectId);
}

export async function deleteProjectNote(recordId: string, projectId: string) {
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("project_records").delete().eq("id", recordId).eq("project_id", projectId).eq("is_system", false);
  if (error) throw new Error(error.message);
  revalidateProjectPaths(projectId);
}

export async function updateProjectStatus(id: string, status: string) {
  const supabase = await requiredSupabase();
  const { error } = await supabase.from("projects").update({ status, completed_at: status === "COMPLETED" ? new Date().toISOString() : null, archived_at: status === "ARCHIVED" ? new Date().toISOString() : null }).eq("id", id);
  if (error) throw new Error(error.message);
  await supabase.from("project_records").insert({ project_id: id, record_type: "PROJECT_STATUS_CHANGED", content: `프로젝트 상태를 ${status}(으)로 변경했습니다.`, is_system: true });
  revalidateProjectPaths(id);
}
