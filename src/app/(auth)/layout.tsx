import Link from "next/link";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="min-h-screen bg-paper">
      <div className="shell">
        <Link href="/" className="mb-8 inline-block text-xl font-bold text-ink">LifeOS</Link>
        {children}
      </div>
    </main>
  );
}
