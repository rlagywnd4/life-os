"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

function parseEvent(formData: FormData) {
  const id = String(formData.get("id") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const eventDate = String(formData.get("eventDate") ?? "");
  const startTime = String(formData.get("startTime") ?? "");
  const endTime = String(formData.get("endTime") ?? "");
  const isAllDay = formData.get("isAllDay") === "on";
  if (!title || title.length > 160 || !/^\d{4}-\d{2}-\d{2}$/.test(eventDate)) throw new Error("일정 제목과 날짜를 확인해주세요.");
  if (startTime && endTime && endTime <= startTime) throw new Error("종료 시간은 시작 시간 이후여야 합니다.");
  return { id, title, eventDate, startTime: startTime || null, endTime: endTime || null, isAllDay };
}

export async function saveCalendarEvent(formData: FormData) {
  const event = parseEvent(formData);
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const values = { title: event.title, event_date: event.eventDate, start_time: event.isAllDay ? null : event.startTime, end_time: event.isAllDay ? null : event.endTime, is_all_day: event.isAllDay };
  const { error } = event.id ? await supabase.from("calendar_events").update(values).eq("id", event.id) : await supabase.from("calendar_events").insert(values);
  if (error) throw new Error(error.message);
  revalidatePath("/calendar");
}

export async function deleteCalendarEvent(id: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("calendar_events").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/calendar");
}
