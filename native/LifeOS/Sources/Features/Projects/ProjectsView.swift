import Supabase
import SwiftUI

struct ProjectsView: View {
    @StateObject private var store: ProjectsStore
    private let statuses = ["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"]
    init(client: SupabaseClient) { _store = StateObject(wrappedValue: ProjectsStore(client: client)) }

    var body: some View {
        List {
            Section {
                LabeledContent("활성 프로젝트", value: "\(store.projects.filter { $0.status == "ACTIVE" }.count) / \(store.maxActiveProjects)")
            }
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

    private var currentProject: LifeProject { store.projects.first(where: { $0.id == project.id }) ?? project }

    var body: some View {
        List {
            Section {
                Text(project.reason ?? "이유 미기록")
                if let desired = project.desiredOutcome { Text(desired).foregroundStyle(.secondary) }
                Picker("상태", selection: Binding(get: { currentProject.status }, set: { value in Task { _ = await store.updateProjectStatus(currentProject, status: value) } })) {
                    ForEach(["ACTIVE", "WAITING", "PAUSED", "COMPLETED", "ABANDONED"], id: \.self) { Text(["ACTIVE":"활성","WAITING":"대기","PAUSED":"일시정지","COMPLETED":"완료","ABANDONED":"중단"][$0]!).tag($0) }
                }
            }
            Section("활동") {
                ForEach(store.flattenedActions(for: project)) { node in
                    let action = node.action
                    let progress = store.progress(of: action, in: project)
                    HStack(spacing: 10) {
                        Button { Task { _ = await store.toggleCompletion(action) } } label: { Image(systemName: action.status == "DONE" ? "checkmark.circle.fill" : "circle") }.buttonStyle(.plain)
                        NavigationLink {
                            ActionDetailView(store: store, project: currentProject, actionId: action.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(action.title)
                                HStack {
                                    Text("\(action.statusLabel) · \(action.estimatedMinutes)분")
                                    if progress.total > 0 { Text("하위 \(progress.completed)/\(progress.total)") }
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.leading, CGFloat(node.depth * 20))
                }
            }
        }
        .navigationTitle(project.title)
        .toolbar { Button("활동 추가", systemImage: "plus") { isCreating = true } }
        .sheet(isPresented: $isCreating) { NavigationStack { ActionEditorView(store: store, project: project) } }
        .sheet(item: $editingAction) { item in NavigationStack { ActionEditorView(store: store, project: project, item: item) } }
    }
}

private struct ActionDetailView: View {
    @ObservedObject var store: ProjectsStore
    let project: LifeProject
    let actionId: UUID
    @State private var isEditing = false
    @State private var isAddingChild = false

    private var action: ProjectAction? { store.actions.first(where: { $0.id == actionId }) }

    var body: some View {
        List {
            if let action {
                let progress = store.progress(of: action, in: project)
                Section {
                    Text(store.path(to: action, in: project).map(\.title).joined(separator: " › "))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(action.title).font(.title2.bold())
                    if let description = action.description, !description.isEmpty { Text(description) }
                    LabeledContent("상태", value: action.statusLabel)
                    LabeledContent("예상 시간", value: "\(action.estimatedMinutes)분")
                    if let scheduledDate = action.scheduledDate {
                        LabeledContent("실행", value: "\(scheduledDate) · \(LifeOSDate.timeLabel(action.scheduledTime))")
                    }
                    if let dueDate = action.dueDate { LabeledContent("마감", value: dueDate) }
                    Button(action.status == "DONE" ? "미완료로 되돌리기" : "활동 완료") {
                        Task { _ = await store.toggleCompletion(action) }
                    }
                }
                if progress.total > 0 {
                    Section("하위 활동 진행률") {
                        ProgressView(value: Double(progress.completed), total: Double(progress.total))
                        Text("\(progress.completed)/\(progress.total) 완료 · \(progress.percentage)%")
                        if progress.allCompleted && action.status != "DONE" && action.status != "CANCELED" {
                            Button("모든 하위 활동을 완료했습니다. 부모 활동도 완료") {
                                Task { _ = await store.toggleCompletion(action) }
                            }
                        }
                    }
                }
                Section("하위 활동") {
                    ForEach(store.flattenedActions(for: project, below: action.id)) { node in
                        NavigationLink {
                            ActionDetailView(store: store, project: project, actionId: node.action.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(node.action.title)
                                Text(node.action.statusLabel).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.leading, CGFloat(node.depth * 20))
                        }
                    }
                    Button("하위 활동 추가", systemImage: "plus") { isAddingChild = true }
                }
            } else {
                ContentUnavailableView("활동을 찾을 수 없습니다", systemImage: "exclamationmark.circle")
            }
        }
        .navigationTitle(action?.title ?? "활동")
        .toolbar { Button("수정") { isEditing = true }.disabled(action == nil) }
        .sheet(isPresented: $isEditing) {
            if let action { NavigationStack { ActionEditorView(store: store, project: project, item: action) } }
        }
        .sheet(isPresented: $isAddingChild) {
            NavigationStack { ActionEditorView(store: store, project: project, initialParentId: actionId) }
        }
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
    @State private var hasScheduledDate: Bool
    @State private var scheduledDate: Date
    @State private var hasScheduledTime: Bool
    @State private var scheduledTime: Date
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    init(store: ProjectsStore, project: LifeProject, item: ProjectAction? = nil, initialParentId: UUID? = nil) {
        self.store = store; self.project = project; self.item = item
        _title = State(initialValue: item?.title ?? ""); _description = State(initialValue: item?.description ?? "")
        _minutes = State(initialValue: item?.estimatedMinutes ?? 30); _parentId = State(initialValue: item?.parentActionId ?? initialParentId)
        _hasScheduledDate = State(initialValue: item?.scheduledDate != nil)
        _scheduledDate = State(initialValue: LifeOSDate.date(item?.scheduledDate) ?? Date())
        _hasScheduledTime = State(initialValue: item?.scheduledTime != nil)
        _scheduledTime = State(initialValue: LifeOSDate.time(item?.scheduledTime) ?? Date())
        _hasDueDate = State(initialValue: item?.dueDate != nil)
        _dueDate = State(initialValue: LifeOSDate.date(item?.dueDate) ?? Date())
    }
    var body: some View {
        Form {
            TextField("활동 제목", text: $title)
            TextField("설명", text: $description, axis: .vertical)
            Stepper("예상 시간 \(minutes)분", value: $minutes, in: 5...480, step: 5)
            Section("실행 계획") {
                Toggle("실행일 지정", isOn: $hasScheduledDate)
                if hasScheduledDate {
                    DatePicker("실행일", selection: $scheduledDate, displayedComponents: .date)
                    Toggle("시간 지정", isOn: $hasScheduledTime)
                    if hasScheduledTime { DatePicker("시작 시간", selection: $scheduledTime, displayedComponents: .hourAndMinute) }
                }
                Toggle("마감일 지정", isOn: $hasDueDate)
                if hasDueDate { DatePicker("마감일", selection: $dueDate, displayedComponents: .date) }
                Text("실행일을 정한 활동만 달력에 표시됩니다.").font(.caption).foregroundStyle(.secondary)
            }
            Picker("부모 활동", selection: $parentId) {
                Text("없음").tag(UUID?.none)
                ForEach(store.parentCandidates(for: item, in: project)) { candidate in
                    Text(store.path(to: candidate, in: project).map(\.title).joined(separator: " › ")).tag(Optional(candidate.id))
                }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(item == nil ? "활동 추가" : "활동 수정")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("저장") { Task { if await store.saveAction(project: project, item: item, parentId: parentId, title: title, description: description, minutes: minutes, scheduledDate: hasScheduledDate ? scheduledDate : nil, scheduledTime: hasScheduledDate && hasScheduledTime ? scheduledTime : nil, dueDate: hasDueDate ? dueDate : nil) { dismiss() } } }.disabled(store.isSaving) } }
    }
}
