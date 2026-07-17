import Supabase
import SwiftUI

struct InboxListView: View {
    @StateObject private var store: InboxStore
    @Environment(\.scenePhase) private var scenePhase

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
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("아직 Inbox가 비어 있습니다", systemImage: "tray")
                    } description: {
                        Text("웹에서 기록한 항목 또는 다음 단계에서 추가할 빠른 입력이 여기에 나타납니다.")
                    }
                } else {
                    List(items) { item in
                        InboxRow(item: item)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Inbox")
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

private struct InboxRow: View {
    let item: InboxItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.categoryLabel)
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
