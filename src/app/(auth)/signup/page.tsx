import Link from "next/link";
import { AuthForm } from "@/components/auth-form";

export default function SignupPage() {
  return (
    <div className="grid gap-4">
      <AuthForm mode="signup" />
      <p className="text-center text-sm text-ink/65">
        이미 계정이 있다면 <Link className="font-semibold text-sky" href="/login">로그인</Link>
      </p>
    </div>
  );
}
