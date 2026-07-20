import Foundation
import Supabase

struct DailyPlan: Codable, Equatable {
    let id: UUID
    let planDate: String
    let energyLevel: String
    let dayMode: String
    let note: String?
    let restReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case planDate = "plan_date"
        case energyLevel = "energy_level"
        case dayMode = "day_mode"
        case note
        case restReason = "rest_reason"
    }
}

struct TodayAction: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let estimatedMinutes: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case estimatedMinutes = "estimated_minutes"
    }
}

private struct DailyPlanMutation: Encodable {
    let planDate: String
    let energyLevel: String
    let dayMode: String
    let note: String?
    let restReason: String?

    enum CodingKeys: String, CodingKey {
        case planDate = "plan_date"
        case energyLevel = "energy_level"
        case dayMode = "day_mode"
        case note
        case restReason = "rest_reason"
    }
}

private struct AddToTodayParameters: Encodable {
    let actionId: String
    let targetDate: String
    let makeCore: Bool

    enum CodingKeys: String, CodingKey {
        case actionId = "action_id"
        case targetDate = "target_date"
        case makeCore = "make_core"
    }
}

private struct ActionCompletionMutation: Encodable {
    let status: String
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
    }
}

@MainActor
final class TodayStore: ObservableObject {
    @Published private(set) var plan: DailyPlan?
    @Published private(set) var actions: [TodayAction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    let today: String
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
        today = Self.koreaDate()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedPlans: [DailyPlan] = try await client
                .from("daily_plans")
                .select("id,plan_date,energy_level,day_mode,note,rest_reason")
                .eq("plan_date", value: today)
                .execute()
                .value
            let fetchedActions: [TodayAction] = try await client
                .from("action_items")
                .select("id,title,estimated_minutes,status")
                .in("status", values: ["TODO", "PLANNED", "IN_PROGRESS"])
                .order("created_at", ascending: true)
                .execute()
                .value
            plan = fetchedPlans.first
            actions = fetchedActions
        } catch {
            errorMessage = "Today를 불러오지 못했습니다. 인터넷 연결과 Supabase 설정을 확인해 주세요."
        }
    }

    func savePlan(energyLevel: String, dayMode: String, note: String, restReason: String) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await client
                .from("daily_plans")
                .upsert(
                    DailyPlanMutation(
                        planDate: today,
                        energyLevel: energyLevel,
                        dayMode: dayMode,
                        note: note.isEmpty ? nil : note,
                        restReason: restReason.isEmpty ? nil : restReason
                    ),
                    onConflict: "user_id,plan_date"
                )
                .execute()
            await load()
        } catch {
            errorMessage = "오늘 계획을 저장하지 못했습니다. 다시 시도해 주세요."
        }
    }

    func addToToday(action: TodayAction, makeCore: Bool) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await client.rpc(
                "add_core_action_to_today",
                params: AddToTodayParameters(actionId: action.id.uuidString, targetDate: today, makeCore: makeCore)
            ).execute()
            await load()
        } catch {
            errorMessage = "행동을 오늘에 추가하지 못했습니다. 다시 시도해 주세요."
        }
    }

    func complete(action: TodayAction) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await client
                .from("action_items")
                .update(ActionCompletionMutation(status: "DONE", completedAt: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: action.id.uuidString)
                .execute()
            await load()
        } catch {
            errorMessage = "행동을 완료 처리하지 못했습니다. 다시 시도해 주세요."
        }
    }

    private static func koreaDate() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
