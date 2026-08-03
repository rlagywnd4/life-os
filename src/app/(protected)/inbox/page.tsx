import Link from "next/link";
import { Archive, CalendarPlus, FolderPlus, Pencil, Trash2 } from "lucide-react";
import { ActionButton } from "@/components/action-button";
import { QuickInboxForm } from "@/components/quick-inbox-form";
import { createInboxCalendarEvent, deleteInboxItem, updateInboxItem, updateInboxStatus } from "@/features/inbox/actions";
import { createClient } from "@/lib/supabase/server";
import { getDisplayLabel, inboxCategoryLabels } from "@/lib/display-labels";

const categories = ["SERVICE_IDEA", "STUDY", "CAREER", "EXERCISE", "CONTENT", "HOBBY", "LIFE", "TRAVEL", "PURCHASE", "ETC"];

export default async function InboxPage({ searchParams }: { searchParams: Promise<{ q?: string; category?: string }> }) {
  const params = await searchParams;
  const supabase = await createClient();
  let query = supabase?.from("inbox_items").select("*").eq("status", "UNREVIEWED").order("created_at", { ascending: false });
  if (params.q) query = query?.or(`title.ilike.%${params.q}%,description.ilike.%${params.q}%`);
  if (params.category) query = query?.eq("category", params.category);
  const { data } = query ? await query : { data: [] };
  const items = data ?? [];

  return (
    <div className="grid gap-6">
      <header className="grid gap-3 sm:flex sm:items-end sm:justify-between">
        <div><h1 className="text-3xl font-bold text-ink">Inbox</h1><p className="muted mt-2">아직 정리되지 않은 생각과 할 일</p></div>
        <span className="status-pill w-fit">미처리 {items.length}개</span>
      </header>
      <section className="panel grid gap-3"><QuickInboxForm /><p className="muted">떠오른 생각을 먼저 기록하고, 지금은 처리 방법만 고릅니다.</p></section>
      <form className="grid gap-2 sm:grid-cols-[1fr_180px_auto]"><input className="field" name="q" placeholder="제목 또는 메모 검색" defaultValue={params.q} aria-label="Inbox 검색" /><select className="field" name="category" defaultValue={params.category ?? ""} aria-label="Inbox 카테고리"><option value="">전체 카테고리</option>{categories.map((category) => <option key={category} value={category}>{getDisplayLabel(inboxCategoryLabels, category)}</option>)}</select><button className="btn-secondary">필터</button></form>
      <section className="grid gap-3">
        {items.map((item) => (
          <article key={item.id} className="panel grid gap-4">
            <div className="min-w-0"><div className="mb-2 flex flex-wrap gap-2"><span className="status-pill">{getDisplayLabel(inboxCategoryLabels, item.category)}</span><span className="muted self-center">{new Intl.DateTimeFormat("ko-KR", { dateStyle: "medium", timeStyle: "short" }).format(new Date(item.created_at))}</span></div><h2 className="text-lg font-semibold">{item.title}</h2>{item.description ? <p className="muted mt-1 whitespace-pre-wrap">{item.description}</p> : null}</div>
            <div className="flex flex-wrap gap-2 border-t border-line pt-3"><Link href={`/projects/new?inbox=${item.id}`} className="btn-primary"><FolderPlus size={18} /> 프로젝트로 만들기</Link><form action={updateInboxStatus.bind(null, item.id, "SOMEDAY")}><ActionButton className="btn-secondary" pendingLabel="보관 중"><Archive size={18} /> 나중에 보기</ActionButton></form><form action={updateInboxStatus.bind(null, item.id, "ARCHIVED")}><ActionButton className="btn-secondary" pendingLabel="보관 중"><Archive size={18} /> 보관</ActionButton></form><form action={deleteInboxItem.bind(null, item.id)}><ActionButton className="btn-secondary" pendingLabel="삭제 중"><Trash2 size={18} /> 삭제</ActionButton></form></div>
            <details className="rounded-md border border-line p-3"><summary className="cursor-pointer text-sm font-semibold"><span className="inline-flex items-center gap-2"><Pencil size={16} /> 수정 또는 일정으로 분류</span></summary><div className="mt-4 grid gap-4"><form action={updateInboxItem} className="grid gap-3"><input type="hidden" name="id" value={item.id} /><label className="grid gap-1"><span className="label">제목</span><input className="field" name="title" defaultValue={item.title} required maxLength={160} /></label><label className="grid gap-1"><span className="label">메모</span><textarea className="field min-h-24" name="description" defaultValue={item.description ?? ""} maxLength={2000} /></label><label className="grid gap-1"><span className="label">카테고리</span><select className="field" name="category" defaultValue={item.category}>{categories.map((category) => <option key={category} value={category}>{getDisplayLabel(inboxCategoryLabels, category)}</option>)}</select></label><ActionButton className="btn-primary w-fit" pendingLabel="저장 중">변경 저장</ActionButton></form><form action={createInboxCalendarEvent} className="grid gap-2 border-t border-line pt-4 sm:grid-cols-[1fr_auto]"><input type="hidden" name="id" value={item.id} /><label className="grid gap-1"><span className="label">일정으로 만들 날짜</span><input className="field" name="eventDate" type="date" required /></label><ActionButton className="btn-secondary self-end" pendingLabel="만드는 중"><CalendarPlus size={18} /> 일정으로 만들기</ActionButton></form></div></details>
          </article>
        ))}
        {items.length === 0 ? <div className="panel grid gap-2 text-center"><p className="font-semibold">현재 정리되지 않은 항목이 없습니다.</p><p className="muted">새 생각이나 할 일을 빠르게 추가해보세요.</p></div> : null}
      </section>
    </div>
  );
}
