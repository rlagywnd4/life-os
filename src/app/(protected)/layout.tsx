import { redirect } from "next/navigation";
import { AppNav } from "@/components/app-nav";
import { getCurrentUser } from "@/lib/auth/session";

export default async function ProtectedLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user && process.env.NEXT_PUBLIC_SUPABASE_URL) redirect("/login");

  return (
    <main className="min-h-screen bg-paper pb-20 lg:pb-0 lg:pl-64">
      <AppNav />
      <div className="shell">{children}</div>
    </main>
  );
}
