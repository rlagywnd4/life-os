import { describe, expect, it } from "vitest";
import {
  buildActionTree,
  getActionDescendantIds,
  getActionDescendantProgress,
  getActionPath,
  type ActionTreeRecord
} from "@/lib/domain/action-tree";
import { actionSchema, actionUpdateSchema } from "@/lib/validation/schemas";

type TestAction = ActionTreeRecord & { title: string };

const actions: TestAction[] = [
  { id: "root", parent_action_id: null, status: "TODO", title: "루트" },
  { id: "child-a", parent_action_id: "root", status: "DONE", title: "자식 A" },
  { id: "child-b", parent_action_id: "root", status: "TODO", title: "자식 B" },
  {
    id: "grandchild",
    parent_action_id: "child-b",
    status: "DONE",
    title: "손자"
  }
];

describe("action hierarchy", () => {
  it("builds an arbitrarily nested tree and aggregates descendant progress", () => {
    const tree = buildActionTree(actions);

    expect(tree).toHaveLength(1);
    expect(tree[0].action.id).toBe("root");
    expect(tree[0].children.map((node) => node.action.id)).toEqual([
      "child-a",
      "child-b"
    ]);
    expect(tree[0]).toMatchObject({
      descendantCount: 3,
      completedDescendantCount: 2
    });
    expect(tree[0].children[1]).toMatchObject({
      descendantCount: 1,
      completedDescendantCount: 1
    });
  });

  it("returns the breadcrumb path through the current action", () => {
    expect(
      getActionPath(actions, "grandchild").map((action) => action.id)
    ).toEqual(["root", "child-b", "grandchild"]);
  });

  it("finds every descendant and counts DONE only as completed", () => {
    expect(getActionDescendantIds(actions, "root")).toEqual([
      "child-a",
      "child-b",
      "grandchild"
    ]);
    expect(getActionDescendantProgress(actions, "root")).toEqual({
      total: 3,
      completed: 2,
      percentage: 67,
      allCompleted: false
    });
    expect(getActionDescendantProgress(actions, "child-b")).toEqual({
      total: 1,
      completed: 1,
      percentage: 100,
      allCompleted: true
    });
  });

  it("accepts an optional parent on create and update forms", () => {
    const projectId = crypto.randomUUID();
    const parentActionId = crypto.randomUUID();
    const base = {
      projectId,
      parentActionId,
      title: "하위 활동",
      description: "내용",
      estimatedMinutes: 15
    };

    expect(actionSchema.safeParse(base).success).toBe(true);
    expect(
      actionSchema.safeParse({ ...base, parentActionId: "" }).success
    ).toBe(true);
    expect(
      actionUpdateSchema.safeParse({ ...base, actionId: crypto.randomUUID() })
        .success
    ).toBe(true);
  });
});
