import { HealthTabs } from "@/components/health-tabs";
import { createClient } from "@/lib/supabase/server";
import { calculateHealthAdherence, generateHealthFeedback } from "@/lib/domain/health";

export default async function HealthReportPage() {
  const supabase = await createClient();
  const [{ data: profile }, { data: checkIns }] = supabase
    ? await Promise.all([
        supabase.from("health_profiles").select("*").maybeSingle(),
        supabase.from("health_check_ins").select("*").order("check_in_date", { ascending: false }).limit(30)
      ])
    : [{ data: null }, { data: [] }];
  const rows = checkIns ?? [];
  const adherence = calculateHealthAdherence(rows, profile);
  const feedback = generateHealthFeedback(rows, profile);

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">리포트</h1>
        <p className="muted mt-2">최근 14일 행동 유지율입니다. 기록이 없는 날은 실패로 계산하지 않습니다.</p>
      </header>
      <HealthTabs />

      <section className="panel">
        <h2 className="mb-3 text-lg font-semibold">이번 주 피드백</h2>
        <p className="leading-7 text-ink/80">{feedback}</p>
      </section>

      <section className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
        {adherence.map((item) => (
          <article key={item.key} className="panel">
            <h2 className="font-semibold">{item.label}</h2>
            <p className="mt-3 text-3xl font-bold">{item.rate === null ? "데이터 없음" : `${item.rate}%`}</p>
            <p className="muted mt-2">완료 {item.done} / 계획 기록일 {item.planned}</p>
          </article>
        ))}
      </section>
    </div>
  );
}
