import { createClient } from "@/lib/supabase/server";
import { actionStatusLabels, dayModeLabels, energyLevelLabels, getDisplayLabel, weeklyReviewStatusLabels } from "@/lib/display-labels";

export default async function HistoryPage() {
  const supabase = await createClient();
  const [{ data: actionRows }, { data: planRows }, { data: reviewRows }] = supabase
    ? await Promise.all([
        supabase.from("action_items").select("*").order("updated_at", { ascending: false }).limit(30),
        supabase.from("daily_plans").select("*").order("plan_date", { ascending: false }).limit(14),
        supabase.from("weekly_reviews").select("*").order("week_start_date", { ascending: false }).limit(4)
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];
  const actions = actionRows ?? [];
  const plans = planRows ?? [];
  const reviews = reviewRows ?? [];

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">기록</h1>
        <p className="muted mt-2">점수가 아니라, 방향을 다시 보기 위한 기록입니다.</p>
      </header>
      <section className="grid gap-3 lg:grid-cols-3">
        <article className="panel">
          <h2 className="mb-3 font-semibold">최근 행동</h2>
          {actions.map((action) => <p key={action.id} className="border-b border-line py-2 text-sm">{action.title} · {getDisplayLabel(actionStatusLabels, action.status)}</p>)}
        </article>
        <article className="panel">
          <h2 className="mb-3 font-semibold">최근 14일</h2>
          {plans.map((plan) => <p key={plan.id} className="border-b border-line py-2 text-sm">{plan.plan_date} · {getDisplayLabel(energyLevelLabels, plan.energy_level)} · {getDisplayLabel(dayModeLabels, plan.day_mode)}</p>)}
        </article>
        <article className="panel">
          <h2 className="mb-3 font-semibold">주간 회고</h2>
          {reviews.map((review) => <p key={review.id} className="border-b border-line py-2 text-sm">{review.week_start_date} · {getDisplayLabel(weeklyReviewStatusLabels, review.status)}</p>)}
        </article>
      </section>
    </div>
  );
}
