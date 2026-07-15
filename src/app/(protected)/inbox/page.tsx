import { Archive, FolderPlus, Trash2 } from "lucide-react";
import { convertInboxToProject, updateInboxStatus } from "@/features/inbox/actions";
import { QuickInboxForm } from "@/components/quick-inbox-form";
import { createClient } from "@/lib/supabase/server";
import { getDisplayLabel, inboxCategoryLabels, inboxStatusLabels } from "@/lib/display-labels";

const categories = ["SERVICE_IDEA", "STUDY", "CAREER", "EXERCISE", "CONTENT", "HOBBY", "LIFE", "TRAVEL", "PURCHASE", "ETC"];

export default async function InboxPage({ searchParams }: { searchParams: Promise<{ q?: string; category?: string }> }) {
  const params = await searchParams;
  const supabase = await createClient();
  let query = supabase?.from("inbox_items").select("*").order("created_at", { ascending: false });
  if (params.q) query = query?.ilike("title", `%${params.q}%`);
  if (params.category) query = query?.eq("category", params.category);
  const { data } = query ? await query : { data: [] };
  const items = data ?? [];

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold text-ink">Inbox</h1>
        <p className="muted mt-2">생각은 먼저 모아두고, 주간 리뷰에서 실행 여부를 고릅니다.</p>
      </header>
      <section className="panel grid gap-3">
        <QuickInboxForm />
        <form className="grid gap-2 sm:grid-cols-[1fr_180px_auto]">
          <input className="field" name="q" placeholder="검색" defaultValue={params.q} />
          <select className="field" name="category" defaultValue={params.category ?? ""}>
            <option value="">전체 카테고리</option>
            {categories.map((category) => <option key={category} value={category}>{getDisplayLabel(inboxCategoryLabels, category)}</option>)}
          </select>
          <button className="btn-secondary">필터</button>
        </form>
      </section>
      <section className="grid gap-3">
        {items.map((item) => (
          <article key={item.id} className="panel grid gap-4">
            <div>
              <div className="mb-2 flex flex-wrap gap-2">
                <span className="status-pill">{getDisplayLabel(inboxCategoryLabels, item.category)}</span>
                <span className="status-pill">{getDisplayLabel(inboxStatusLabels, item.status)}</span>
              </div>
              <h2 className="text-lg font-semibold">{item.title}</h2>
              {item.description ? <p className="muted mt-1">{item.description}</p> : null}
            </div>
            {item.status === "UNREVIEWED" ? (
              <form action={convertInboxToProject} className="grid gap-3 border-t border-line pt-4">
                <input type="hidden" name="inboxId" value={item.id} />
                <label className="grid gap-1">
                  <span className="label">무엇을 하려는가?</span>
                  <input className="field" name="title" defaultValue={item.title} required />
                </label>
                <label className="grid gap-1">
                  <span className="label">왜 하고 싶은가?</span>
                  <textarea className="field min-h-20" name="reason" />
                </label>
                <label className="grid gap-1">
                  <span className="label">어떤 상태가 되면 충분히 해봤다고 느낄 것인가?</span>
                  <textarea className="field min-h-20" name="desiredOutcome" />
                </label>
                <label className="flex items-center gap-2 text-sm font-semibold">
                  <input type="checkbox" name="activateNow" /> 지금 활성 프로젝트로 시작
                </label>
                <div className="flex flex-wrap gap-2">
                  <button className="btn-primary"><FolderPlus size={18} /> 프로젝트 전환</button>
                  <button className="btn-secondary" formAction={updateInboxStatus.bind(null, item.id, "SOMEDAY")}><Archive size={18} /> Someday</button>
                  <button className="btn-secondary" formAction={updateInboxStatus.bind(null, item.id, "DISCARDED")}><Trash2 size={18} /> 폐기</button>
                </div>
              </form>
            ) : null}
          </article>
        ))}
        {items.length === 0 ? <p className="panel muted">아직 Inbox 항목이 없습니다. 떠오른 생각 하나를 기록해보세요.</p> : null}
      </section>
    </div>
  );
}
