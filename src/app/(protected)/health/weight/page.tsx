import { Trash2 } from "lucide-react";
import { HealthTabs } from "@/components/health-tabs";
import { deleteHealthGoal, saveHealthGoal } from "@/features/health/actions";
import { createClient } from "@/lib/supabase/server";

export default async function HealthWeightPage() {
  const supabase = await createClient();
  const [{ data: profile }, { data: goals }, { data: checkIns }] = supabase
    ? await Promise.all([
        supabase.from("health_profiles").select("*").maybeSingle(),
        supabase.from("health_weight_goals").select("*").order("sort_order"),
        supabase.from("health_check_ins").select("*").order("check_in_date", { ascending: false }).limit(14)
      ])
    : [{ data: null }, { data: [] }, { data: [] }];
  const goalRows = goals ?? [];
  const weightRows = (checkIns ?? []).filter((row) => row.weight_kg);

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">체중</h1>
        <p className="muted mt-2">단일 측정값보다 흐름을 천천히 봅니다.</p>
      </header>
      <HealthTabs />
      <section className="grid gap-3 md:grid-cols-3">
        <article className="panel">
          <p className="muted">현재 체중</p>
          <p className="text-2xl font-bold">{profile?.current_weight_kg ?? "-"} kg</p>
        </article>
        <article className="panel">
          <p className="muted">최종 목표</p>
          <p className="text-2xl font-bold">{profile?.target_weight_kg ?? "-"} kg</p>
        </article>
        <article className="panel">
          <p className="muted">최근 기록</p>
          <p className="text-2xl font-bold">{weightRows[0]?.weight_kg ?? "-"} kg</p>
        </article>
      </section>

      <section className="panel grid gap-3">
        <h2 className="text-lg font-semibold">단계별 목표 체중</h2>
        {goalRows.map((goal) => (
          <form key={goal.id} action={saveHealthGoal} className="grid gap-2 rounded-md border border-line p-3 md:grid-cols-[1fr_140px_90px_120px_auto] md:items-end">
            <input type="hidden" name="id" value={goal.id} />
            <label className="grid gap-1">
              <span className="label">목표 이름</span>
              <input className="field" name="goalName" defaultValue={goal.goal_name} />
            </label>
            <label className="grid gap-1">
              <span className="label">목표 체중</span>
              <input className="field" name="targetWeightKg" type="number" step="0.1" defaultValue={goal.target_weight_kg} />
            </label>
            <label className="grid gap-1">
              <span className="label">순서</span>
              <input className="field" name="sortOrder" type="number" defaultValue={goal.sort_order} />
            </label>
            <label className="grid gap-1">
              <span className="label">달성 일자</span>
              <input className="field" name="achievedDate" type="date" defaultValue={goal.achieved_date ?? ""} />
            </label>
            <div className="flex gap-2">
              <label className="btn-secondary"><input className="mr-2" type="checkbox" name="achieved" defaultChecked={goal.achieved} /> 달성</label>
              <button className="btn-primary">저장</button>
              <button className="btn-secondary" formAction={deleteHealthGoal.bind(null, goal.id)}><Trash2 size={18} /></button>
            </div>
          </form>
        ))}
      </section>

      <form action={saveHealthGoal} className="panel grid gap-3 md:grid-cols-[1fr_160px_100px_auto] md:items-end">
        <label className="grid gap-1">
          <span className="label">새 목표 이름</span>
          <input className="field" name="goalName" placeholder="예: 여행 전 가벼운 몸" required />
        </label>
        <label className="grid gap-1">
          <span className="label">목표 체중</span>
          <input className="field" name="targetWeightKg" type="number" step="0.1" required />
        </label>
        <label className="grid gap-1">
          <span className="label">순서</span>
          <input className="field" name="sortOrder" type="number" defaultValue={goalRows.length + 1} />
        </label>
        <button className="btn-primary">목표 추가</button>
      </form>
    </div>
  );
}
