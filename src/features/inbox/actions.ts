"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { inboxSchema, projectConversionSchema } from "@/lib/validation/schemas";

export async function createInboxItem(formData: FormData) {
  const parsed = inboxSchema.safeParse({
    title: formData.get("title"),
    description: formData.get("description") ?? undefined,
    category: formData.get("category") ?? "ETC"
  });
  if (!parsed.success) throw new Error("Inbox 제목을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase.from("inbox_items").insert(parsed.data);
  if (error) throw new Error(error.message);

  revalidatePath("/dashboard");
  revalidatePath("/inbox");
}

export async function updateInboxStatus(id: string, status: "SOMEDAY" | "DISCARDED" | "ARCHIVED") {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("inbox_items").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/inbox");
}

export async function convertInboxToProject(formData: FormData) {
  const parsed = projectConversionSchema.safeParse({
    inboxId: formData.get("inboxId"),
    title: formData.get("title"),
    reason: formData.get("reason") ?? "",
    desiredOutcome: formData.get("desiredOutcome") ?? "",
    activateNow: formData.get("activateNow") === "on"
  });
  if (!parsed.success) throw new Error("프로젝트 전환 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase.rpc("convert_inbox_to_project", {
    inbox_id: parsed.data.inboxId,
    project_title: parsed.data.title,
    project_reason: parsed.data.reason ?? "",
    project_desired_outcome: parsed.data.desiredOutcome ?? "",
    activate_now: parsed.data.activateNow
  });
  if (error) throw new Error(error.message);

  revalidatePath("/inbox");
  revalidatePath("/projects");
  redirect("/projects");
}
