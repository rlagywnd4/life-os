import { differenceInCalendarDays, eachDayOfInterval, endOfDay, getDay, startOfDay, subDays } from "date-fns";

export type HealthCheckIn = {
  check_in_date: string;
  weight_kg: number | null;
  steps: number | null;
  brisk_walk_status: string;
  planned_snack_done: boolean | null;
  dinner_overeating: boolean | null;
  exercise_completion: string;
  low_energy_mode: boolean;
};

export type HealthProfile = {
  snack_weekdays: number[];
};

export const workoutRoutineA = [
  "의자 스쿼트 10회 x 3세트",
  "벽 또는 높은 지지대 푸시업 8회 x 3세트",
  "글루트 브리지 12회 x 3세트",
  "버드독 좌우 각 8회 x 2세트",
  "제자리 걷기 5분"
];

export const workoutRoutineB = [
  "스텝업 또는 낮은 계단 오르기 좌우 각 8회 x 3세트",
  "힙 힌지 10회 x 3세트",
  "밴드 또는 수건 로우 10회 x 3세트",
  "무릎을 댄 플랭크 15~20초 x 3세트",
  "가벼운 전신 스트레칭 5분"
];

export const workoutMinimumA = ["의자 스쿼트 10회", "벽 푸시업 8회", "글루트 브리지 10회", "제자리 걷기 3분"];
export const workoutMinimumB = ["스텝업 좌우 각 5회", "힙 힌지 10회", "버드독 좌우 각 5회", "스트레칭 3분"];

export function getRecentWindow(today = new Date()) {
  const end = endOfDay(today);
  const start = startOfDay(subDays(end, 13));
  return { start, end, days: eachDayOfInterval({ start, end }) };
}

function asDateKey(date: Date) {
  return date.toISOString().slice(0, 10);
}

function rate(done: number, planned: number) {
  if (planned === 0) return null;
  return Math.round((done / planned) * 100);
}

export function calculateHealthAdherence(checkIns: HealthCheckIn[], profile?: HealthProfile | null, today = new Date()) {
  const byDate = new Map(checkIns.map((checkIn) => [checkIn.check_in_date, checkIn]));
  const weekdays = profile?.snack_weekdays ?? [1, 2, 3, 4, 5];
  const rows = {
    weight: { label: "체중 기록", done: 0, planned: 0 },
    steps: { label: "걸음 수 기록", done: 0, planned: 0 },
    briskWalk: { label: "빠르게 걷기", done: 0, planned: 0 },
    plannedSnack: { label: "계획된 간식", done: 0, planned: 0 },
    dinner: { label: "저녁 과식 방지", done: 0, planned: 0 },
    weekendStrength: { label: "주말 근력운동", done: 0, planned: 0 }
  };

  for (const day of getRecentWindow(today).days) {
    const checkIn = byDate.get(asDateKey(day));
    if (!checkIn) continue;
    const dayOfWeek = getDay(day);
    const isWeekday = dayOfWeek >= 1 && dayOfWeek <= 5;
    const isSnackDay = weekdays.includes(dayOfWeek);
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

    rows.weight.planned += 1;
    if (checkIn.weight_kg) rows.weight.done += 1;

    rows.steps.planned += 1;
    if (typeof checkIn.steps === "number") rows.steps.done += 1;

    if (isWeekday) {
      rows.briskWalk.planned += 1;
      if (["DONE", "PARTIAL", "ALTERNATIVE"].includes(checkIn.brisk_walk_status)) rows.briskWalk.done += 1;
    }

    if (isSnackDay) {
      rows.plannedSnack.planned += 1;
      if (checkIn.planned_snack_done === true) rows.plannedSnack.done += 1;
    }

    rows.dinner.planned += 1;
    if (checkIn.dinner_overeating === false) rows.dinner.done += 1;

    if (isWeekend) {
      rows.weekendStrength.planned += 1;
      if (["FULL", "MINIMUM", "ALTERNATIVE"].includes(checkIn.exercise_completion)) rows.weekendStrength.done += 1;
    }
  }

  return Object.entries(rows).map(([key, value]) => ({
    key,
    ...value,
    rate: rate(value.done, value.planned)
  }));
}

export function getAverageWeightTrend(checkIns: HealthCheckIn[]) {
  const sorted = checkIns
    .filter((checkIn) => typeof checkIn.weight_kg === "number")
    .sort((a, b) => a.check_in_date.localeCompare(b.check_in_date));
  if (sorted.length < 4) return null;

  const mid = Math.ceil(sorted.length / 2);
  const previous = sorted.slice(0, mid);
  const recent = sorted.slice(mid);
  const average = (rows: HealthCheckIn[]) => rows.reduce((sum, row) => sum + (row.weight_kg ?? 0), 0) / rows.length;
  const diff = average(recent) - average(previous);
  return Number(diff.toFixed(2));
}

export function generateHealthFeedback(checkIns: HealthCheckIn[], profile?: HealthProfile | null, today = new Date()) {
  const adherence = calculateHealthAdherence(checkIns, profile, today);
  const measured = adherence.filter((item) => item.rate !== null);
  if (measured.length === 0) {
    return "아직 단정할 만큼 데이터가 충분하지 않습니다. 오늘 기록 하나부터 남겨도 충분합니다.";
  }

  const best = [...measured].sort((a, b) => (b.rate ?? 0) - (a.rate ?? 0))[0];
  const weakest = [...measured].sort((a, b) => (a.rate ?? 0) - (b.rate ?? 0))[0];
  const trend = getAverageWeightTrend(checkIns);
  const trendText =
    trend === null
      ? "체중 추세는 아직 데이터가 조금 더 필요합니다."
      : trend > 0
        ? "체중은 단일 측정값보다 평균 추세로 보면 최근 약간 올라간 흐름입니다."
        : trend < 0
          ? "체중 평균 추세는 천천히 내려가는 흐름입니다."
          : "체중 평균 추세는 대체로 안정적입니다.";

  return `최근에는 ${best.label}을 가장 안정적으로 유지했습니다. ${trendText} 다음에는 ${weakest.label} 하나만 우선 조정해보세요. 휴식과 저에너지 모드는 실패가 아니라 계획 조정입니다.`;
}

export function daysSince(dateString?: string | null, today = new Date()) {
  if (!dateString) return null;
  return differenceInCalendarDays(today, new Date(dateString));
}
