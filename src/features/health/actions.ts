"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { healthCheckInSchema, healthProfileSchema, healthWeightGoalSchema } from "@/lib/validation/schemas";

function normalizeOptional<T>(value: T | "" | undefined) {
  return value === "" || value === undefined ? null : value;
}

export async function saveHealthProfile(formData: FormData) {
  const snackWeekdays = formData.getAll("snackWeekdays");
  const parsed = healthProfileSchema.safeParse({
    heightCm: formData.get("heightCm"),
    birthYear: formData.get("birthYear"),
    currentWeightKg: formData.get("currentWeightKg"),
    targetWeightKg: formData.get("targetWeightKg"),
    goalDescription: formData.get("goalDescription") ?? "",
    activityLevel: formData.get("activityLevel") ?? "",
    usualWeighInTime: formData.get("usualWeighInTime") ?? "",
    weeklyLossRateKg: formData.get("weeklyLossRateKg") ?? 0.5,
    weekdayBriskWalkMinutes: formData.get("weekdayBriskWalkMinutes") ?? 20,
    lowEnergyWalkMinutes: formData.get("lowEnergyWalkMinutes") ?? 5,
    snackReminderEnabled: formData.get("snackReminderEnabled") === "on",
    snackReminderTime: formData.get("snackReminderTime") ?? "17:30",
    snackWeekdays: snackWeekdays.length > 0 ? snackWeekdays : [1, 2, 3, 4, 5],
    defaultSnackName: formData.get("defaultSnackName") ?? "퇴근 전 계획된 간식",
    defaultSnackNote: formData.get("defaultSnackNote") ?? ""
  });
  if (!parsed.success) throw new Error("건강 프로필 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) throw new Error("UNAUTHORIZED");

  const { error } = await supabase.from("health_profiles").upsert(
    {
      user_id: userId,
      height_cm: parsed.data.heightCm ?? null,
      birth_year: parsed.data.birthYear ?? null,
      current_weight_kg: parsed.data.currentWeightKg,
      target_weight_kg: parsed.data.targetWeightKg,
      goal_description: parsed.data.goalDescription || null,
      activity_level: normalizeOptional(parsed.data.activityLevel),
      usual_weigh_in_time: normalizeOptional(parsed.data.usualWeighInTime),
      weekly_loss_rate_kg: parsed.data.weeklyLossRateKg,
      weekday_brisk_walk_minutes: parsed.data.weekdayBriskWalkMinutes,
      low_energy_walk_minutes: parsed.data.lowEnergyWalkMinutes,
      snack_reminder_enabled: parsed.data.snackReminderEnabled,
      snack_reminder_time: parsed.data.snackReminderTime,
      snack_weekdays: parsed.data.snackWeekdays,
      default_snack_name: parsed.data.defaultSnackName,
      default_snack_note: parsed.data.defaultSnackNote || null
    },
    { onConflict: "user_id" }
  );
  if (error) throw new Error(error.message);

  revalidatePath("/health");
  revalidatePath("/health/settings");
}

export async function saveHealthCheckIn(formData: FormData) {
  const parsed = healthCheckInSchema.safeParse({
    checkInDate: formData.get("checkInDate"),
    weightKg: formData.get("weightKg"),
    steps: formData.get("steps"),
    briskWalkStatus: formData.get("briskWalkStatus") ?? "UNRECORDED",
    plannedSnackDone: formData.get("plannedSnackDone") ?? "",
    unplannedSnack: formData.get("unplannedSnack") === "on",
    dinnerOvereating: formData.get("dinnerOvereating") === "on",
    freeMeal: formData.get("freeMeal") === "on",
    alcohol: formData.get("alcohol") === "on",
    exerciseCompletion: formData.get("exerciseCompletion") ?? "NOT_DONE",
    sleepHours: formData.get("sleepHours"),
    conditionLevel: formData.get("conditionLevel") ?? "",
    stressLevel: formData.get("stressLevel") ?? "",
    lowEnergyMode: formData.get("lowEnergyMode") === "on",
    note: formData.get("note") ?? ""
  });
  if (!parsed.success) throw new Error("체크인 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) throw new Error("UNAUTHORIZED");

  const { error } = await supabase.from("health_check_ins").upsert(
    {
      user_id: userId,
      check_in_date: parsed.data.checkInDate,
      weight_kg: parsed.data.weightKg ?? null,
      steps: parsed.data.steps ?? null,
      brisk_walk_status: parsed.data.briskWalkStatus,
      planned_snack_done: parsed.data.plannedSnackDone === "" ? null : parsed.data.plannedSnackDone === "true",
      unplanned_snack: parsed.data.unplannedSnack,
      dinner_overeating: parsed.data.dinnerOvereating,
      free_meal: parsed.data.freeMeal,
      alcohol: parsed.data.alcohol,
      exercise_completion: parsed.data.exerciseCompletion,
      sleep_hours: parsed.data.sleepHours ?? null,
      condition_level: normalizeOptional(parsed.data.conditionLevel),
      stress_level: normalizeOptional(parsed.data.stressLevel),
      low_energy_mode: parsed.data.lowEnergyMode,
      note: parsed.data.note || null
    },
    { onConflict: "user_id,check_in_date" }
  );
  if (error) throw new Error(error.message);

  revalidatePath("/health");
  revalidatePath("/health/weight");
  revalidatePath("/health/report");
}

export async function saveHealthGoal(formData: FormData) {
  const parsed = healthWeightGoalSchema.safeParse({
    id: formData.get("id") || undefined,
    targetWeightKg: formData.get("targetWeightKg"),
    goalName: formData.get("goalName"),
    sortOrder: formData.get("sortOrder") ?? 0,
    achieved: formData.get("achieved") === "on",
    achievedDate: formData.get("achievedDate") ?? ""
  });
  if (!parsed.success) throw new Error("목표 입력을 확인해주세요.");

  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) throw new Error("UNAUTHORIZED");

  const row = {
    user_id: userId,
    target_weight_kg: parsed.data.targetWeightKg,
    goal_name: parsed.data.goalName,
    sort_order: parsed.data.sortOrder,
    achieved: parsed.data.achieved,
    achieved_date: parsed.data.achievedDate || null
  };

  const { error } = parsed.data.id
    ? await supabase.from("health_weight_goals").update(row).eq("id", parsed.data.id)
    : await supabase.from("health_weight_goals").insert(row);
  if (error) throw new Error(error.message);

  revalidatePath("/health/weight");
}

export async function deleteHealthGoal(id: string) {
  const supabase = await createClient();
  if (!supabase) throw new Error("Supabase 환경 변수가 필요합니다.");
  const { error } = await supabase.from("health_weight_goals").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/health/weight");
}
