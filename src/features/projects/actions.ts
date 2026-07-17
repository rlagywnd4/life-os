"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { actionSchema, actionUpdateSchema } from "@/lib/validation/schemas";

function getActionErrorMessage(message: string) {
  if (message.includes("ACTION_HIERARCHY_CYCLE")) {
    return "자기 자신이나 자신의 하위 활동으로는 이동할 수 없습니다.";
  }
  if (
    message.includes("ACTION_PARENT_NOT_FOUND") ||
    message.includes("ACTION_PARENT_NOT_AVAILABLE")
  ) {
    return "선택한 부모 활동을 사용할 수 없습니다.";
  }
  return message;
}

function revalidateActionPaths(projectId: string, actionId?: string) {
  revalidatePath("/projects");
  revalidatePath(`/projects/${projectId}`);
  if (actionId) revalidatePath(`/projects/${projectId}/actions/${actionId}`);
  revalidatePath("/today");
  revalidatePath("/history");
}

export async function createActionItem(formData: FormData) {
  const parsed = actionSchema.safeParse({
    projectId: formData.get("projectId"),
    parentActionId: formData.get("parentActionId"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    estimatedMinutes: formData.get("estimatedMinutes") ?? 30
  });
  if (!parsed.success) throw new Error("행동 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase.from("action_items").insert({
    project_id: parsed.data.projectId,
    parent_action_id: parsed.data.parentActionId ?? null,
    title: parsed.data.title,
    description: parsed.data.description,
    estimated_minutes: parsed.data.estimatedMinutes
  });
  if (error) throw new Error(getActionErrorMessage(error.message));

  revalidateActionPaths(parsed.data.projectId, parsed.data.parentActionId);
}

export async function updateActionItem(formData: FormData) {
  const parsed = actionUpdateSchema.safeParse({
    actionId: formData.get("actionId"),
    projectId: formData.get("projectId"),
    parentActionId: formData.get("parentActionId"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    estimatedMinutes: formData.get("estimatedMinutes") ?? 30
  });
  if (!parsed.success) throw new Error("활동 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase
    .from("action_items")
    .update({
      parent_action_id: parsed.data.parentActionId ?? null,
      title: parsed.data.title,
      description: parsed.data.description,
      estimated_minutes: parsed.data.estimatedMinutes
    })
    .eq("id", parsed.data.actionId)
    .eq("project_id", parsed.data.projectId);
  if (error) throw new Error(getActionErrorMessage(error.message));

  revalidateActionPaths(parsed.data.projectId, parsed.data.actionId);
}

export async function updateActionCompletion(
  actionId: string,
  projectId: string,
  completed: boolean
) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase
    .from("action_items")
    .update({
      status: completed ? "DONE" : "TODO",
      completed_at: completed ? new Date().toISOString() : null
    })
    .eq("id", actionId)
    .eq("project_id", projectId);
  if (error) throw new Error(error.message);

  revalidateActionPaths(projectId, actionId);
}

export async function updateProjectStatus(id: string, status: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase
    .from("projects")
    .update({ status })
    .eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/projects");
  revalidatePath(`/projects/${id}`);
}
