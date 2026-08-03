"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { inboxSchema, inboxUpdateSchema, projectConversionSchema } from "@/lib/validation/schemas";

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

export async function updateInboxItem(formData: FormData) {
  const parsed = inboxUpdateSchema.safeParse({
    id: formData.get("id"),
    title: formData.get("title"),
    description: formData.get("description") ?? "",
    category: formData.get("category") ?? "ETC"
  });
  if (!parsed.success) throw new Error("Inbox 입력을 확인해주세요.");
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("inbox_items").update({
    title: parsed.data.title,
    description: parsed.data.description || null,
    category: parsed.data.category
  }).eq("id", parsed.data.id).eq("status", "UNREVIEWED");
  if (error) throw new Error(error.message);
  revalidatePath("/inbox");
}

export async function deleteInboxItem(id: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("inbox_items").delete().eq("id", id).eq("status", "UNREVIEWED");
  if (error) throw new Error(error.message);
  revalidatePath("/inbox");
}

export async function createInboxCalendarEvent(formData: FormData) {
  const id = String(formData.get("id") ?? "");
  const eventDate = String(formData.get("eventDate") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(id) || !/^\d{4}-\d{2}-\d{2}$/.test(eventDate)) {
    throw new Error("일정 날짜를 확인해주세요.");
  }
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { data: item, error: lookupError } = await supabase.from("inbox_items").select("title,description").eq("id", id).eq("status", "UNREVIEWED").single();
  if (lookupError || !item) throw new Error("이미 처리된 Inbox 항목입니다.");
  const { error } = await supabase.from("calendar_events").insert({ source_inbox_item_id: id, title: item.title, description: item.description, event_date: eventDate, is_all_day: true });
  if (error) throw new Error(error.message);
  const { error: statusError } = await supabase.from("inbox_items").update({ status: "ARCHIVED", reviewed_at: new Date().toISOString() }).eq("id", id).eq("status", "UNREVIEWED");
  if (statusError) throw new Error(statusError.message);
  revalidatePath("/inbox");
  revalidatePath("/calendar");
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
