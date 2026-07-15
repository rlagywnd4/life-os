import Link from "next/link";
import { Calendar, FolderKanban, Inbox, Moon } from "lucide-react";
import { QuickInboxForm } from "@/components/quick-inbox-form";
import { createClient } from "@/lib/supabase/server";
import { toDateOnlyInKorea } from "@/lib/dates/korea";

export default async function DashboardPage() {
  const supabase = await createClient();
  const today = toDateOnlyInKorea();

  const profile = supabase ? await supabase.from("profiles").select("*").single() : null;
  const inboxCount = supabase
    ? await supabase.from("inbox_items").select("id", { count: "exact", head: true }).eq("status", "UNREVIEWED")
    : { count: 0 };
  const activeProjects = supabase
    ? await supabase.from("projects").select("id,title,status").eq("status", "ACTIVE").order("updated_at", { ascending: false })
    : { data: [] };
  const todayPlan = supabase
    ? await supabase.from("daily_plans").select("*").eq("plan_date", today).maybeSingle()
    : { data: null };
  const completed = supabase
    ? await supabase.from("action_items").select("id", { count: "exact", head: true }).eq("status", "DONE")
    : { count: 0 };

  const displayName = profile?.data?.display_name ?? "사용자";

  return (
    <div className="grid gap-6">
      <header className="grid gap-2">
        <p className="muted">{today}</p>
        <h1 className="text-3xl font-bold text-ink">{displayName}님의 LifeOS</h1>
      </header>

      <section className="panel grid gap-3">
        <h2 className="text-lg font-semibold text-ink">빠른 Inbox</h2>
        <QuickInboxForm />
      </section>

      <section className="grid gap-3 md:grid-cols-4">
        <article className="panel">
          <Inbox className="mb-3 text-moss" />
          <p className="text-2xl font-bold">{inboxCount.count ?? 0}</p>
          <p className="muted">미검토 Inbox</p>
        </article>
        <article className="panel">
          <FolderKanban className="mb-3 text-sky" />
          <p className="text-2xl font-bold">{activeProjects.data?.length ?? 0} / {profile?.data?.max_active_projects ?? 3}</p>
          <p className="muted">활성 프로젝트</p>
        </article>
        <article className="panel">
          <Calendar className="mb-3 text-berry" />
          <p className="text-2xl font-bold">{todayPlan.data?.energy_level ?? "미정"}</p>
          <p className="muted">오늘 에너지</p>
        </article>
        <article className="panel">
          <Moon className="mb-3 text-amber" />
          <p className="text-2xl font-bold">{completed.count ?? 0}</p>
          <p className="muted">완료한 작은 행동</p>
        </article>
      </section>

      <section className="grid gap-3 lg:grid-cols-2">
        <div className="panel">
          <h2 className="mb-3 font-semibold">오늘 계획</h2>
          <p className="muted mb-4">
            {todayPlan.data?.day_mode === "REST" || todayPlan.data?.day_mode === "RECOVERY"
              ? "오늘은 회복을 선택한 날입니다. 쉬는 것도 계획의 일부입니다."
              : "지금 상태에 맞는 한 가지 행동만 선택해도 충분합니다."}
          </p>
          <Link className="btn-secondary" href="/today">오늘 계획 만들기</Link>
        </div>
        <div className="panel">
          <h2 className="mb-3 font-semibold">주간 리뷰</h2>
          <p className="muted mb-4">Inbox와 프로젝트를 돌아보고 다음 주 초점을 고릅니다.</p>
          <Link className="btn-secondary" href="/weekly-review">리뷰 열기</Link>
        </div>
      </section>
    </div>
  );
}
