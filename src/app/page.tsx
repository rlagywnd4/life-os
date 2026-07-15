import Link from "next/link";
import { ArrowRight, Inbox, ListChecks, Moon, Target } from "lucide-react";
import { getCurrentUser } from "@/lib/auth/session";
import { redirect } from "next/navigation";

export default async function HomePage() {
  const user = await getCurrentUser();
  if (user) redirect("/dashboard");

  const points = [
    { icon: Inbox, title: "생각을 빠르게 기록", text: "떠오른 일을 Inbox에 먼저 넣고 즉시 실행과 분리합니다." },
    { icon: Target, title: "세 개에 집중", text: "활성 프로젝트 수를 제한해 충동적인 동시 시작을 줄입니다." },
    { icon: ListChecks, title: "오늘 상태에 맞게", text: "에너지와 일정에 맞춰 핵심 행동만 고릅니다." },
    { icon: Moon, title: "휴식도 계획", text: "REST와 RECOVERY를 정상적인 선택으로 기록합니다." }
  ];

  return (
    <main className="min-h-screen bg-paper">
      <section className="shell grid min-h-screen content-center gap-10 py-12 lg:grid-cols-[1fr_0.9fr] lg:items-center">
        <div className="space-y-7">
          <p className="text-sm font-semibold uppercase tracking-wide text-moss">LifeOS</p>
          <div className="space-y-4">
            <h1 className="max-w-2xl text-4xl font-bold leading-tight text-ink sm:text-6xl">
              하고 싶은 일을 잃지 않고, 한 번에 너무 많이 시작하지 않게.
            </h1>
            <p className="max-w-xl text-lg leading-8 text-ink/70">
              LifeOS는 생각을 모으고, 주간 리뷰에서 고르고, 오늘의 작은 행동으로 옮기는 개인용 웹앱입니다.
            </p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <Link className="btn-primary" href="/signup">
              무료로 시작하기 <ArrowRight size={18} />
            </Link>
            <Link className="btn-secondary" href="/login">
              로그인
            </Link>
          </div>
        </div>
        <div className="grid gap-3">
          {points.map((point) => (
            <article key={point.title} className="panel flex gap-4">
              <point.icon className="mt-1 shrink-0 text-moss" size={24} aria-hidden />
              <div>
                <h2 className="font-semibold text-ink">{point.title}</h2>
                <p className="mt-1 text-sm leading-6 text-ink/65">{point.text}</p>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
