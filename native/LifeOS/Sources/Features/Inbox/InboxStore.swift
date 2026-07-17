import Foundation
import Supabase

@MainActor
final class InboxStore: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded([InboxItem])
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func load() async {
        if case .loaded(let items) = state {
            state = .loading
            await fetch(preserving: items)
        } else {
            state = .loading
            await fetch(preserving: [])
        }
    }

    private func fetch(preserving existingItems: [InboxItem]) async {
        do {
            let items: [InboxItem] = try await client
                .from("inbox_items")
                .select("id,title,description,category,status,created_at,updated_at")
                .eq("status", value: "UNREVIEWED")
                .order("created_at", ascending: false)
                .execute()
                .value
            state = .loaded(items)
        } catch {
            if existingItems.isEmpty {
                state = .failed("Inbox를 불러오지 못했습니다. 연결을 확인한 뒤 다시 시도하세요.")
            } else {
                state = .loaded(existingItems)
            }
        }
    }
}
