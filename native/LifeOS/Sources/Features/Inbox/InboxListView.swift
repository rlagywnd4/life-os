import Supabase
import SwiftUI

struct InboxListView: View {
    @StateObject private var store: InboxStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""
    @State private var isCreating = false

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
                let filteredItems = items.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) }
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
    @State private var deleteConfirmation = false

    init(store: InboxStore, item: InboxItem? = nil) {
        self.store = store
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _description = State(initialValue: item?.description ?? "")
        _category = State(initialValue: item?.category ?? "ETC")
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
                    Picker("상태", selection: .constant(item.status)) {
                        Text(item.statusLabel).tag(item.status)
                    }
                    Button("언젠가로 이동") { Task { _ = await store.updateStatus(item, status: "SOMEDAY") } }
                    Button("보관") { Task { _ = await store.updateStatus(item, status: "ARCHIVED") } }
                    Button("폐기", role: .destructive) { Task { _ = await store.updateStatus(item, status: "DISCARDED") } }
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
                        let saved = item == nil ? await store.create(title: title, description: description, category: category) : await store.update(item!, title: title, description: description, category: category)
                        if saved { dismiss() }
                    }
                }.disabled(store.isSaving)
            }
        }
        .alert("Inbox를 삭제할까요?", isPresented: $deleteConfirmation) {
            Button("삭제", role: .destructive) { Task { if await store.delete(item!) { dismiss() } } }
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
