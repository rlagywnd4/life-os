import { notFound } from "next/navigation";
import { ProjectSetupForm } from "@/components/project-setup-form";
import { createClient } from "@/lib/supabase/server";

export default async function NewProjectPage({ searchParams }: { searchParams: Promise<{ inbox?: string }> }) {
  const { inbox: inboxId } = await searchParams;
  const supabase = await createClient();
  const { data: sourceInbox } = inboxId && supabase ? await supabase.from("inbox_items").select("id,title,description,status").eq("id", inboxId).single() : { data: null };
  if (sourceInbox && sourceInbox.status !== "UNREVIEWED") notFound();

  return <div className="grid gap-6"><header><h1 className="text-3xl font-bold">프로젝트 만들기</h1><p className="muted mt-2">목표, 계획, 첫 행동까지 한 흐름에서 정리합니다.</p></header><ProjectSetupForm sourceInbox={sourceInbox ? { id: sourceInbox.id, title: sourceInbox.title, description: sourceInbox.description } : undefined} /></div>;
}
