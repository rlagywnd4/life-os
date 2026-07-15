import Link from "next/link";

const tabs = [
  { href: "/health", label: "오늘" },
  { href: "/health/weight", label: "체중" },
  { href: "/health/workout", label: "운동" },
  { href: "/health/report", label: "리포트" },
  { href: "/health/settings", label: "설정" }
];

export function HealthTabs() {
  return (
    <nav className="flex gap-2 overflow-x-auto border-b border-line pb-2">
      {tabs.map((tab) => (
        <Link key={tab.href} href={tab.href} className="btn-secondary min-w-fit">
          {tab.label}
        </Link>
      ))}
    </nav>
  );
}
