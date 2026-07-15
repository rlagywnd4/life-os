export const inboxCategoryLabels: Record<string, string> = {
  SERVICE_IDEA: "서비스 아이디어",
  STUDY: "공부",
  CAREER: "커리어",
  EXERCISE: "운동",
  CONTENT: "콘텐츠",
  HOBBY: "취미",
  LIFE: "생활",
  TRAVEL: "여행",
  PURCHASE: "구매",
  ETC: "기타"
};

export const inboxStatusLabels: Record<string, string> = {
  UNREVIEWED: "미검토",
  CONVERTED_TO_PROJECT: "프로젝트 전환됨",
  SOMEDAY: "언젠가",
  DISCARDED: "폐기",
  ARCHIVED: "보관됨"
};

export const projectStatusLabels: Record<string, string> = {
  ACTIVE: "활성",
  WAITING: "대기",
  PAUSED: "일시정지",
  COMPLETED: "완료",
  ABANDONED: "중단",
  ARCHIVED: "보관됨"
};

export const actionStatusLabels: Record<string, string> = {
  TODO: "할 일",
  PLANNED: "계획됨",
  IN_PROGRESS: "진행 중",
  DONE: "완료",
  SKIPPED: "건너뜀",
  CANCELED: "취소"
};

export const energyLevelLabels: Record<string, string> = {
  LOW: "낮음",
  MEDIUM: "보통",
  HIGH: "높음"
};

export const dayModeLabels: Record<string, string> = {
  NORMAL: "일반",
  REST: "휴식",
  RECOVERY: "회복",
  TRAVEL: "이동/여행",
  BUSY: "바쁨"
};

export const weeklyReviewStatusLabels: Record<string, string> = {
  IN_PROGRESS: "작성 중",
  COMPLETED: "완료"
};

export function getDisplayLabel(labels: Record<string, string>, value: string | null | undefined) {
  if (!value) return "";
  return labels[value] ?? value;
}
