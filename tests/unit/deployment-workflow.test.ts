import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const workflow = readFileSync(
  join(process.cwd(), ".github/workflows/test-and-deploy.yml"),
  "utf8"
);

describe("production deployment workflow", () => {
  it("requires the Supabase production configuration", () => {
    expect(workflow).toContain("secrets.SUPABASE_ACCESS_TOKEN");
    expect(workflow).toContain("secrets.SUPABASE_DB_PASSWORD");
    expect(workflow).toContain("vars.SUPABASE_PROJECT_ID");
  });

  it("previews and applies database migrations with the official CLI action", () => {
    expect(workflow).toContain("uses: supabase/setup-cli@v2");
    expect(workflow).toContain("supabase db push --dry-run");
    expect(workflow).toContain("supabase db push\n");
  });

  it("builds before applying production database migrations", () => {
    const build = workflow.indexOf("- name: Build");
    const migrate = workflow.indexOf("- name: Apply database migrations");

    expect(build).toBeGreaterThan(-1);
    expect(migrate).toBeGreaterThan(build);
    expect(workflow).not.toContain("secrets.VERCEL_TOKEN");
    expect(workflow).not.toContain("vercel deploy");
  });

  it("repairs only the verified legacy migration history on an explicit manual run", () => {
    const repair = workflow.indexOf(
      "- name: Repair verified legacy migration history"
    );
    const preview = workflow.indexOf("- name: Preview database migrations");

    expect(workflow).toContain("repair_legacy_history:");
    expect(workflow).toContain(
      "github.event_name == 'workflow_dispatch' && inputs.repair_legacy_history"
    );
    expect(workflow).toContain(
      "supabase migration repair --status applied 202607150001 202607150002 --yes"
    );
    expect(workflow).not.toContain(
      "migration repair --status applied 202607150003"
    );
    expect(repair).toBeGreaterThan(-1);
    expect(preview).toBeGreaterThan(repair);
  });
});
