"use client";

import Link from "next/link";
import { ChevronDown, ChevronRight } from "lucide-react";
import { useMemo, useState } from "react";
import { ActionButton } from "@/components/action-button";
import { moveActionItem, setNextAction, updateActionCompletion } from "@/features/projects/actions";
import { actionStatusLabels, getDisplayLabel } from "@/lib/display-labels";
import { buildActionTree, type ActionTreeNode } from "@/lib/domain/action-tree";
import type { Database } from "@/types/database";

export type ActionTreeItem = Pick<
  Database["public"]["Tables"]["action_items"]["Row"],
  | "id"
  | "project_id"
  | "parent_action_id"
  | "title"
  | "description"
  | "estimated_minutes"
  | "status"
  | "completed_at"
  | "created_at"
  | "is_stage"
  | "scheduled_date"
  | "scheduled_time"
  | "due_date"
>;

type ActionTreeProps = {
  projectId: string;
  actions: ActionTreeItem[];
  rootParentId?: string | null;
  emptyMessage?: string;
  nextActionId?: string | null;
};

type TreeNodeProps = {
  projectId: string;
  node: ActionTreeNode<ActionTreeItem>;
  collapsedIds: Set<string>;
  onToggle: (id: string) => void;
  nextActionId?: string | null;
};

function TreeNode({ projectId, node, collapsedIds, onToggle, nextActionId }: TreeNodeProps) {
  const { action, children, descendantCount, completedDescendantCount } = node;
  const hasChildren = children.length > 0;
  const collapsed = collapsedIds.has(action.id);
  const percentage =
    descendantCount === 0
      ? 0
      : Math.round((completedDescendantCount / descendantCount) * 100);
  const shouldSuggestCompletion =
    descendantCount > 0 &&
    completedDescendantCount === descendantCount &&
    action.status !== "DONE" &&
    action.status !== "CANCELED";

  return (
    <div className="grid gap-2">
      <article className="rounded-md border border-line bg-white p-3">
        <div className="flex items-start gap-2">
          {hasChildren ? (
            <button
              type="button"
              className="mt-0.5 inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-ink/70 hover:bg-paper focus:outline-none focus:ring-2 focus:ring-sky"
              aria-expanded={!collapsed}
              aria-label={`${action.title} 하위 활동 ${collapsed ? "펼치기" : "접기"}`}
              onClick={() => onToggle(action.id)}
            >
              {collapsed ? (
                <ChevronRight size={18} />
              ) : (
                <ChevronDown size={18} />
              )}
            </button>
          ) : (
            <span className="h-8 w-8 shrink-0" aria-hidden="true" />
          )}

          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div className="min-w-0">
                <Link
                  href={`/projects/${projectId}/actions/${action.id}`}
                  className="font-semibold hover:text-moss hover:underline"
                >
                  {action.title}{action.is_stage ? " (단계)" : ""}
                </Link>
                {action.description ? (
                  <p className="muted mt-1 line-clamp-2">
                    {action.description}
                  </p>
                ) : null}
              </div>
              <div className="flex shrink-0 flex-wrap gap-2">
                <span className="status-pill">
                  {getDisplayLabel(actionStatusLabels, action.status)}
                </span>
                <span className="status-pill">
                  {action.estimated_minutes}분
                </span>
              </div>
            </div>

            {descendantCount > 0 ? (
              <div className="mt-3 grid gap-1.5">
                <div className="flex items-center justify-between gap-3 text-xs font-semibold text-ink/70">
                  <span>
                    하위 활동 {completedDescendantCount}/{descendantCount} 완료
                  </span>
                  <span>{percentage}%</span>
                </div>
                <div
                  className="h-2 overflow-hidden rounded-full bg-line"
                  role="progressbar"
                  aria-label={`${action.title} 하위 활동 진행률`}
                  aria-valuemin={0}
                  aria-valuemax={100}
                  aria-valuenow={percentage}
                >
                  <div
                    className="h-full rounded-full bg-moss transition-[width]"
                    style={{ width: `${percentage}%` }}
                  />
                </div>
              </div>
            ) : null}

            {shouldSuggestCompletion ? (
              <div className="mt-3 flex flex-col gap-2 rounded-md border border-moss/30 bg-moss/10 p-3 sm:flex-row sm:items-center sm:justify-between">
                <p className="text-sm font-semibold">
                  모든 하위 활동을 완료했습니다. 이 활동도 완료할까요?
                </p>
                <form
                  action={updateActionCompletion.bind(
                    null,
                    action.id,
                    projectId,
                    true
                  )}
                >
                  <ActionButton
                    className="btn-secondary"
                    pendingLabel="완료 중"
                  >
                    완료하기
                  </ActionButton>
                </form>
              </div>
            ) : null}
            {!action.is_stage && !hasChildren ? (
              <div className="mt-3 flex flex-wrap gap-2">
                <form action={updateActionCompletion.bind(null, action.id, projectId, action.status !== "DONE")}>
                  <ActionButton className="btn-secondary" pendingLabel="변경 중">
                    {action.status === "DONE" ? "미완료로" : "완료"}
                  </ActionButton>
                </form>
                {action.status !== "DONE" ? (
                  <form action={setNextAction.bind(null, projectId, action.id)}>
                    <ActionButton className={nextActionId === action.id ? "btn-primary" : "btn-secondary"} pendingLabel="지정 중">
                      {nextActionId === action.id ? "현재 다음 행동" : "다음 행동으로"}
                    </ActionButton>
                  </form>
                ) : null}
                {action.scheduled_date ? <span className="status-pill">{action.scheduled_date}{action.scheduled_time ? ` ${action.scheduled_time.slice(0, 5)}` : ""}</span> : null}
              </div>
            ) : null}
            <div className="mt-3 flex flex-wrap gap-2">
              <form action={moveActionItem.bind(null, action.id, projectId, "UP")}><ActionButton className="btn-secondary" pendingLabel="이동 중">위로</ActionButton></form>
              <form action={moveActionItem.bind(null, action.id, projectId, "DOWN")}><ActionButton className="btn-secondary" pendingLabel="이동 중">아래로</ActionButton></form>
            </div>
          </div>
        </div>
      </article>

      {hasChildren && !collapsed ? (
        <div className="ml-5 grid gap-2 border-l border-line pl-3">
          {children.map((child) => (
            <TreeNode
              key={child.action.id}
              projectId={projectId}
              node={child}
              collapsedIds={collapsedIds}
              onToggle={onToggle}
              nextActionId={nextActionId}
            />
          ))}
        </div>
      ) : null}
    </div>
  );
}

