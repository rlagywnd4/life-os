export type EnergyLevel = "LOW" | "MEDIUM" | "HIGH";
export type ProjectStatus = "ACTIVE" | "WAITING" | "PAUSED" | "COMPLETED" | "ABANDONED" | "ARCHIVED";

const vagueActionWords = ["공부하기", "준비하기", "개발하기", "운동하기", "정리하기", "완성하기", "열심히 하기"];

export function getActionSizeWarning(minutes: number, recommendedMinutes = 30) {
  if (minutes > recommendedMinutes) {
    return "이 행동은 조금 커 보입니다. 30분 안에 시작하고 끝낼 수 있도록 더 작게 나눠보세요.";
  }
  return null;
}

export function getActionSpecificityWarning(title: string) {
  const normalized = title.trim();
  if (vagueActionWords.includes(normalized)) {
    return "조금 더 구체적인 첫 행동으로 바꿔보세요.";
  }
  return null;
}

export function getRecommendedCoreActionRange(energy: EnergyLevel) {
  if (energy === "LOW") return { min: 0, max: 1 };
  if (energy === "MEDIUM") return { min: 1, max: 2 };
  return { min: 1, max: 3 };
}

export function canTransitionProject(from: ProjectStatus, to: ProjectStatus) {
  const transitions: Record<ProjectStatus, ProjectStatus[]> = {
    ACTIVE: ["PAUSED", "COMPLETED", "ABANDONED", "ARCHIVED"],
    WAITING: ["ACTIVE", "PAUSED", "ABANDONED", "ARCHIVED"],
    PAUSED: ["ACTIVE", "WAITING", "ABANDONED", "ARCHIVED"],
    COMPLETED: ["ARCHIVED"],
    ABANDONED: ["ARCHIVED"],
    ARCHIVED: []
  };
  return transitions[from].includes(to);
}

export function assertActiveProjectLimit(currentActiveCount: number, maxActiveProjects: number) {
  if (currentActiveCount >= maxActiveProjects) {
    return {
      ok: false as const,
      code: "ACTIVE_PROJECT_LIMIT_EXCEEDED",
      message: "활성 프로젝트 한도에 도달했습니다. 기존 프로젝트를 보류하거나 새 프로젝트를 대기 상태로 저장하세요."
    };
  }
  return { ok: true as const };
}

export function formatAppError(error: unknown) {
  if (error instanceof Error) {
    return { code: error.message || "UNKNOWN_ERROR", message: error.message };
  }
  return { code: "UNKNOWN_ERROR", message: "요청을 처리하지 못했습니다." };
}
