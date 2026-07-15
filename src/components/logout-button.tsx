"use client";

import { LogOut } from "lucide-react";
import { createClient } from "@/lib/supabase/browser";

export function LogoutButton() {
  async function logout() {
    await createClient().auth.signOut();
    window.location.href = "/login";
  }

  return (
    <button className="btn-secondary w-full justify-start" onClick={logout}>
      <LogOut size={18} /> 로그아웃
    </button>
  );
}
