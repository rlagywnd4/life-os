import Foundation
import Supabase

struct DailyPlan: Codable, Equatable {
    let id: UUID
    let planDate: String
    let energyLevel: String
    let dayMode: String
    let note: String?
    let restReason: String?
    let availableMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case planDate = "plan_date"
        case energyLevel = "energy_level"
        case dayMode = "day_mode"
        case note
        case restReason = "rest_reason"
        case availableMinutes = "available_minutes"
    }
}

struct TodayAction: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let estimatedMinutes: Int
    let status: String
    let scheduledDate: String?
    let scheduledTime: String?
    let dueDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case estimatedMinutes = "estimated_minutes"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case dueDate = "due_date"
    }
}

private struct DailyPlanMutation: Encodable {
    let planDate: String
    let energyLevel: String
    let dayMode: String
    let note: String?
    let restReason: String?
    let availableMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case planDate = "plan_date"
        case energyLevel = "energy_level"
        case dayMode = "day_mode"
        case note
        case restReason = "rest_reason"
        case availableMinutes = "available_minutes"
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

private struct TodayRescheduleParameters: Encodable {
    let actionId: String
    let targetDate: String
    let targetTime: String?
    let changeReason: String?
    enum CodingKeys: String, CodingKey {
        case actionId = "action_id"; case targetDate = "target_date"; case targetTime = "target_time"; case changeReason = "change_reason"
    }
}

@MainActor
final class TodayStore: ObservableObject {
    @Published private(set) var plan: DailyPlan?
    @Published private(set) var actions: [TodayAction] = []
    @Published private(set) var events: [CalendarEvent] = []
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
            async let fetchedPlans: [DailyPlan] = client
                .from("daily_plans")
                .select("id,plan_date,energy_level,day_mode,note,rest_reason,available_minutes")
                .eq("plan_date", value: today)
                .execute()
                .value
            async let fetchedActions: [TodayAction] = client
                .from("action_items")
                .select("id,title,estimated_minutes,status,scheduled_date,scheduled_time,due_date")
                .in("status", values: ["TODO", "PLANNED", "IN_PROGRESS"])
                .order("created_at", ascending: true)
                .execute()
                .value
            async let fetchedEvents: [CalendarEvent] = client.from("calendar_events")
                .select("id,title,description,event_date,start_time,end_time,is_all_day,category,location")
                .eq("event_date", value: today).order("start_time", ascending: true).execute().value
            plan = try await fetchedPlans.first
            actions = try await fetchedActions
            events = try await fetchedEvents
        } catch {
            errorMessage = "Today를 불러오지 못했습니다. 인터넷 연결과 Supabase 설정을 확인해 주세요."
        }
    }

    func savePlan(energyLevel: String, dayMode: String, note: String, restReason: String, availableMinutes: Int?) async {
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
                        restReason: restReason.isEmpty ? nil : restReason,
                        availableMinutes: availableMinutes
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

    func moveToTomorrow(action: TodayAction) async {
        guard let todayDate = LifeOSDate.date(today), let tomorrow = LifeOSDate.calendar.date(byAdding: .day, value: 1, to: todayDate) else { return }
        isSaving = true; errorMessage = nil
        defer { isSaving = false }
        do {
            try await client.rpc("reschedule_action", params: TodayRescheduleParameters(
                actionId: action.id.uuidString, targetDate: LifeOSDate.string(tomorrow),
                targetTime: action.scheduledTime, changeReason: "오늘 완료하지 못해 내일로 이동"
            )).execute()
            await load()
        } catch { errorMessage = "활동을 내일로 옮기지 못했습니다." }
    }

    var scheduledActions: [TodayAction] {
        actions.filter { $0.scheduledDate == today }.sorted {
            if $0.scheduledTime == nil { return false }
            if $1.scheduledTime == nil { return true }
            return $0.scheduledTime! < $1.scheduledTime!
        }
    }

    var unscheduledActions: [TodayAction] { actions.filter { $0.scheduledDate == nil } }
    var plannedMinutes: Int { scheduledActions.reduce(0) { $0 + $1.estimatedMinutes } }

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
