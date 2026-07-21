import Foundation

enum LifeOSDate {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    static func string(_ date: Date) -> String { dateOnlyFormatter.string(from: date) }
    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        return dateOnlyFormatter.date(from: value)
    }
    static func time(_ value: String?) -> Date? {
        guard let value else { return nil }
        return timeFormatter.date(from: value)
    }
    static func timeLabel(_ value: String?) -> String {
        guard let date = time(value) else { return "시간 미정" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

struct CalendarAction: Codable, Identifiable, Equatable {
    let id: UUID
    let projectId: UUID
    let title: String
    let estimatedMinutes: Int
    let status: String
    let scheduledDate: String?
    let scheduledTime: String?
    let dueDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case projectId = "project_id"
        case estimatedMinutes = "estimated_minutes"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case dueDate = "due_date"
    }

    var isDone: Bool { status == "DONE" }
}

struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let eventDate: String
    let startTime: String?
    let endTime: String?
    let isAllDay: Bool
    let category: String
    let location: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, location
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case isAllDay = "is_all_day"
    }

    var categoryLabel: String {
        ["GENERAL": "일반", "APPOINTMENT": "약속", "TRAVEL": "여행", "MILESTONE": "마일스톤"][category] ?? category
    }
}

struct CalendarDayLoad {
    let actions: [CalendarAction]
    let events: [CalendarEvent]
    let dueActions: [CalendarAction]
    let availableMinutes: Int?
    var plannedMinutes: Int { actions.filter { !$0.isDone }.reduce(0) { $0 + $1.estimatedMinutes } }
    var overloadMinutes: Int { max(0, plannedMinutes - (availableMinutes ?? plannedMinutes)) }
}

struct CalendarPlanCapacity: Codable {
    let planDate: String
    let availableMinutes: Int?
    enum CodingKeys: String, CodingKey { case planDate = "plan_date"; case availableMinutes = "available_minutes" }
}
