import Link from "next/link";
import { CalendarDays, FolderKanban, HeartPulse, History, Inbox, LayoutDashboard, Settings, Sparkles } from "lucide-react";
import { LogoutButton } from "@/components/logout-button";

const nav = [
  { href: "/dashboard", label: "대시보드", icon: LayoutDashboard },
  { href: "/health", label: "건강", icon: HeartPulse },
  { href: "/inbox", label: "Inbox", icon: Inbox },
  { href: "/projects", label: "프로젝트", icon: FolderKanban },
  { href: "/today", label: "오늘", icon: CalendarDays },
  { href: "/weekly-review", label: "주간 리뷰", icon: Sparkles },
  { href: "/history", label: "기록", icon: History },
  { href: "/settings", label: "설정", icon: Settings }
];

export function AppNav() {
  return (
    <>
      <aside className="fixed left-0 top-0 hidden h-screen w-64 border-r border-line bg-white p-4 lg:block">
        <Link href="/dashboard" className="mb-6 block text-xl font-bold text-ink">LifeOS</Link>
        <nav className="grid gap-1">
          {nav.map((item) => (
            <Link key={item.href} href={item.href} className="flex min-h-11 items-center gap-3 rounded-md px-3 text-sm font-semibold text-ink/75 hover:bg-paper hover:text-ink">
              <item.icon size={18} /> {item.label}
            </Link>
          ))}
        </nav>
        <div className="absolute bottom-4 left-4 right-4">
          <LogoutButton />
        </div>
      </aside>
      <nav className="fixed bottom-0 left-0 right-0 z-10 grid grid-cols-5 border-t border-line bg-white lg:hidden">
        {nav.slice(0, 5).map((item) => (
          <Link key={item.href} href={item.href} className="flex min-h-14 flex-col items-center justify-center gap-1 text-[11px] font-semibold text-ink/75">
            <item.icon size={18} /> {item.label}
          </Link>
        ))}
      </nav>
    </>
  );
}
