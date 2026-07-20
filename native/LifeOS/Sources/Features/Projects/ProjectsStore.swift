import Foundation
import Supabase

private struct ProjectStatusMutation: Encodable { let status: String }
private struct ActionMutation: Encodable {
    let projectId: String
    let parentActionId: String?
    let title: String
    let description: String?
    let estimatedMinutes: Int
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case parentActionId = "parent_action_id"
        case title, description
        case estimatedMinutes = "estimated_minutes"
    }
}
private struct ActionUpdateMutation: Encodable {
    let parentActionId: String?
    let title: String
    let description: String?
    let estimatedMinutes: Int
    enum CodingKeys: String, CodingKey {
        case parentActionId = "parent_action_id"
        case title, description
        case estimatedMinutes = "estimated_minutes"
    }
}
private struct ActionCompletionMutation: Encodable { let status: String; let completedAt: String?; enum CodingKeys: String, CodingKey { case status; case completedAt = "completed_at" } }

@MainActor
final class ProjectsStore: ObservableObject {
    @Published private(set) var projects: [LifeProject] = []
    @Published private(set) var actions: [ProjectAction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    private let client: SupabaseClient

    init(client: SupabaseClient) { self.client = client }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            async let projectRows: [LifeProject] = client.from("projects").select("id,title,description,reason,desired_outcome,status,updated_at").order("updated_at", ascending: false).execute().value
            async let actionRows: [ProjectAction] = client.from("action_items").select("id,project_id,parent_action_id,title,description,estimated_minutes,status,completed_at").order("created_at", ascending: true).execute().value
            projects = try await projectRows; actions = try await actionRows
        } catch { errorMessage = "프로젝트를 불러오지 못했습니다." }
    }

    func actions(for project: LifeProject) -> [ProjectAction] { actions.filter { $0.projectId == project.id } }

    func updateProjectStatus(_ project: LifeProject, status: String) async -> Bool {
        await mutate { try await self.client.from("projects").update(ProjectStatusMutation(status: status)).eq("id", value: project.id.uuidString).execute() }
    }

    func saveAction(project: LifeProject, item: ProjectAction?, parentId: UUID?, title: String, description: String, minutes: Int) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { errorMessage = "활동 제목을 입력해 주세요."; return false }
        if let item {
            return await mutate { try await self.client.from("action_items").update(ActionUpdateMutation(parentActionId: parentId?.uuidString, title: title, description: description.isEmpty ? nil : description, estimatedMinutes: minutes)).eq("id", value: item.id.uuidString).eq("project_id", value: project.id.uuidString).execute() }
        }
        return await mutate { try await self.client.from("action_items").insert(ActionMutation(projectId: project.id.uuidString, parentActionId: parentId?.uuidString, title: title, description: description.isEmpty ? nil : description, estimatedMinutes: minutes)).execute() }
    }

    func toggleCompletion(_ action: ProjectAction) async -> Bool {
        let done = action.status != "DONE"
        return await mutate { try await self.client.from("action_items").update(ActionCompletionMutation(status: done ? "DONE" : "TODO", completedAt: done ? ISO8601DateFormatter().string(from: Date()) : nil)).eq("id", value: action.id.uuidString).execute() }
    }

    private func mutate(_ operation: () async throws -> Void) async -> Bool {
        isSaving = true; errorMessage = nil
        defer { isSaving = false }
        do { try await operation(); await load(); return true }
        catch { errorMessage = "변경사항을 저장하지 못했습니다: \(error.localizedDescription)"; return false }
    }
}
