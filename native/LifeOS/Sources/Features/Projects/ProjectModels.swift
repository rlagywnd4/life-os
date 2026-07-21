import Foundation

struct LifeProject: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let reason: String?
    let desiredOutcome: String?
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, reason, status
        case desiredOutcome = "desired_outcome"
        case updatedAt = "updated_at"
    }

    var statusLabel: String {
        ["ACTIVE": "활성", "WAITING": "대기", "PAUSED": "일시정지", "COMPLETED": "완료", "ABANDONED": "중단", "ARCHIVED": "보관됨"][status] ?? status
    }
}

struct ProjectAction: Codable, Identifiable, Equatable {
    let id: UUID
    let projectId: UUID
    let parentActionId: UUID?
    let title: String
    let description: String?
    let estimatedMinutes: Int
    let status: String
    let scheduledDate: String?
    let scheduledTime: String?
    let dueDate: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case projectId = "project_id"
        case parentActionId = "parent_action_id"
        case estimatedMinutes = "estimated_minutes"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case dueDate = "due_date"
        case completedAt = "completed_at"
    }

    var statusLabel: String {
        ["TODO": "할 일", "PLANNED": "계획됨", "IN_PROGRESS": "진행 중", "DONE": "완료", "SKIPPED": "건너뜀", "CANCELED": "취소"][status] ?? status
    }
}

struct ProjectActionNode: Identifiable {
    let action: ProjectAction
    let depth: Int
    var id: UUID { action.id }
}

struct ProjectActionProgress {
    let completed: Int
    let total: Int
    var percentage: Int { total == 0 ? 0 : Int((Double(completed) / Double(total) * 100).rounded()) }
    var allCompleted: Bool { total > 0 && completed == total }
}
