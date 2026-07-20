import Foundation
import Supabase

private struct InboxMutation: Encodable {
    let title: String
    let description: String?
    let category: String
}

private struct InboxStatusMutation: Encodable {
    let status: String
}

@MainActor
final class InboxStore: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded([InboxItem])
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isSaving = false
    @Published private(set) var mutationError: String?

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

    func create(title: String, description: String, category: String) async -> Bool {
        await save(item: nil, title: title, description: description, category: category)
    }

    func update(_ item: InboxItem, title: String, description: String, category: String) async -> Bool {
        await save(item: item, title: title, description: description, category: category)
    }

    func updateStatus(_ item: InboxItem, status: String) async -> Bool {
        await performMutation {
            try await self.client.from("inbox_items")
                .update(InboxStatusMutation(status: status))
                .eq("id", value: item.id.uuidString)
                .execute()
        }
    }

    func delete(_ item: InboxItem) async -> Bool {
        await performMutation {
            try await self.client.from("inbox_items")
                .delete()
                .eq("id", value: item.id.uuidString)
                .execute()
        }
    }

    private func save(item: InboxItem?, title: String, description: String, category: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            mutationError = "Inbox 제목을 입력해 주세요."
            return false
        }
        let mutation = InboxMutation(title: trimmedTitle, description: description.isEmpty ? nil : description, category: category)
        if let item {
            return await performMutation {
                try await self.client.from("inbox_items").update(mutation).eq("id", value: item.id.uuidString).execute()
            }
        }
        return await performMutation {
            try await self.client.from("inbox_items").insert(mutation).execute()
        }
    }

    private func performMutation(_ operation: () async throws -> Void) async -> Bool {
        isSaving = true
        mutationError = nil
        defer { isSaving = false }
        do {
            try await operation()
            await load()
            return true
        } catch {
            mutationError = "저장하지 못했습니다. 인터넷 연결과 Supabase 설정을 확인해 주세요."
            return false
        }
    }

    private func fetch(preserving existingItems: [InboxItem]) async {
        do {
            let items: [InboxItem] = try await client
                .from("inbox_items")
                .select("id,title,description,category,status,created_at,updated_at")
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
