import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { notFound } from "next/navigation";
import { ActionButton } from "@/components/action-button";
import { ActionTree } from "@/components/action-tree";
import {
  createActionItem,
  deleteActionItem,
  setNextAction,
  updateActionCompletion,
  updateActionItem
} from "@/features/projects/actions";
import { actionStatusLabels, getDisplayLabel } from "@/lib/display-labels";
import {
  getActionDescendantIds,
  getActionDescendantProgress,
  getActionPath
} from "@/lib/domain/action-tree";
import { createClient } from "@/lib/supabase/server";

export default async function ActionDetailPage({
  params
}: {
  params: Promise<{ id: string; actionId: string }>;
}) {
  const { id: projectId, actionId } = await params;
  const supabase = await createClient();
  const [{ data: project }, { data: action }, { data: actionRows }] = supabase
    ? await Promise.all([
        supabase.from("projects").select("*").eq("id", projectId).single(),
        supabase
          .from("action_items")
          .select("*")
          .eq("id", actionId)
          .eq("project_id", projectId)
          .single(),
        supabase
          .from("action_items")
          .select("*")
          .eq("project_id", projectId)
          .order("created_at")
      ])
    : [{ data: null }, { data: null }, { data: [] }];

  if (!project || !action) notFound();

  const actions = actionRows ?? [];
  const path = getActionPath(actions, action.id);
  const progress = getActionDescendantProgress(actions, action.id);
  const unavailableParentIds = new Set([
    action.id,
    ...getActionDescendantIds(actions, action.id)
  ]);
  const parentCandidates = actions.filter(
    (candidate) => !unavailableParentIds.has(candidate.id)
  );
  const canAddChildren = ["ACTIVE", "WAITING", "PAUSED"].includes(
    project.status
  );
  const shouldSuggestCompletion =
    progress.allCompleted &&
    action.status !== "DONE" &&
    action.status !== "CANCELED";

  return (
    <div className="grid gap-6">
      <nav
        aria-label="활동 경로"
        className="flex flex-wrap items-center gap-1 text-sm text-ink/70"
      >
        <Link
          href={`/projects/${project.id}`}
          className="font-semibold hover:text-moss hover:underline"
        >
          {project.title}
        </Link>
        {path.map((pathAction, index) => {
          const current = index === path.length - 1;
          return (
            <span
              key={pathAction.id}
              className="inline-flex items-center gap-1"
            >
              <ChevronRight size={15} aria-hidden="true" />
              {current ? (
                <span className="font-semibold text-ink" aria-current="page">
                  {pathAction.title}
                </span>
              ) : (
                <Link
                  href={`/projects/${project.id}/actions/${pathAction.id}`}
                  className="hover:text-moss hover:underline"
                >
                  {pathAction.title}
                </Link>
              )}
            </span>
          );
        })}
      </nav>

      <header className="panel grid gap-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <span className="status-pill">
              {getDisplayLabel(actionStatusLabels, action.status)}
            </span>
            <h1 className="mt-3 text-3xl font-bold">{action.title}</h1>
            {action.description ? (
              <p className="mt-3 whitespace-pre-wrap text-ink/80">
                {action.description}
              </p>
            ) : null}
          </div>
          <form
            action={updateActionCompletion.bind(
              null,
              action.id,
              project.id,
              action.status !== "DONE"
            )}
          >
            <ActionButton className="btn-secondary" pendingLabel="변경 중">
              {action.status === "DONE" ? "미완료로 되돌리기" : "활동 완료"}
            </ActionButton>
          </form>
        </div>

        {progress.total > 0 ? (
          <div className="grid gap-1.5 rounded-md border border-line bg-paper p-3">
            <div className="flex items-center justify-between gap-3 text-sm font-semibold">
              <span>
                하위 활동 {progress.completed}/{progress.total} 완료
              </span>
              <span>{progress.percentage}%</span>
            </div>
            <div
              className="h-2 overflow-hidden rounded-full bg-line"
              role="progressbar"
              aria-label={`${action.title} 하위 활동 진행률`}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={progress.percentage}
            >
              <div
                className="h-full rounded-full bg-moss"
                style={{ width: `${progress.percentage}%` }}
              />
            </div>
          </div>
        ) : null}

        {shouldSuggestCompletion ? (
          <div className="flex flex-col gap-2 rounded-md border border-moss/30 bg-moss/10 p-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="font-semibold">모든 하위 활동을 완료했습니다.</p>
              <p className="muted mt-1">
                부모 활동은 자동으로 완료되지 않습니다. 직접 완료할까요?
              </p>
            </div>
            <form
              action={updateActionCompletion.bind(
                null,
                action.id,
                project.id,
                true
              )}
            >
              <ActionButton className="btn-primary" pendingLabel="완료 중">
                완료하기
              </ActionButton>
            </form>
          </div>
        ) : null}
      </header>

      <section className="panel">
        <h2 className="mb-3 text-lg font-semibold">활동 수정</h2>
        <form
          key={action.updated_at}
          action={updateActionItem}
          className="grid gap-3"
        >
          <input type="hidden" name="actionId" value={action.id} />
          <input type="hidden" name="projectId" value={project.id} />
          <label className="grid gap-1">
            <span className="label">제목</span>
            <input
              className="field"
              name="title"
              defaultValue={action.title}
              maxLength={160}
              required
            />
          </label>
          <label className="grid gap-1">
            <span className="label">내용</span>
            <textarea
              className="field min-h-28"
              name="description"
              defaultValue={action.description ?? ""}
              maxLength={1000}
            />
          </label>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="grid gap-1">
              <span className="label">부모 활동</span>
              <select
                className="field"
                name="parentActionId"
                defaultValue={action.parent_action_id ?? ""}
              >
                <option value="">최상위 활동</option>
                {parentCandidates.map((candidate) => (
                  <option key={candidate.id} value={candidate.id}>
                    {getActionPath(actions, candidate.id)
                      .map((item) => item.title)
                      .join(" › ")}
                  </option>
                ))}
              </select>
            </label>
            <label className="grid gap-1">
              <span className="label">예상 시간(분)</span>
              <input
                className="field"
                name="estimatedMinutes"
                type="number"
                min="1"
                max="480"
                defaultValue={action.estimated_minutes}
              />
            </label>
            <label className="grid gap-1">
              <span className="label">상태</span>
              <select className="field" name="status" defaultValue={action.status}>
                {[["TODO", "할 일"], ["PLANNED", "계획됨"], ["IN_PROGRESS", "진행 중"], ["WAITING", "대기"], ["DONE", "완료"], ["SKIPPED", "건너뜀"], ["CANCELED", "취소"]].map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
          </div>
          <div className="grid gap-3 rounded-md border border-line bg-paper p-3 sm:grid-cols-2">
            <label className="grid gap-1"><span className="label">시작일</span><input className="field" name="startedDate" type="date" defaultValue={action.started_date ?? ""} /></label>
            <label className="grid gap-1"><span className="label">예정 날짜</span><input className="field" name="scheduledDate" type="date" defaultValue={action.scheduled_date ?? ""} /></label>
            <label className="grid gap-1"><span className="label">마감일</span><input className="field" name="dueDate" type="date" defaultValue={action.due_date ?? ""} /></label>
            <label className="grid gap-1"><span className="label">시작 시간</span><input className="field" name="scheduledTime" type="time" defaultValue={action.scheduled_time?.slice(0, 5) ?? ""} /></label>
            <label className="grid gap-1"><span className="label">종료 시간</span><input className="field" name="scheduledEndTime" type="time" defaultValue={action.scheduled_end_time?.slice(0, 5) ?? ""} /></label>
            <label className="grid gap-1"><span className="label">실제 소요 시간(분)</span><input className="field" name="actualMinutes" type="number" min="0" max="1440" defaultValue={action.actual_minutes ?? ""} /></label>
            <label className="flex items-center gap-2 text-sm font-semibold sm:col-span-2"><input name="isAllDay" type="checkbox" defaultChecked={action.is_all_day} /> 종일 일정</label>
          </div>
          <ActionButton className="btn-primary" pendingLabel="저장 중">
            변경 저장
          </ActionButton>
        </form>
      </section>

      <section className="panel grid gap-3">
        <h2 className="text-lg font-semibold">다음 행동과 삭제</h2>
        <div className="flex flex-wrap gap-2"><form action={setNextAction.bind(null, project.id, action.id)}><ActionButton className="btn-secondary" pendingLabel="지정 중">다음 행동으로 지정</ActionButton></form><form action={deleteActionItem.bind(null, action.id, project.id, "REPARENT")}><ActionButton className="btn-secondary" pendingLabel="삭제 중">하위 활동을 상위로 옮기고 삭제</ActionButton></form>{progress.total > 0 ? <form action={deleteActionItem.bind(null, action.id, project.id, "CASCADE")}><ActionButton className="btn-secondary" pendingLabel="삭제 중">하위 활동도 함께 삭제</ActionButton></form> : null}</div>
        <p className="muted">삭제는 되돌릴 수 없습니다. 하위 활동이 있으면 두 가지 처리 방식을 선택할 수 있습니다.</p>
      </section>

      {canAddChildren ? (
        <section className="panel">
          <h2 className="mb-1 text-lg font-semibold">하위 활동 추가</h2>
          <p className="muted mb-3">
            이 활동을 더 작고 실행 가능한 단계로 나눕니다.
          </p>
          <form action={createActionItem} className="grid gap-3">
            <input type="hidden" name="projectId" value={project.id} />
            <input type="hidden" name="parentActionId" value={action.id} />
            <input
              className="field"
              name="title"
              placeholder="새 하위 활동 제목"
              maxLength={160}
              required
            />
            <input type="hidden" name="status" value="TODO" />
            <input type="hidden" name="dueDate" value="" />
            <input type="hidden" name="startedDate" value="" />
            <input type="hidden" name="scheduledDate" value="" />
            <input type="hidden" name="scheduledTime" value="" />
            <input type="hidden" name="scheduledEndTime" value="" />
            <input type="hidden" name="isAllDay" value="on" />
            <input type="hidden" name="actualMinutes" value="" />
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
              하위 활동 저장
            </ActionButton>
          </form>
        </section>
      ) : null}

      <section className="panel grid gap-3">
        <div>
          <h2 className="text-lg font-semibold">하위 활동</h2>
          <p className="muted mt-1">현재 활동 아래의 전체 구조입니다.</p>
        </div>
        <ActionTree
          projectId={project.id}
          actions={actions}
          rootParentId={action.id}
          emptyMessage="아직 하위 활동이 없습니다."
        />
      </section>
    </div>
  );
}
