"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/browser";
import { getSiteUrl } from "@/lib/env";

type Mode = "login" | "signup" | "forgot" | "reset";

export function AuthForm({ mode }: { mode: Mode }) {
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setMessage("");
    const form = new FormData(event.currentTarget);
    const email = String(form.get("email") ?? "");
    const password = String(form.get("password") ?? "");
    const supabase = createClient();
    const siteUrl = getSiteUrl();

    const result =
      mode === "signup"
        ? await supabase.auth.signUp({
            email,
            password,
            options: { emailRedirectTo: `${siteUrl}/auth/callback?next=/dashboard` }
          })
        : mode === "forgot"
          ? await supabase.auth.resetPasswordForEmail(email, {
              redirectTo: `${siteUrl}/reset-password`
            })
          : mode === "reset"
            ? await supabase.auth.updateUser({ password })
            : await supabase.auth.signInWithPassword({ email, password });

    if (result.error) {
      setMessage(result.error.message);
      setLoading(false);
      return;
    }

    if (mode === "login" || mode === "reset") {
      window.location.href = "/dashboard";
      return;
    }

    setMessage(mode === "forgot" ? "비밀번호 재설정 메일을 보냈습니다." : "가입 메일을 확인해주세요.");
    setLoading(false);
  }

  const title = {
    login: "로그인",
    signup: "회원가입",
    forgot: "비밀번호 찾기",
    reset: "비밀번호 재설정"
  }[mode];

  return (
    <form onSubmit={onSubmit} className="panel mx-auto grid w-full max-w-md gap-4">
      <h1 className="text-2xl font-bold text-ink">{title}</h1>
      {mode !== "reset" ? (
        <label className="grid gap-2">
          <span className="label">이메일</span>
          <input className="field" name="email" type="email" required autoComplete="email" />
        </label>
      ) : null}
      {mode !== "forgot" ? (
        <label className="grid gap-2">
          <span className="label">비밀번호</span>
          <input
            className="field"
            name="password"
            type="password"
            required
            minLength={6}
            autoComplete={mode === "login" ? "current-password" : "new-password"}
          />
        </label>
      ) : null}
      <button className="btn-primary" disabled={loading} aria-busy={loading}>
        {loading ? (
          <>
            <span className="btn-spinner" aria-hidden="true" />
            처리 중
          </>
        ) : (
          title
        )}
      </button>
      {message ? <p className="muted" role="status">{message}</p> : null}
    </form>
  );
}
