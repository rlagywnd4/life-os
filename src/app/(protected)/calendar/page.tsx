import Link from "next/link";
import { ActionButton } from "@/components/action-button";
import { deleteCalendarEvent, saveCalendarEvent } from "@/features/calendar/actions";
import { createClient } from "@/lib/supabase/server";

export default async function CalendarPage() {
  const supabase = await createClient();
  const [{ data: events }, { data: actions }, { data: projects }] = supabase ? await Promise.all([
    supabase.from("calendar_events").select("*").order("event_date").order("start_time"),
    supabase.from("action_items").select("id,project_id,title,scheduled_date,scheduled_time,scheduled_end_time,is_all_day,estimated_minutes").not("scheduled_date", "is", null).is("deleted_at", null).order("scheduled_date").order("scheduled_time"),
    supabase.from("projects").select("id,title")
  ]) : [{ data: [] }, { data: [] }, { data: [] }];
  const projectTitles = new Map((projects ?? []).map((project) => [project.id, project.title]));
  const schedule = [
    ...(events ?? []).map((event) => ({ kind: "event" as const, key: `event-${event.id}`, date: event.event_date, time: event.start_time, title: event.title, detail: "일반 일정", event })),
    ...(actions ?? []).map((action) => ({ kind: "action" as const, key: `action-${action.id}`, date: action.scheduled_date!, time: action.scheduled_time, title: action.title, detail: `${projectTitles.get(action.project_id) ?? "프로젝트"} · ${action.estimated_minutes}분`, action }))
  ].sort((left, right) => `${left.date}${left.time ?? ""}`.localeCompare(`${right.date}${right.time ?? ""}`));
  return <div className="grid gap-6"><header><h1 className="text-3xl font-bold">캘린더</h1><p className="muted mt-2">일반 일정과 프로젝트 활동을 한 날짜 기준으로 확인합니다.</p></header><section className="panel"><h2 className="font-semibold">일반 일정 추가</h2><form action={saveCalendarEvent} className="mt-3 grid gap-3 sm:grid-cols-2"><label className="grid gap-1"><span className="label">제목</span><input className="field" name="title" required maxLength={160} /></label><label className="grid gap-1"><span className="label">날짜</span><input className="field" type="date" name="eventDate" required /></label><label className="grid gap-1"><span className="label">시작 시간</span><input className="field" type="time" name="startTime" /></label><label className="grid gap-1"><span className="label">종료 시간</span><input className="field" type="time" name="endTime" /></label><label className="flex items-center gap-2 text-sm font-semibold sm:col-span-2"><input type="checkbox" name="isAllDay" defaultChecked /> 종일</label><ActionButton className="btn-primary w-fit" pendingLabel="저장 중">일정 저장</ActionButton></form></section><section className="panel grid gap-3"><h2 className="font-semibold">날짜별 일정</h2>{schedule.map((entry) => <article className="flex flex-col gap-2 border-t border-line pt-3 sm:flex-row sm:items-center sm:justify-between" key={entry.key}><div><p className="font-semibold">{entry.date} {entry.time?.slice(0, 5) ?? "종일"} — {entry.title}</p><p className="muted">{entry.detail}</p></div>{entry.kind === "event" ? <form action={deleteCalendarEvent.bind(null, entry.event.id)}><ActionButton className="btn-secondary" pendingLabel="삭제 중">삭제</ActionButton></form> : <Link className="btn-secondary" href={`/projects/${entry.action.project_id}/actions/${entry.action.id}`}>활동 보기</Link>}</article>)}{schedule.length === 0 ? <p className="muted">일정이 없습니다.</p> : null}</section></div>;
}
