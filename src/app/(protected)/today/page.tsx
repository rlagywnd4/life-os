import { CheckCircle2, Plus } from "lucide-react";
import { ActionButton } from "@/components/action-button";
import { createClient } from "@/lib/supabase/server";
import { toDateOnlyInKorea } from "@/lib/dates/korea";
import { addActionToToday, completeAction, upsertDailyPlan } from "@/features/today/actions";
import { getRecommendedCoreActionRange } from "@/lib/domain/rules";
import { dayModeLabels, energyLevelLabels } from "@/lib/display-labels";

export default async function TodayPage() {
  const supabase = await createClient();
  const today = toDateOnlyInKorea();
  const [{ data: plan }, { data: actionRows }] = supabase
    ? await Promise.all([
        supabase.from("daily_plans").select("*").eq("plan_date", today).maybeSingle(),
        supabase.from("action_items").select("*").in("status", ["TODO", "PLANNED", "IN_PROGRESS"]).order("created_at")
      ])
    : [{ data: null }, { data: [] }];
  const actions = actionRows ?? [];
  const range = getRecommendedCoreActionRange((plan?.energy_level ?? "MEDIUM") as "LOW" | "MEDIUM" | "HIGH");

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">오늘</h1>
        <p className="muted mt-2">{today} · 권장 핵심 행동 {range.min}~{range.max}개</p>
      </header>
      <section className="panel">
        <form action={upsertDailyPlan} className="grid gap-3">
          <input type="hidden" name="planDate" value={today} />
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="grid gap-1">
              <span className="label">에너지</span>
              <select className="field" name="energyLevel" defaultValue={plan?.energy_level ?? "MEDIUM"}>
                {Object.entries(energyLevelLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
            <label className="grid gap-1">
              <span className="label">오늘 모드</span>
              <select className="field" name="dayMode" defaultValue={plan?.day_mode ?? "NORMAL"}>
                {Object.entries(dayModeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
          </div>
          <textarea className="field min-h-24" name="note" defaultValue={plan?.note ?? ""} placeholder="하루 메모" />
          <input className="field" name="restReason" defaultValue={plan?.rest_reason ?? ""} placeholder="휴식 또는 회복을 선택한 이유" />
          <ActionButton className="btn-primary" pendingLabel="저장 중">오늘 계획 저장</ActionButton>
        </form>
        {plan?.day_mode === "REST" || plan?.day_mode === "RECOVERY" ? (
          <p className="mt-4 rounded-md border border-line bg-paper p-3 text-sm font-semibold">
            오늘은 회복을 선택한 날입니다. 쉬는 것도 계획의 일부입니다.
          </p>
        ) : null}
      </section>

      <section className="panel grid gap-3">
        <h2 className="text-lg font-semibold">행동 선택</h2>
        {actions.map((action) => (
          <form key={action.id} action={addActionToToday} className="flex flex-col gap-3 rounded-md border border-line p-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="font-semibold">{action.title}</p>
              <p className="muted">{action.estimated_minutes}분</p>
            </div>
            <input type="hidden" name="actionId" value={action.id} />
            <input type="hidden" name="targetDate" value={today} />
            <label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" name="makeCore" /> 핵심</label>
            <div className="flex gap-2">
              <ActionButton className="btn-secondary" pendingLabel="추가 중"><Plus size={18} /> 오늘로</ActionButton>
              <ActionButton className="btn-secondary" formAction={completeAction.bind(null, action.id)} pendingLabel="완료 중"><CheckCircle2 size={18} /> 완료</ActionButton>
            </div>
          </form>
        ))}
        {actions.length === 0 ? <p className="muted">선택할 행동이 없습니다. 프로젝트에서 작은 행동을 추가해보세요.</p> : null}
      </section>
    </div>
  );
}
