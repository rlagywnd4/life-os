import { format, startOfWeek } from "date-fns";

export const DEFAULT_TIMEZONE = "Asia/Seoul";

export function toDateOnlyInKorea(date = new Date()) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: DEFAULT_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  });
  return formatter.format(date);
}

export function getKoreanWeekStart(date = new Date(), weekStartsOn: 0 | 1 | 2 | 3 | 4 | 5 | 6 = 1) {
  return format(startOfWeek(date, { weekStartsOn }), "yyyy-MM-dd");
}
