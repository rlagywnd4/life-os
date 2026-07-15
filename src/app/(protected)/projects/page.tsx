import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getDisplayLabel, projectStatusLabels } from "@/lib/display-labels";

const sections = ["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"];

export default async function ProjectsPage() {
  const supabase = await createClient();
  const [{ data: projectRows }, { data: actionRows }, { data: profile }] = supabase
    ? await Promise.all([
        supabase.from("projects").select("*").order("updated_at", { ascending: false }),
        supabase.from("action_items").select("id,project_id,status,title,completed_at").order("updated_at", { ascending: false }),
        supabase.from("profiles").select("*").single()
      ])
    : [{ data: [] }, { data: [] }, { data: null }];
  const projects = projectRows ?? [];
  const actions = actionRows ?? [];
  const activeCount = projects.filter((project) => project.status === "ACTIVE").length;

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">프로젝트</h1>
        <p className="muted mt-2">활성 프로젝트 {activeCount} / {profile?.max_active_projects ?? 3}</p>
      </header>
      {sections.map((status) => {
        const list = projects.filter((project) => project.status === status);
        return (
          <section key={status} className="grid gap-3">
            <h2 className="text-lg font-semibold">{getDisplayLabel(projectStatusLabels, status)}</h2>
            <div className="grid gap-3 md:grid-cols-2">
              {list.map((project) => {
                const projectActions = actions.filter((action) => action.project_id === project.id);
                const openActions = projectActions.filter((action) => action.status !== "DONE").length;
                const recentDone = projectActions.find((action) => action.status === "DONE");
                return (
                  <Link key={project.id} href={`/projects/${project.id}`} className="panel block hover:border-moss">
                    <h3 className="text-lg font-semibold">{project.title}</h3>
                    <p className="muted mt-1 line-clamp-2">{project.reason ?? "이 프로젝트를 왜 하고 싶은지 적어둘 수 있습니다."}</p>
                    <div className="mt-4 flex flex-wrap gap-2">
                      <span className="status-pill">미완료 행동 {openActions}</span>
                      {recentDone ? <span className="status-pill">최근 완료 있음</span> : null}
                    </div>
                  </Link>
                );
              })}
            </div>
          </section>
        );
      })}
    </div>
  );
}
