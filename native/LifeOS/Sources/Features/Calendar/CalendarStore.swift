import Foundation
import Supabase

private struct CalendarEventMutation: Encodable {
    let title: String
    let description: String?
    let eventDate: String
    let startTime: String?
    let endTime: String?
    let isAllDay: Bool
    let category: String
    let location: String?

    enum CodingKeys: String, CodingKey {
        case title, description, category, location
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case isAllDay = "is_all_day"
    }
}

private struct RescheduleActionParameters: Encodable {
    let actionId: String
    let targetDate: String
    let targetTime: String?
    let changeReason: String?
    enum CodingKeys: String, CodingKey {
        case actionId = "action_id"
        case targetDate = "target_date"
        case targetTime = "target_time"
        case changeReason = "change_reason"
    }
}

private struct CalendarActionCompletionMutation: Encodable {
    let status: String
    let completedAt: String?
    enum CodingKeys: String, CodingKey { case status; case completedAt = "completed_at" }
}

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var actions: [CalendarAction] = []
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var capacities: [CalendarPlanCapacity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    private let client: SupabaseClient

    init(client: SupabaseClient) { self.client = client }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let actionRows: [CalendarAction] = client.from("action_items")
                .select("id,project_id,title,estimated_minutes,status,scheduled_date,scheduled_time,due_date")
                .order("scheduled_date", ascending: true).execute().value
            async let eventRows: [CalendarEvent] = client.from("calendar_events")
                .select("id,title,description,event_date,start_time,end_time,is_all_day,category,location")
                .order("event_date", ascending: true).order("start_time", ascending: true).execute().value
            async let capacityRows: [CalendarPlanCapacity] = client.from("daily_plans")
                .select("plan_date,available_minutes").execute().value
            actions = try await actionRows
            events = try await eventRows
            capacities = try await capacityRows
        } catch {
            errorMessage = "달력을 불러오지 못했습니다: \(error.localizedDescription)"
        }
    }

    func items(on date: Date) -> CalendarDayLoad {
        let key = LifeOSDate.string(date)
        return CalendarDayLoad(
            actions: actions.filter { $0.scheduledDate == key }.sorted(by: actionSort),
            events: events.filter { $0.eventDate == key }.sorted { ($0.startTime ?? "") < ($1.startTime ?? "") },
            dueActions: actions.filter { $0.dueDate == key && $0.scheduledDate != key },
            availableMinutes: capacities.first(where: { $0.planDate == key })?.availableMinutes
        )
    }

    func saveEvent(id: UUID?, title: String, description: String, date: Date, hasTime: Bool,
                   startTime: Date, hasEndTime: Bool, endTime: Date, category: String, location: String) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { errorMessage = "일정 제목을 입력해 주세요."; return false }
        if hasTime && hasEndTime && endTime <= startTime {
            errorMessage = "종료 시간은 시작 시간보다 늦어야 합니다."
            return false
        }
        let mutation = CalendarEventMutation(
            title: title, description: description.isEmpty ? nil : description,
            eventDate: LifeOSDate.string(date), startTime: hasTime ? LifeOSDate.timeFormatter.string(from: startTime) : nil,
            endTime: hasTime && hasEndTime ? LifeOSDate.timeFormatter.string(from: endTime) : nil,
            isAllDay: !hasTime, category: category, location: location.isEmpty ? nil : location
        )
        return await mutate {
            if let id {
                try await self.client.from("calendar_events").update(mutation).eq("id", value: id.uuidString).execute()
            } else {
                try await self.client.from("calendar_events").insert(mutation).execute()
            }
        }
    }

    func deleteEvent(_ event: CalendarEvent) async -> Bool {
        await mutate { try await self.client.from("calendar_events").delete().eq("id", value: event.id.uuidString).execute() }
    }

    func reschedule(_ action: CalendarAction, to date: Date, hasTime: Bool, time: Date, reason: String) async -> Bool {
        await mutate {
            try await self.client.rpc("reschedule_action", params: RescheduleActionParameters(
                actionId: action.id.uuidString, targetDate: LifeOSDate.string(date),
                targetTime: hasTime ? LifeOSDate.timeFormatter.string(from: time) : nil,
                changeReason: reason.isEmpty ? nil : reason
            )).execute()
        }
    }

    func moveAction(id: UUID, to date: Date) async -> Bool {
        guard let action = actions.first(where: { $0.id == id }) else { return false }
        let existingTime = LifeOSDate.time(action.scheduledTime) ?? Date()
        return await reschedule(action, to: date, hasTime: action.scheduledTime != nil, time: existingTime, reason: "달력에서 이동")
    }

    func toggleCompletion(_ action: CalendarAction) async -> Bool {
        let done = !action.isDone
        return await mutate {
            try await self.client.from("action_items").update(CalendarActionCompletionMutation(
                status: done ? "DONE" : "PLANNED",
                completedAt: done ? ISO8601DateFormatter().string(from: Date()) : nil
            )).eq("id", value: action.id.uuidString).execute()
        }
    }

    private func actionSort(_ lhs: CalendarAction, _ rhs: CalendarAction) -> Bool {
        switch (lhs.scheduledTime, rhs.scheduledTime) {
        case let (left?, right?): return left < right
        case (_?, nil): return true
        case (nil, _?): return false
        default: return lhs.title < rhs.title
        }
    }

    private func mutate(_ operation: () async throws -> Void) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do { try await operation(); await load(); return true }
        catch { errorMessage = "변경사항을 저장하지 못했습니다: \(error.localizedDescription)"; return false }
    }
}
