export type ActionTreeRecord = {
  id: string;
  parent_action_id: string | null;
  status: string;
};

export type ActionTreeNode<T extends ActionTreeRecord> = {
  action: T;
  children: ActionTreeNode<T>[];
  descendantCount: number;
  completedDescendantCount: number;
};

export type ActionDescendantProgress = {
  total: number;
  completed: number;
  percentage: number;
  allCompleted: boolean;
};

export function buildActionTree<T extends ActionTreeRecord>(
  actions: T[],
  rootParentId: string | null = null
): ActionTreeNode<T>[] {
  const childrenByParent = new Map<string | null, T[]>();

  for (const action of actions) {
    const siblings = childrenByParent.get(action.parent_action_id) ?? [];
    siblings.push(action);
    childrenByParent.set(action.parent_action_id, siblings);
  }

  const buildNode = (action: T, ancestors: Set<string>): ActionTreeNode<T> => {
    if (ancestors.has(action.id)) {
      return {
        action,
        children: [],
        descendantCount: 0,
        completedDescendantCount: 0
      };
    }

    const nextAncestors = new Set(ancestors);
    nextAncestors.add(action.id);
    const children = (childrenByParent.get(action.id) ?? []).map((child) =>
      buildNode(child, nextAncestors)
    );
    const descendantCount = children.reduce(
      (total, child) => total + 1 + child.descendantCount,
      0
    );
    const completedDescendantCount = children.reduce(
      (total, child) =>
        total +
        (child.action.status === "DONE" ? 1 : 0) +
        child.completedDescendantCount,
      0
    );

    return {
      action,
      children,
      descendantCount,
      completedDescendantCount
    };
  };

  return (childrenByParent.get(rootParentId) ?? []).map((action) =>
    buildNode(action, new Set())
  );
}

export function getActionPath<T extends ActionTreeRecord>(
  actions: T[],
  actionId: string
): T[] {
  const actionById = new Map(actions.map((action) => [action.id, action]));
  const path: T[] = [];
  const visited = new Set<string>();
  let current = actionById.get(actionId);

  while (current && !visited.has(current.id)) {
    path.push(current);
    visited.add(current.id);
    current = current.parent_action_id
      ? actionById.get(current.parent_action_id)
      : undefined;
  }

  return path.reverse();
}

export function getActionDescendantIds<T extends ActionTreeRecord>(
  actions: T[],
  actionId: string
): string[] {
  const childrenByParent = new Map<string, T[]>();
  for (const action of actions) {
    if (!action.parent_action_id) continue;
    const children = childrenByParent.get(action.parent_action_id) ?? [];
    children.push(action);
    childrenByParent.set(action.parent_action_id, children);
  }

  const descendants: string[] = [];
  const visited = new Set([actionId]);
  const pending = [...(childrenByParent.get(actionId) ?? [])];

  while (pending.length > 0) {
    const action = pending.shift();
    if (!action || visited.has(action.id)) continue;
    visited.add(action.id);
    descendants.push(action.id);
    pending.push(...(childrenByParent.get(action.id) ?? []));
  }

  return descendants;
}

export function getActionDescendantProgress<T extends ActionTreeRecord>(
  actions: T[],
  actionId: string
): ActionDescendantProgress {
  const descendantIds = new Set(getActionDescendantIds(actions, actionId));
  const completed = actions.filter(
    (action) => descendantIds.has(action.id) && action.status === "DONE"
  ).length;
  const total = descendantIds.size;

  return {
    total,
    completed,
    percentage: total === 0 ? 0 : Math.round((completed / total) * 100),
    allCompleted: total > 0 && completed === total
  };
}
