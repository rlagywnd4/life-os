"use client";

import { LogOut } from "lucide-react";
import { useState } from "react";
import { createClient } from "@/lib/supabase/browser";

export function LogoutButton() {
  const [loading, setLoading] = useState(false);

  async function logout() {
    setLoading(true);
    await createClient().auth.signOut();
    window.location.href = "/login";
  }

  return (
    <button className="btn-secondary w-full justify-start" onClick={logout} disabled={loading} aria-busy={loading}>
      {loading ? (
        <>
          <span className="btn-spinner" aria-hidden="true" /> 로그아웃 중
        </>
      ) : (
        <>
          <LogOut size={18} /> 로그아웃
        </>
      )}
    </button>
  );
}
