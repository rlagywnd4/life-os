import Link from "next/link";
import { Plus } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { getDisplayLabel, projectStatusLabels } from "@/lib/display-labels";
import { calculateProjectProgress, getProjectPlanningGaps } from "@/lib/domain/project-planning";

const sections = ["DRAFT", "ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED", "ARCHIVED"];

export default async function ProjectsPage({ searchParams }: { searchParams: Promise<{ status?: string; sort?: string }> }) {
  const params = await searchParams;
  const supabase = await createClient();
  const [{ data: projectRows }, { data: actionRows }, { data: milestoneRows }, { data: profile }] = supabase ? await Promise.all([
    supabase.from("projects").select("*").order(params.sort === "created" ? "created_at" : params.sort === "target" ? "target_date" : "updated_at", { ascending: false }),
    supabase.from("action_items").select("id,project_id,parent_action_id,title,status,completed_at,is_stage,deleted_at,scheduled_date,due_date").is("deleted_at", null).order("sort_order").order("created_at"),
    supabase.from("project_milestones").select("id,project_id,title,target_date,completed_at").order("target_date"),
    supabase.from("profiles").select("*").single()
  ]) : [{ data: [] }, { data: [] }, { data: [] }, { data: null }];
  const projects = projectRows ?? [];
  const actions = actionRows ?? [];
  const milestones = milestoneRows ?? [];
  const activeCount = projects.filter((project) => project.status === "ACTIVE").length;
  const visibleSections = params.status ? sections.filter((status) => status === params.status) : sections;

  return <div className="grid gap-6">
    <header className="grid gap-3 sm:flex sm:items-end sm:justify-between"><div><h1 className="text-3xl font-bold">프로젝트</h1><p className="muted mt-2">목표를 정하고, 단계를 나누고, 다음 행동을 일정에 배치합니다.</p><p className="muted mt-1">진행 중 {activeCount} / {profile?.max_active_projects ?? 3}</p></div><Link href="/projects/new" className="btn-primary w-fit"><Plus size={18} /> 새 프로젝트</Link></header>
    <form className="grid gap-2 sm:grid-cols-2"><select className="field" name="status" defaultValue={params.status ?? ""}><option value="">전체 상태</option>{sections.map((status) => <option key={status} value={status}>{getDisplayLabel(projectStatusLabels, status)}</option>)}</select><select className="field" name="sort" defaultValue={params.sort ?? "updated"}><option value="updated">최근 수정순</option><option value="target">목표일순</option><option value="created">생성일순</option></select><button className="btn-secondary sm:col-span-2">적용</button></form>
    {visibleSections.map((status) => {
      const list = projects.filter((project) => project.status === status);
      if (params.status && list.length === 0) return <section key={status} className="panel muted">이 상태의 프로젝트가 없습니다.</section>;
      return <section key={status} className="grid gap-3"><h2 className="text-lg font-semibold">{getDisplayLabel(projectStatusLabels, status)} <span className="muted">{list.length}</span></h2><div className="grid gap-3 md:grid-cols-2">{list.map((project) => {
        const projectActions = actions.filter((action) => action.project_id === project.id);
        const projectMilestones = milestones.filter((milestone) => milestone.project_id === project.id);
        const progress = calculateProjectProgress(projectActions, projectMilestones, project.status);
        const nextAction = projectActions.find((action) => action.id === project.next_action_id);
        const currentStage = projectActions.find((action) => action.is_stage && action.status !== "DONE");
        const nearestMilestone = projectMilestones.find((milestone) => !milestone.completed_at);
        const gaps = getProjectPlanningGaps(project, projectActions);
        return <Link key={project.id} href={`/projects/${project.id}`} className="panel block transition hover:border-moss hover:shadow"><div className="flex items-start justify-between gap-3"><h3 className="text-lg font-semibold">{project.title}</h3><span className="status-pill shrink-0">{getDisplayLabel(projectStatusLabels, project.status)}</span></div><p className="muted mt-2 line-clamp-2">{project.goal ?? project.description ?? "프로젝트 목표를 추가해보세요."}</p><div className="mt-4 grid gap-2 text-sm"><div className="flex items-center justify-between gap-3"><span className="font-semibold">진행률</span><span>{progress.percentage}%</span></div><div className="h-2 overflow-hidden rounded-full bg-line"><div className="h-full bg-moss" style={{ width: `${progress.percentage}%` }} /></div>{project.target_date ? <p className="muted">목표일 {project.target_date}</p> : null}{currentStage ? <p><span className="muted">현재 단계 · </span>{currentStage.title}</p> : null}{nextAction ? <p><span className="muted">다음 행동 · </span>{nextAction.title}</p> : null}{nearestMilestone ? <p><span className="muted">가장 가까운 마일스톤 · </span>{nearestMilestone.title}{nearestMilestone.target_date ? ` (${nearestMilestone.target_date})` : ""}</p> : null}</div>{gaps.length > 0 ? <div className="mt-4 flex flex-wrap gap-1">{gaps.map((gap) => <span className="status-pill" key={gap}>{gap}</span>)}</div> : null}</Link>;
      })}</div>{list.length === 0 && !params.status ? <p className="muted">이 상태의 프로젝트가 없습니다.</p> : null}</section>;
    })}
  </div>;
}
