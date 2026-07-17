import { Send } from "lucide-react";
import { createInboxItem } from "@/features/inbox/actions";
import { ActionButton } from "@/components/action-button";

export function QuickInboxForm() {
  return (
    <form action={createInboxItem} className="flex flex-col gap-2 sm:flex-row">
      <input className="field" name="title" placeholder="떠오른 생각을 바로 기록" aria-label="Inbox 제목" required />
      <ActionButton className="btn-primary sm:w-auto" type="submit" pendingLabel="저장 중">
        <Send size={18} /> 저장
      </ActionButton>
    </form>
  );
}
