import Link from "next/link";
import { Dumbbell, Footprints, Moon, Utensils } from "lucide-react";
import { ActionButton } from "@/components/action-button";
import { HealthTabs } from "@/components/health-tabs";
import { saveHealthCheckIn } from "@/features/health/actions";
import { createClient } from "@/lib/supabase/server";
import { toDateOnlyInKorea } from "@/lib/dates/korea";

const briskOptions = [
  ["UNRECORDED", "미기록"],
  ["DONE", "완료"],
  ["PARTIAL", "부분 완료"],
  ["ALTERNATIVE", "대체 활동"],
  ["REST", "휴식"]
];

export default async function HealthTodayPage() {
  const supabase = await createClient();
  const today = toDateOnlyInKorea();
  const [{ data: profile }, { data: checkIn }] = supabase
    ? await Promise.all([
        supabase.from("health_profiles").select("*").maybeSingle(),
        supabase.from("health_check_ins").select("*").eq("check_in_date", today).maybeSingle()
      ])
    : [{ data: null }, { data: null }];

  if (!profile) {
    return (
      <div className="grid gap-6">
        <header>
          <h1 className="text-3xl font-bold">건강</h1>
          <p className="muted mt-2">다이어트 프로필을 먼저 만들면 오늘 체크인을 시작할 수 있습니다.</p>
        </header>
        <HealthTabs />
        <section className="panel">
          <p className="muted mb-4">현재 체중과 최종 목표 체중만 있어도 시작할 수 있습니다.</p>
          <Link className="btn-primary" href="/health/settings">프로필 만들기</Link>
        </section>
      </div>
    );
  }

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">건강</h1>
        <p className="muted mt-2">{today} · 30초 체크인</p>
      </header>
      <HealthTabs />

      <section className="grid gap-3 md:grid-cols-4">
        <article className="panel">
          <Footprints className="mb-3 text-moss" />
          <p className="text-2xl font-bold">{checkIn?.steps ?? "-"}</p>
          <p className="muted">걸음 수</p>
        </article>
        <article className="panel">
          <Utensils className="mb-3 text-berry" />
          <p className="text-2xl font-bold">{profile.default_snack_name}</p>
          <p className="muted">{profile.snack_reminder_time.slice(0, 5)} 예정 간식</p>
        </article>
        <article className="panel">
          <Dumbbell className="mb-3 text-sky" />
          <p className="text-2xl font-bold">{profile.weekday_brisk_walk_minutes}분</p>
          <p className="muted">평일 빠르게 걷기</p>
        </article>
        <article className="panel">
          <Moon className="mb-3 text-amber" />
          <p className="text-2xl font-bold">{profile.low_energy_walk_minutes}분</p>
          <p className="muted">저에너지 모드</p>
        </article>
      </section>

      <form action={saveHealthCheckIn} className="panel grid gap-4">
        <input type="hidden" name="checkInDate" value={today} />
        <div className="grid gap-3 sm:grid-cols-3">
          <label className="grid gap-1">
            <span className="label">오늘 체중</span>
            <input className="field" name="weightKg" type="number" step="0.1" defaultValue={checkIn?.weight_kg ?? ""} />
          </label>
          <label className="grid gap-1">
            <span className="label">걸음 수</span>
            <input className="field" name="steps" type="number" inputMode="numeric" defaultValue={checkIn?.steps ?? ""} />
          </label>
          <label className="grid gap-1">
            <span className="label">수면 시간</span>
            <input className="field" name="sleepHours" type="number" step="0.5" defaultValue={checkIn?.sleep_hours ?? ""} />
          </label>
        </div>

        <div className="grid gap-3 sm:grid-cols-3">
          <label className="grid gap-1">
            <span className="label">빠르게 걷기</span>
            <select className="field" name="briskWalkStatus" defaultValue={checkIn?.brisk_walk_status ?? "UNRECORDED"}>
              {briskOptions.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>
          <label className="grid gap-1">
            <span className="label">계획된 간식</span>
            <select className="field" name="plannedSnackDone" defaultValue={checkIn?.planned_snack_done === true ? "true" : checkIn?.planned_snack_done === false ? "false" : ""}>
              <option value="">미기록</option>
              <option value="true">실행</option>
              <option value="false">미실행</option>
            </select>
          </label>
          <label className="grid gap-1">
            <span className="label">운동 완료 형태</span>
            <select className="field" name="exerciseCompletion" defaultValue={checkIn?.exercise_completion ?? "NOT_DONE"}>
              <option value="NOT_DONE">미실행</option>
              <option value="FULL">전체 운동</option>
              <option value="MINIMUM">최소 운동</option>
              <option value="ALTERNATIVE">대체 운동</option>
              <option value="REST">휴식</option>
            </select>
          </label>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <label className="grid gap-1">
            <span className="label">컨디션</span>
            <select className="field" name="conditionLevel" defaultValue={checkIn?.condition_level ?? ""}>
              <option value="">미기록</option>
              <option value="VERY_LOW">매우 낮음</option>
              <option value="LOW">낮음</option>
              <option value="NORMAL">보통</option>
              <option value="GOOD">좋음</option>
              <option value="VERY_GOOD">매우 좋음</option>
            </select>
          </label>
          <label className="grid gap-1">
            <span className="label">스트레스</span>
            <select className="field" name="stressLevel" defaultValue={checkIn?.stress_level ?? ""}>
              <option value="">미기록</option>
              <option value="LOW">낮음</option>
              <option value="NORMAL">보통</option>
              <option value="HIGH">높음</option>
            </select>
          </label>
        </div>

        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-5">
          <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="unplannedSnack" defaultChecked={checkIn?.unplanned_snack ?? false} /> 계획 밖 간식</label>
          <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="dinnerOvereating" defaultChecked={checkIn?.dinner_overeating ?? false} /> 저녁 과식</label>
          <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="freeMeal" defaultChecked={checkIn?.free_meal ?? false} /> 자유식</label>
          <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="alcohol" defaultChecked={checkIn?.alcohol ?? false} /> 음주</label>
          <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="lowEnergyMode" defaultChecked={checkIn?.low_energy_mode ?? false} /> 저에너지 모드</label>
        </div>

        <textarea className="field min-h-24" name="note" placeholder="짧은 메모" defaultValue={checkIn?.note ?? ""} />
        <ActionButton className="btn-primary" pendingLabel="저장 중">체크인 저장</ActionButton>
      </form>
    </div>
  );
}
