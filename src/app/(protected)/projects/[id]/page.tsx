import { notFound } from "next/navigation";
import { ActionButton } from "@/components/action-button";
import { ActionTree } from "@/components/action-tree";
import {
  createActionItem,
  updateProjectStatus
} from "@/features/projects/actions";
import { getDisplayLabel, projectStatusLabels } from "@/lib/display-labels";
import { createClient } from "@/lib/supabase/server";

export default async function ProjectDetailPage({
  params
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: project } = supabase
    ? await supabase.from("projects").select("*").eq("id", id).single()
    : { data: null };
  if (!project) notFound();
  const { data: actionRows } = supabase
    ? await supabase
        .from("action_items")
        .select("*")
        .eq("project_id", id)
        .order("created_at")
    : { data: [] };
  const actions = actionRows ?? [];

  return (
    <div className="grid gap-6">
      <header className="panel">
        <div className="mb-3 flex flex-wrap gap-2">
          <span className="status-pill">
            {getDisplayLabel(projectStatusLabels, project.status)}
          </span>
        </div>
        <h1 className="text-3xl font-bold">{project.title}</h1>
        <p className="muted mt-3">{project.reason}</p>
        <p className="mt-3 text-sm text-ink/80">{project.desired_outcome}</p>
        <form className="mt-4 flex flex-wrap gap-2">
          {["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"].map(
            (status) => (
              <ActionButton
                key={status}
                className="btn-secondary"
                formAction={updateProjectStatus.bind(null, project.id, status)}
                pendingLabel="변경 중"
              >
                {getDisplayLabel(projectStatusLabels, status)}
              </ActionButton>
            )
          )}
        </form>
      </header>

      {["ACTIVE", "WAITING", "PAUSED"].includes(project.status) ? (
        <section className="panel">
          <h2 className="mb-1 text-lg font-semibold">최상위 활동 추가</h2>
          <p className="muted mb-3">
            하위 활동은 각 활동의 상세 화면에서 추가할 수 있습니다.
          </p>
          <form action={createActionItem} className="grid gap-3">
            <input type="hidden" name="projectId" value={project.id} />
            <input type="hidden" name="parentActionId" value="" />
            <input
              className="field"
              name="title"
              placeholder="새 활동 제목"
              maxLength={160}
              required
            />
            <textarea
              className="field min-h-20"
              name="description"
              placeholder="활동 내용"
              maxLength={1000}
            />
            <input
              className="field"
              name="estimatedMinutes"
              type="number"
              min="1"
              max="480"
              defaultValue="30"
              aria-label="예상 분"
            />
            <ActionButton className="btn-primary" pendingLabel="저장 중">
              활동 저장
            </ActionButton>
          </form>
        </section>
      ) : null}

      <section className="panel grid gap-3">
        <div>
          <h2 className="text-lg font-semibold">활동 목록</h2>
          <p className="muted mt-1">
            화살표로 하위 활동을 접거나 펼칠 수 있습니다.
          </p>
        </div>
        <ActionTree projectId={project.id} actions={actions} />
      </section>
    </div>
  );
}
