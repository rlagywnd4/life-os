"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { actionSchema } from "@/lib/validation/schemas";

export async function createActionItem(formData: FormData) {
  const parsed = actionSchema.safeParse({
    projectId: formData.get("projectId"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    estimatedMinutes: formData.get("estimatedMinutes") ?? 30
  });
  if (!parsed.success) throw new Error("행동 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase.from("action_items").insert({
    project_id: parsed.data.projectId,
    title: parsed.data.title,
    description: parsed.data.description,
    estimated_minutes: parsed.data.estimatedMinutes
  });
  if (error) throw new Error(error.message);

  revalidatePath("/projects");
  revalidatePath(`/projects/${parsed.data.projectId}`);
}

export async function updateProjectStatus(id: string, status: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("projects").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/projects");
  revalidatePath(`/projects/${id}`);
}
