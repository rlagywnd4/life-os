import Supabase
import SwiftUI

struct ProjectsView: View {
    @StateObject private var store: ProjectsStore
    private let statuses = ["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"]
    init(client: SupabaseClient) { _store = StateObject(wrappedValue: ProjectsStore(client: client)) }

    var body: some View {
        List {
            ForEach(statuses, id: \.self) { status in
                let projects = store.projects.filter { $0.status == status }
                if !projects.isEmpty {
                    Section(projects.first?.statusLabel ?? status) {
                        ForEach(projects) { project in
                            NavigationLink { ProjectDetailView(store: store, project: project) } label: {
                                VStack(alignment: .leading) {
                                    Text(project.title).font(.headline)
                                    Text(project.reason ?? "이 프로젝트를 시작한 이유를 기록할 수 있습니다.").font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    Text("미완료 활동 \(store.actions(for: project).filter { $0.status != "DONE" }.count)개").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("프로젝트")
        .task { await store.load() }
        .refreshable { await store.load() }
    }
}

private struct ProjectDetailView: View {
    @ObservedObject var store: ProjectsStore
    let project: LifeProject
    @State private var editingAction: ProjectAction?
    @State private var isCreating = false

    var body: some View {
        List {
            Section {
                Text(project.reason ?? "이유 미기록")
                if let desired = project.desiredOutcome { Text(desired).foregroundStyle(.secondary) }
                Picker("상태", selection: Binding(get: { project.status }, set: { value in Task { _ = await store.updateProjectStatus(project, status: value) } })) {
                    ForEach(["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"], id: \.self) { Text(["ACTIVE":"활성","WAITING":"대기","PAUSED":"일시정지","COMPLETED":"완료","ABANDONED":"중단"][$0]!).tag($0) }
                }
            }
            Section("활동") {
                ForEach(store.actions(for: project)) { action in
                    HStack {
                        Button { Task { _ = await store.toggleCompletion(action) } } label: { Image(systemName: action.status == "DONE" ? "checkmark.circle.fill" : "circle") }.buttonStyle(.plain)
                        VStack(alignment: .leading) { Text(action.title); Text("\(action.statusLabel) · \(action.estimatedMinutes)분").font(.caption).foregroundStyle(.secondary) }
                        Spacer(); Button("수정") { editingAction = action }.buttonStyle(.borderless)
                    }
                    .padding(.leading, action.parentActionId == nil ? 0 : 20)
                }
            }
        }
        .navigationTitle(project.title)
        .toolbar { Button("활동 추가", systemImage: "plus") { isCreating = true } }
        .sheet(isPresented: $isCreating) { NavigationStack { ActionEditorView(store: store, project: project) } }
        .sheet(item: $editingAction) { item in NavigationStack { ActionEditorView(store: store, project: project, item: item) } }
    }
}

private struct ActionEditorView: View {
    @ObservedObject var store: ProjectsStore
    let project: LifeProject
    let item: ProjectAction?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var minutes: Int
    @State private var parentId: UUID?
    init(store: ProjectsStore, project: LifeProject, item: ProjectAction? = nil) { self.store = store; self.project = project; self.item = item; _title = State(initialValue: item?.title ?? ""); _description = State(initialValue: item?.description ?? ""); _minutes = State(initialValue: item?.estimatedMinutes ?? 30); _parentId = State(initialValue: item?.parentActionId) }
    var body: some View {
        Form {
            TextField("활동 제목", text: $title)
            TextField("설명", text: $description, axis: .vertical)
            Stepper("예상 시간 \(minutes)분", value: $minutes, in: 5...480, step: 5)
            Picker("부모 활동", selection: $parentId) {
                Text("없음").tag(UUID?.none)
                ForEach(store.actions(for: project).filter { $0.id != item?.id }) { Text($0.title).tag(Optional($0.id)) }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(item == nil ? "활동 추가" : "활동 수정")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("저장") { Task { if await store.saveAction(project: project, item: item, parentId: parentId, title: title, description: description, minutes: minutes) { dismiss() } } }.disabled(store.isSaving) } }
    }
}
