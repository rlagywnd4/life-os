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
private struct ProjectLimitProfile: Codable { let maxActiveProjects: Int; enum CodingKeys: String, CodingKey { case maxActiveProjects = "max_active_projects" } }

@MainActor
final class ProjectsStore: ObservableObject {
    @Published private(set) var projects: [LifeProject] = []
    @Published private(set) var actions: [ProjectAction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var maxActiveProjects = 3
    private let client: SupabaseClient

    init(client: SupabaseClient) { self.client = client }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            async let projectRows: [LifeProject] = client.from("projects").select("id,title,description,reason,desired_outcome,status,updated_at").order("updated_at", ascending: false).execute().value
            async let actionRows: [ProjectAction] = client.from("action_items").select("id,project_id,parent_action_id,title,description,estimated_minutes,status,completed_at").order("created_at", ascending: true).execute().value
            async let profiles: [ProjectLimitProfile] = client.from("profiles").select("max_active_projects").limit(1).execute().value
            projects = try await projectRows; actions = try await actionRows; maxActiveProjects = try await profiles.first?.maxActiveProjects ?? 3
        } catch { errorMessage = "프로젝트를 불러오지 못했습니다." }
    }

    func actions(for project: LifeProject) -> [ProjectAction] { actions.filter { $0.projectId == project.id } }

    func flattenedActions(for project: LifeProject, below rootParentId: UUID? = nil) -> [ProjectActionNode] {
        let projectActions = actions(for: project)
        let grouped = Dictionary(grouping: projectActions, by: \.parentActionId)
        var result: [ProjectActionNode] = []
        var visited = Set<UUID>()
        func appendChildren(of parentId: UUID?, depth: Int) {
            for action in grouped[parentId] ?? [] where !visited.contains(action.id) {
                visited.insert(action.id)
                result.append(ProjectActionNode(action: action, depth: depth))
                appendChildren(of: action.id, depth: depth + 1)
            }
        }
        appendChildren(of: rootParentId, depth: 0)
        return result
    }

    func descendantIDs(of action: ProjectAction, in project: LifeProject) -> Set<UUID> {
        let projectActions = actions(for: project)
        let grouped = Dictionary(grouping: projectActions, by: \.parentActionId)
        var result = Set<UUID>()
        func visit(_ parentId: UUID) {
            for child in grouped[parentId] ?? [] where !result.contains(child.id) {
                result.insert(child.id)
                visit(child.id)
            }
        }
        visit(action.id)
        return result
    }

    func progress(of action: ProjectAction, in project: LifeProject) -> ProjectActionProgress {
        let ids = descendantIDs(of: action, in: project)
        let descendants = actions(for: project).filter { ids.contains($0.id) }
        return ProjectActionProgress(completed: descendants.filter { $0.status == "DONE" }.count, total: descendants.count)
    }

    func path(to action: ProjectAction, in project: LifeProject) -> [ProjectAction] {
        let projectActions = actions(for: project)
        let byId = Dictionary(uniqueKeysWithValues: projectActions.map { ($0.id, $0) })
        var path: [ProjectAction] = [action]
        var parentId = action.parentActionId
        var visited: Set<UUID> = [action.id]
        while let id = parentId, let parent = byId[id], !visited.contains(id) {
            path.insert(parent, at: 0)
            visited.insert(id)
            parentId = parent.parentActionId
        }
        return path
    }

    func parentCandidates(for item: ProjectAction?, in project: LifeProject) -> [ProjectAction] {
        guard let item else { return flattenedActions(for: project).map(\.action) }
        let unavailable = descendantIDs(of: item, in: project).union([item.id])
        return flattenedActions(for: project).map(\.action).filter { !unavailable.contains($0.id) }
    }

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
