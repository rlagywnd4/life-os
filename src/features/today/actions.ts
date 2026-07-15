"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { dailyPlanSchema } from "@/lib/validation/schemas";
import { toDateOnlyInKorea } from "@/lib/dates/korea";

export async function upsertDailyPlan(formData: FormData) {
  const parsed = dailyPlanSchema.safeParse({
    planDate: formData.get("planDate") ?? toDateOnlyInKorea(),
    energyLevel: formData.get("energyLevel"),
    dayMode: formData.get("dayMode"),
    note: formData.get("note") ?? "",
    restReason: formData.get("restReason") ?? ""
  });
  if (!parsed.success) throw new Error("오늘 계획 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");

  const { error } = await supabase.from("daily_plans").upsert(
    {
      plan_date: parsed.data.planDate,
      energy_level: parsed.data.energyLevel,
      day_mode: parsed.data.dayMode,
      note: parsed.data.note,
      rest_reason: parsed.data.restReason
    },
    { onConflict: "user_id,plan_date" }
  );
  if (error) throw new Error(error.message);

  revalidatePath("/dashboard");
  revalidatePath("/today");
}

export async function addActionToToday(formData: FormData) {
  const actionId = String(formData.get("actionId") ?? "");
  const targetDate = String(formData.get("targetDate") ?? toDateOnlyInKorea());
  const makeCore = formData.get("makeCore") === "on";
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.rpc("add_core_action_to_today", {
    action_id: actionId,
    target_date: targetDate,
    make_core: makeCore
  });
  if (error) throw new Error(error.message);
  revalidatePath("/today");
  revalidatePath("/dashboard");
}

export async function completeAction(actionId: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase
    .from("action_items")
    .update({ status: "DONE", completed_at: new Date().toISOString() })
    .eq("id", actionId);
  if (error) throw new Error(error.message);
  revalidatePath("/today");
  revalidatePath("/history");
}
