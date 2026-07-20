import Supabase
import SwiftUI

struct InboxListView: View {
    @StateObject private var store: InboxStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""
    @State private var isCreating = false
    @State private var categoryFilter = ""

    init(client: SupabaseClient) {
        _store = StateObject(wrappedValue: InboxStore(client: client))
    }

    var body: some View {
        Group {
            switch store.state {
            case .idle, .loading:
                ProgressView("Inbox 불러오는 중")

            case .failed(let message):
                ContentUnavailableView {
                    Label("Inbox를 불러오지 못했습니다", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("다시 시도") {
                        Task { await store.load() }
                    }
                }

            case .loaded(let items):
                let filteredItems = items.filter {
                    (categoryFilter.isEmpty || $0.category == categoryFilter) &&
                    (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false))
                }
                if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("아직 Inbox가 비어 있습니다", systemImage: "tray")
                    } description: {
                        Text("웹 또는 네이티브 앱에서 기록한 항목이 여기에 나타납니다.")
                    }
                } else {
                    List(filteredItems) { item in
                        NavigationLink {
                            InboxEditorView(store: store, item: item)
                        } label: {
                            InboxRow(item: item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Inbox")
        .searchable(text: $searchText, prompt: "Inbox 검색")
        .toolbar {
            Menu {
                Button("전체 카테고리") { categoryFilter = "" }
                Divider()
                ForEach(["SERVICE_IDEA", "STUDY", "CAREER", "EXERCISE", "CONTENT", "HOBBY", "LIFE", "TRAVEL", "PURCHASE", "ETC"], id: \.self) { value in
                    Button(InboxItem.categoryName(value)) { categoryFilter = value }
                }
            } label: {
                Label(categoryFilter.isEmpty ? "필터" : InboxItem.categoryName(categoryFilter), systemImage: "line.3.horizontal.decrease.circle")
            }
            Button("추가", systemImage: "plus") { isCreating = true }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack { InboxEditorView(store: store) }
        }
        .task {
            await store.load()
        }
        .refreshable {
            await store.load()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await store.load() }
        }
    }
}

private struct InboxEditorView: View {
    @ObservedObject var store: InboxStore
    let item: InboxItem?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var category: String
    @State private var status: String
    @State private var deleteConfirmation = false
    @State private var isConverting = false

    init(store: InboxStore, item: InboxItem? = nil) {
        self.store = store
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _description = State(initialValue: item?.description ?? "")
        _category = State(initialValue: item?.category ?? "ETC")
        _status = State(initialValue: item?.status ?? "UNREVIEWED")
    }

    var body: some View {
        Form {
            TextField("제목", text: $title)
            TextField("내용", text: $description, axis: .vertical)
            Picker("카테고리", selection: $category) {
                ForEach(["SERVICE_IDEA", "STUDY", "CAREER", "EXERCISE", "CONTENT", "HOBBY", "LIFE", "TRAVEL", "PURCHASE", "ETC"], id: \.self) { value in
                    Text(InboxItem.categoryName(value)).tag(value)
                }
            }
            if let item {
                Section("상태") {
                    if item.canEditStatus {
                        Picker("상태", selection: $status) {
                            ForEach(InboxItem.editableStatuses, id: \.self) { value in
                                Text(InboxItem.statusName(value)).tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        Text("상태를 선택한 뒤 저장을 누르면 반영됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("상태", value: item.statusLabel)
                        Text("프로젝트로 전환된 항목은 연결을 보호하기 위해 상태를 변경할 수 없습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if item.status == "UNREVIEWED" {
                    Section {
                        Button("프로젝트로 전환", systemImage: "arrow.right.circle") { isConverting = true }
                    }
                }
                Section { Button("삭제", role: .destructive) { deleteConfirmation = true } }
            }
            if let error = store.mutationError { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(item == nil ? "Inbox 추가" : "Inbox 수정")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        let saved = item == nil
                            ? await store.create(title: title, description: description, category: category)
                            : await store.update(
                                item!, title: title, description: description,
                                category: category, status: status
                            )
                        if saved { dismiss() }
                    }
                }.disabled(store.isSaving)
            }
        }
        .alert("Inbox를 삭제할까요?", isPresented: $deleteConfirmation) {
            Button("삭제", role: .destructive) { Task { if await store.delete(item!) { dismiss() } } }
        }
        .sheet(isPresented: $isConverting) {
            NavigationStack {
                InboxProjectConversionView(store: store, item: item!) {
                    isConverting = false
                    dismiss()
                }
            }
        }
    }
}

private struct InboxProjectConversionView: View {
    @ObservedObject var store: InboxStore
    let item: InboxItem
    let onConverted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var reason = ""
    @State private var desiredOutcome = ""
    @State private var activateNow = true

    init(store: InboxStore, item: InboxItem, onConverted: @escaping () -> Void) {
        self.store = store
        self.item = item
        self.onConverted = onConverted
        _title = State(initialValue: item.title)
    }

    var body: some View {
        Form {
            TextField("프로젝트 제목", text: $title)
            TextField("이 프로젝트가 필요한 이유", text: $reason, axis: .vertical)
            TextField("원하는 결과", text: $desiredOutcome, axis: .vertical)
            Toggle("바로 활성 프로젝트로 시작", isOn: $activateNow)
            if let error = store.mutationError { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("프로젝트로 전환")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("전환") {
                    Task {
                        if await store.convertToProject(
                            item, title: title, reason: reason,
                            desiredOutcome: desiredOutcome, activateNow: activateNow
                        ) { onConverted() }
                    }
                }
                .disabled(store.isSaving)
            }
        }
    }
}

private struct InboxRow: View {
    let item: InboxItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(item.categoryLabel)
                Text(item.statusLabel)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(item.title)
                .font(.headline)
            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 6)
    }
}
