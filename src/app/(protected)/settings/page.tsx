import { LogoutButton } from "@/components/logout-button";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data: profile } = supabase ? await supabase.from("profiles").select("*").single() : { data: null };

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">설정</h1>
        <p className="muted mt-2">개인 사용에 맞게 제한과 기본값을 조정합니다.</p>
      </header>
      <section className="panel grid gap-3">
        <label className="grid gap-1">
          <span className="label">표시 이름</span>
          <input className="field" defaultValue={profile?.display_name ?? ""} readOnly />
        </label>
        <label className="grid gap-1">
          <span className="label">시간대</span>
          <input className="field" defaultValue={profile?.timezone ?? "Asia/Seoul"} readOnly />
        </label>
        <div className="grid gap-3 sm:grid-cols-3">
          <input className="field" value={`활성 프로젝트 ${profile?.max_active_projects ?? 3}`} readOnly />
          <input className="field" value={`핵심 행동 ${profile?.max_core_actions ?? 3}`} readOnly />
          <input className="field" value={`권장 ${profile?.recommended_action_minutes ?? 30}분`} readOnly />
        </div>
      </section>
      <section className="panel grid gap-3">
        <LogoutButton />
        <p className="muted">계정 삭제는 Supabase Auth 사용자 삭제와 RLS cascade를 함께 검증한 뒤 운영 환경에서 활성화합니다.</p>
      </section>
    </div>
  );
}
