import Link from "next/link";
import { AuthForm } from "@/components/auth-form";

export default function LoginPage() {
  return (
    <div className="grid gap-4">
      <AuthForm mode="login" />
      <p className="text-center text-sm text-ink/65">
        계정이 없다면 <Link className="font-semibold text-sky" href="/signup">회원가입</Link>
        {" "}· <Link className="font-semibold text-sky" href="/forgot-password">비밀번호 찾기</Link>
      </p>
    </div>
  );
}
