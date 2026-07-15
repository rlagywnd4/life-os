import { createClient } from "@/lib/supabase/server";

export default async function SomedayPage() {
  const supabase = await createClient();
  const { data } = supabase
    ? await supabase.from("someday_items").select("*").order("created_at", { ascending: false })
    : { data: [] };
  const items = data ?? [];

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">Someday</h1>
        <p className="muted mt-2">지금 시작하지 않아도 되는 생각을 보관합니다.</p>
      </header>
      <section className="grid gap-3">
        {items.map((item) => (
          <article key={item.id} className="panel">
            <span className="status-pill">{item.category}</span>
            <h2 className="mt-2 font-semibold">{item.title}</h2>
            <p className="muted mt-1">{item.description}</p>
          </article>
        ))}
        {items.length === 0 ? <p className="panel muted">Someday에 보류된 항목이 없습니다.</p> : null}
      </section>
    </div>
  );
}
