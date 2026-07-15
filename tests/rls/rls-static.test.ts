import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const migrationDir = join(process.cwd(), "supabase/migrations");
const sql = readdirSync(migrationDir)
  .filter((file) => file.endsWith(".sql"))
  .sort()
  .map((file) => readFileSync(join(migrationDir, file), "utf8"))
  .join("\n");

const userOwnedTables = [
  "inbox_items",
  "projects",
  "action_items",
  "daily_plans",
  "daily_plan_actions",
  "someday_items",
  "weekly_reviews",
  "weekly_review_focus_projects",
  "daily_check_ins",
  "health_profiles",
  "health_weight_goals",
  "health_check_ins",
  "life_context_documents",
  "life_context_entries"
];

describe("RLS migration", () => {
  it("enables row level security for all user-owned tables", () => {
    for (const table of userOwnedTables) {
      expect(sql).toContain(`alter table public.${table} enable row level security`);
    }
  });

  it("uses auth.uid ownership checks for CRUD policies", () => {
    for (const table of userOwnedTables) {
      const pattern = new RegExp(`on public\\.${table}[\\s\\S]+auth\\.uid\\(\\)`, "m");
      expect(sql).toMatch(pattern);
    }
  });

  it("contains atomic RPC functions for conversion and daily planning", () => {
    expect(sql).toContain("create or replace function public.convert_inbox_to_project");
    expect(sql).toContain("for update");
    expect(sql).toContain("ACTIVE_PROJECT_LIMIT_EXCEEDED");
    expect(sql).toContain("create or replace function public.add_core_action_to_today");
    expect(sql).toContain("CORE_ACTION_LIMIT_EXCEEDED");
  });
});