export function ActionTree({
  projectId,
  actions,
  rootParentId = null,
  emptyMessage = "등록된 활동이 없습니다.",
  nextActionId = null
}: ActionTreeProps) {
  const [collapsedIds, setCollapsedIds] = useState<Set<string>>(
    () => new Set()
  );
  const [showCompleted, setShowCompleted] = useState(true);
  const visibleActions = useMemo(() => {
    if (showCompleted) return actions;
    const byId = new Map(actions.map((action) => [action.id, action]));
    const ids = new Set(actions.filter((action) => action.status !== "DONE").map((action) => action.id));
    for (const action of actions) {
      if (action.status === "DONE") continue;
      let parentId = action.parent_action_id;
      while (parentId) {
        ids.add(parentId);
        parentId = byId.get(parentId)?.parent_action_id ?? null;
      }
    }
    return actions.filter((action) => ids.has(action.id));
  }, [actions, showCompleted]);
  const nodes = useMemo(
    () => buildActionTree(visibleActions, rootParentId),
    [visibleActions, rootParentId]
  );

  function toggle(id: string) {
    setCollapsedIds((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  const allIds = actions.map((action) => action.id);

  if (nodes.length === 0) return <p className="muted">{emptyMessage}</p>;

  return (
    <div className="grid gap-2 overflow-x-auto">
      <div className="flex flex-wrap gap-2"><button type="button" className="btn-secondary" onClick={() => setCollapsedIds(new Set(allIds))}>모두 접기</button><button type="button" className="btn-secondary" onClick={() => setCollapsedIds(new Set())}>모두 펼치기</button><button type="button" className="btn-secondary" onClick={() => setShowCompleted((current) => !current)}>{showCompleted ? "완료 활동 숨기기" : "완료 활동 보기"}</button></div>
      {nodes.map((node) => (
        <TreeNode
          key={node.action.id}
          projectId={projectId}
          node={node}
          collapsedIds={collapsedIds}
          onToggle={toggle}
          nextActionId={nextActionId}
        />
      ))}
    </div>
  );
}
