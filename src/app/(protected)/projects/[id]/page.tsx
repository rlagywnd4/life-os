import { notFound } from "next/navigation";
import { ActionButton } from "@/components/action-button";
import { createClient } from "@/lib/supabase/server";
import { createActionItem, updateProjectStatus } from "@/features/projects/actions";
import { getActionSizeWarning, getActionSpecificityWarning } from "@/lib/domain/rules";
import { getDisplayLabel, projectStatusLabels } from "@/lib/display-labels";

export default async function ProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: project } = supabase
    ? await supabase.from("projects").select("*").eq("id", id).single()
    : { data: null };
  if (!project) notFound();
  const { data: actionRows } = supabase
    ? await supabase.from("action_items").select("*").eq("project_id", id).order("created_at")
    : { data: [] };
  const actions = actionRows ?? [];

  const openActions = actions.filter((action) => action.status !== "DONE");
  const doneActions = actions.filter((action) => action.status === "DONE");

  return (
    <div className="grid gap-6">
      <header className="panel">
        <div className="mb-3 flex flex-wrap gap-2">
          <span className="status-pill">{getDisplayLabel(projectStatusLabels, project.status)}</span>
        </div>
        <h1 className="text-3xl font-bold">{project.title}</h1>
        <p className="muted mt-3">{project.reason}</p>
        <p className="mt-3 text-sm text-ink/80">{project.desired_outcome}</p>
        <form className="mt-4 flex flex-wrap gap-2">
          {["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"].map((status) => (
            <ActionButton key={status} className="btn-secondary" formAction={updateProjectStatus.bind(null, project.id, status)} pendingLabel="변경 중">
              {getDisplayLabel(projectStatusLabels, status)}
            </ActionButton>
          ))}
        </form>
      </header>

      {["ACTIVE", "WAITING", "PAUSED"].includes(project.status) ? (
        <section className="panel">
          <h2 className="mb-3 text-lg font-semibold">행동 추가</h2>
          <form action={createActionItem} className="grid gap-3">
            <input type="hidden" name="projectId" value={project.id} />
            <input className="field" name="title" placeholder="30분 안에 시작하고 끝낼 수 있는 행동" required />
            <textarea className="field min-h-20" name="description" placeholder="메모" />
            <input className="field" name="estimatedMinutes" type="number" min="1" defaultValue="30" aria-label="예상 분" />
            <ActionButton className="btn-primary" pendingLabel="저장 중">행동 저장</ActionButton>
          </form>
        </section>
      ) : null}

      <section className="grid gap-3 lg:grid-cols-2">
        <div className="panel">
          <h2 className="mb-3 text-lg font-semibold">미완료 행동</h2>
          <div className="grid gap-2">
            {openActions.map((action) => (
              <div key={action.id} className="rounded-md border border-line p-3">
                <p className="font-semibold">{action.title}</p>
                {getActionSpecificityWarning(action.title) ? <p className="mt-1 text-sm text-amber">{getActionSpecificityWarning(action.title)}</p> : null}
                {getActionSizeWarning(action.estimated_minutes) ? <p className="mt-1 text-sm text-amber">{getActionSizeWarning(action.estimated_minutes)}</p> : null}
              </div>
            ))}
          </div>
        </div>
        <div className="panel">
          <h2 className="mb-3 text-lg font-semibold">완료 행동</h2>
          <div className="grid gap-2">
            {doneActions.map((action) => <p key={action.id} className="rounded-md border border-line p-3">{action.title}</p>)}
            {doneActions.length === 0 ? <p className="muted">완료하지 않았더라도 시도한 내용을 기록할 수 있습니다.</p> : null}
          </div>
        </div>
      </section>
    </div>
  );
}
