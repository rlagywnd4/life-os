import { createClient } from "@/lib/supabase/server";

const steps = ["Inbox 검토", "활성 프로젝트 검토", "완료 행동 확인", "다음 주 초점", "회고 작성"];

export default async function WeeklyReviewPage() {
  const supabase = await createClient();
  const [{ data: inboxRows }, { data: projectRows }, { data: actionRows }] = supabase
    ? await Promise.all([
        supabase.from("inbox_items").select("*").eq("status", "UNREVIEWED").limit(5),
        supabase.from("projects").select("*").eq("status", "ACTIVE"),
        supabase.from("action_items").select("*").in("status", ["DONE", "SKIPPED"]).limit(8)
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];
  const inbox = inboxRows ?? [];
  const projects = projectRows ?? [];
  const actions = actionRows ?? [];

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">주간 리뷰</h1>
        <p className="muted mt-2">중간 저장 가능한 5단계 흐름의 초판입니다.</p>
      </header>
      <ol className="grid gap-3 md:grid-cols-5">
        {steps.map((step, index) => <li key={step} className="panel text-sm font-semibold">{index + 1}. {step}</li>)}
      </ol>
      <section className="grid gap-3 lg:grid-cols-3">
        <article className="panel">
          <h2 className="mb-3 font-semibold">검토할 Inbox</h2>
          {inbox.map((item) => <p key={item.id} className="border-b border-line py-2 text-sm">{item.title}</p>)}
        </article>
        <article className="panel">
          <h2 className="mb-3 font-semibold">활성 프로젝트</h2>
          {projects.map((project) => <p key={project.id} className="border-b border-line py-2 text-sm">{project.title}</p>)}
        </article>
        <article className="panel">
          <h2 className="mb-3 font-semibold">최근 결과</h2>
          {actions.map((action) => <p key={action.id} className="border-b border-line py-2 text-sm">{action.title}</p>)}
        </article>
      </section>
      <form className="panel grid gap-3">
        <textarea className="field min-h-24" placeholder="잘 된 점" />
        <textarea className="field min-h-24" placeholder="어려웠던 점" />
        <textarea className="field min-h-24" placeholder="다음 주 방향" />
        <button className="btn-primary" type="button">회고 임시 저장</button>
      </form>
    </div>
  );
}
