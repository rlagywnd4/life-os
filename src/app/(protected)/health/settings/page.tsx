import { HealthTabs } from "@/components/health-tabs";
import { saveHealthProfile } from "@/features/health/actions";
import { createClient } from "@/lib/supabase/server";

const weekdays = [
  [1, "월"],
  [2, "화"],
  [3, "수"],
  [4, "목"],
  [5, "금"],
  [6, "토"],
  [0, "일"]
];

export default async function HealthSettingsPage() {
  const supabase = await createClient();
  const { data: profile } = supabase ? await supabase.from("health_profiles").select("*").maybeSingle() : { data: null };
  const selectedWeekdays = profile?.snack_weekdays ?? [1, 2, 3, 4, 5];

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">건강 설정</h1>
        <p className="muted mt-2">현재 체중과 최종 목표 체중만 있어도 시작할 수 있습니다.</p>
      </header>
      <HealthTabs />

      <form action={saveHealthProfile} className="grid gap-6">
        <section className="panel grid gap-3">
          <h2 className="text-lg font-semibold">다이어트 프로필</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <label className="grid gap-1">
              <span className="label">현재 체중 *</span>
              <input className="field" name="currentWeightKg" type="number" step="0.1" defaultValue={profile?.current_weight_kg ?? ""} required />
            </label>
            <label className="grid gap-1">
              <span className="label">최종 목표 체중 *</span>
              <input className="field" name="targetWeightKg" type="number" step="0.1" defaultValue={profile?.target_weight_kg ?? ""} required />
            </label>
            <label className="grid gap-1">
              <span className="label">키</span>
              <input className="field" name="heightCm" type="number" step="0.1" defaultValue={profile?.height_cm ?? ""} />
            </label>
            <label className="grid gap-1">
              <span className="label">출생연도</span>
              <input className="field" name="birthYear" type="number" defaultValue={profile?.birth_year ?? ""} />
            </label>
          </div>
          <textarea className="field min-h-24" name="goalDescription" placeholder="목표 설명" defaultValue={profile?.goal_description ?? ""} />
          <div className="grid gap-3 sm:grid-cols-3">
            <label className="grid gap-1">
              <span className="label">활동 수준</span>
              <select className="field" name="activityLevel" defaultValue={profile?.activity_level ?? ""}>
                <option value="">선택 안 함</option>
                <option value="LOW">낮음</option>
                <option value="LIGHT">가벼움</option>
                <option value="MODERATE">보통</option>
                <option value="HIGH">높음</option>
              </select>
            </label>
            <label className="grid gap-1">
              <span className="label">평소 체중 측정 시간</span>
              <select className="field" name="usualWeighInTime" defaultValue={profile?.usual_weigh_in_time ?? ""}>
                <option value="">선택 안 함</option>
                <option value="MORNING">아침</option>
                <option value="AFTER_WORK">퇴근 후</option>
                <option value="EVENING">저녁</option>
                <option value="BEFORE_SLEEP">자기 전</option>
                <option value="OTHER">기타</option>
              </select>
            </label>
            <label className="grid gap-1">
              <span className="label">주간 권장 감량 속도</span>
              <input className="field" name="weeklyLossRateKg" type="number" step="0.1" defaultValue={profile?.weekly_loss_rate_kg ?? 0.5} />
            </label>
          </div>
        </section>

        <section className="panel grid gap-3">
          <h2 className="text-lg font-semibold">빠르게 걷기</h2>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="grid gap-1">
              <span className="label">평일 목표 시간</span>
              <input className="field" name="weekdayBriskWalkMinutes" type="number" defaultValue={profile?.weekday_brisk_walk_minutes ?? 20} />
            </label>
            <label className="grid gap-1">
              <span className="label">저에너지 모드 목표 시간</span>
              <input className="field" name="lowEnergyWalkMinutes" type="number" defaultValue={profile?.low_energy_walk_minutes ?? 5} />
            </label>
          </div>
        </section>

        <section className="panel grid gap-3">
          <h2 className="text-lg font-semibold">계획된 간식</h2>
          <label className="flex items-center gap-2 text-sm font-semibold">
            <input type="checkbox" name="snackReminderEnabled" defaultChecked={profile?.snack_reminder_enabled ?? true} /> 알림 사용
          </label>
          <div className="grid gap-3 sm:grid-cols-3">
            <label className="grid gap-1">
              <span className="label">알림 시간</span>
              <input className="field" name="snackReminderTime" type="time" defaultValue={(profile?.snack_reminder_time ?? "17:30").slice(0, 5)} />
            </label>
            <label className="grid gap-1">
              <span className="label">기본 간식 이름</span>
              <input className="field" name="defaultSnackName" defaultValue={profile?.default_snack_name ?? "퇴근 전 계획된 간식"} />
            </label>
            <label className="grid gap-1">
              <span className="label">예상 섭취량 또는 메모</span>
              <input className="field" name="defaultSnackNote" defaultValue={profile?.default_snack_note ?? ""} />
            </label>
          </div>
          <div className="flex flex-wrap gap-2">
            {weekdays.map(([value, label]) => (
              <label key={value} className="btn-secondary">
                <input className="mr-2" type="checkbox" name="snackWeekdays" value={value} defaultChecked={selectedWeekdays.includes(Number(value))} />
                {label}
              </label>
            ))}
          </div>
          <p className="muted">푸시 알림은 아직 mock 단계입니다. 설정은 저장하고, 앱 접속 시 예정된 간식을 보여줍니다.</p>
        </section>

        <button className="btn-primary">건강 설정 저장</button>
      </form>
    </div>
  );
}
