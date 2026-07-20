import Foundation
import Supabase

private struct HealthCheckInMutation: Encodable {
    let userId: String
    let checkInDate: String
    let weightKg: Double?
    let steps: Int?
    let briskWalkStatus: String
    let plannedSnackDone: Bool?
    let unplannedSnack: Bool
    let dinnerOvereating: Bool
    let freeMeal: Bool
    let alcohol: Bool
    let exerciseCompletion: String
    let sleepHours: Double?
    let conditionLevel: String?
    let stressLevel: String?
    let lowEnergyMode: Bool
    let note: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case checkInDate = "check_in_date"
        case weightKg = "weight_kg"
        case steps
        case briskWalkStatus = "brisk_walk_status"
        case plannedSnackDone = "planned_snack_done"
        case unplannedSnack = "unplanned_snack"
        case dinnerOvereating = "dinner_overeating"
        case freeMeal = "free_meal"
        case alcohol
        case exerciseCompletion = "exercise_completion"
        case sleepHours = "sleep_hours"
        case conditionLevel = "condition_level"
        case stressLevel = "stress_level"
        case lowEnergyMode = "low_energy_mode"
        case note
    }
}
struct HealthProfileMutation: Encodable {
    let userId: String
    let heightCm: Double?
    let birthYear: Int?
    let currentWeightKg: Double
    let targetWeightKg: Double
    let goalDescription: String?
    let activityLevel: String?
    let usualWeighInTime: String?
    let weeklyLossRateKg: Double
    let weekdayBriskWalkMinutes: Int
    let lowEnergyWalkMinutes: Int
    let snackReminderEnabled: Bool
    let snackReminderTime: String
    let snackWeekdays: [Int]
    let defaultSnackName: String
    let defaultSnackNote: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case heightCm = "height_cm"
        case birthYear = "birth_year"
        case currentWeightKg = "current_weight_kg"
        case targetWeightKg = "target_weight_kg"
        case goalDescription = "goal_description"
        case activityLevel = "activity_level"
        case usualWeighInTime = "usual_weigh_in_time"
        case weeklyLossRateKg = "weekly_loss_rate_kg"
        case weekdayBriskWalkMinutes = "weekday_brisk_walk_minutes"
        case lowEnergyWalkMinutes = "low_energy_walk_minutes"
        case snackReminderEnabled = "snack_reminder_enabled"
        case snackReminderTime = "snack_reminder_time"
        case snackWeekdays = "snack_weekdays"
        case defaultSnackName = "default_snack_name"
        case defaultSnackNote = "default_snack_note"
    }
}

struct HealthGoalMutation: Encodable {
    let userId: String
    let targetWeightKg: Double
    let goalName: String
    let sortOrder: Int
    let achieved: Bool
    let achievedDate: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case targetWeightKg = "target_weight_kg"
        case goalName = "goal_name"
        case sortOrder = "sort_order"
        case achieved
        case achievedDate = "achieved_date"
    }
}

@MainActor
final class HealthStore: ObservableObject {
    @Published private(set) var profile: HealthProfile?
    @Published private(set) var checkIns: [HealthCheckIn] = []
    @Published private(set) var goals: [HealthWeightGoal] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let client: SupabaseClient
    let today: String

    init(client: SupabaseClient) {
        self.client = client
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        today = formatter.string(from: Date())
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let profiles: [HealthProfile] = client.from("health_profiles")
                .select("height_cm,birth_year,current_weight_kg,target_weight_kg,goal_description,activity_level,usual_weigh_in_time,weekly_loss_rate_kg,weekday_brisk_walk_minutes,low_energy_walk_minutes,snack_reminder_enabled,snack_reminder_time,snack_weekdays,default_snack_name,default_snack_note")
                .limit(1).execute().value
            async let rows: [HealthCheckIn] = client.from("health_check_ins")
                .select("id,check_in_date,weight_kg,steps,brisk_walk_status,planned_snack_done,unplanned_snack,dinner_overeating,free_meal,alcohol,exercise_completion,sleep_hours,condition_level,stress_level,low_energy_mode,note")
                .order("check_in_date", ascending: false).limit(30).execute().value
            async let goalRows: [HealthWeightGoal] = client.from("health_weight_goals")
                .select("id,target_weight_kg,goal_name,sort_order,achieved,achieved_date")
                .order("sort_order", ascending: true).execute().value
            profile = try await profiles.first
            checkIns = try await rows
            goals = try await goalRows
        } catch {
            errorMessage = "건강 데이터를 불러오지 못했습니다: \(error.localizedDescription)"
        }
    }

    func saveCheckIn(
        weight: Double?, steps: Int?, sleep: Double?, walk: String,
        plannedSnackDone: Bool?, exercise: String, condition: String?, stress: String?,
        unplannedSnack: Bool, dinnerOvereating: Bool, freeMeal: Bool, alcohol: Bool,
        lowEnergyMode: Bool, note: String
    ) async -> Bool {
        await mutate {
            let session = try await self.client.auth.session
            let row = HealthCheckInMutation(
                userId: session.user.id.uuidString, checkInDate: self.today,
                weightKg: weight, steps: steps, briskWalkStatus: walk,
                plannedSnackDone: plannedSnackDone, unplannedSnack: unplannedSnack,
                dinnerOvereating: dinnerOvereating, freeMeal: freeMeal, alcohol: alcohol,
                exerciseCompletion: exercise, sleepHours: sleep, conditionLevel: condition,
                stressLevel: stress, lowEnergyMode: lowEnergyMode,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            )
            try await self.client.from("health_check_ins")
                .upsert(row, onConflict: "user_id,check_in_date").execute()
        }
    }

    func saveProfile(_ mutation: HealthProfileMutation) async -> Bool {
        guard mutation.currentWeightKg > 0, mutation.targetWeightKg > 0 else {
            errorMessage = "현재 체중과 목표 체중을 확인해 주세요."
            return false
        }
        return await mutate {
            try await self.client.from("health_profiles")
                .upsert(mutation, onConflict: "user_id").execute()
        }
    }

    func saveGoal(item: HealthWeightGoal?, mutation: HealthGoalMutation) async -> Bool {
        guard mutation.targetWeightKg > 0,
              !mutation.goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "목표 이름과 체중을 확인해 주세요."
            return false
        }
        return await mutate {
            if let item {
                try await self.client.from("health_weight_goals").update(mutation)
                    .eq("id", value: item.id.uuidString).execute()
            } else {
                try await self.client.from("health_weight_goals").insert(mutation).execute()
            }
        }
    }

    func deleteGoal(_ goal: HealthWeightGoal) async -> Bool {
        await mutate {
            try await self.client.from("health_weight_goals").delete()
                .eq("id", value: goal.id.uuidString).execute()
        }
    }

    func userId() async throws -> String {
        try await client.auth.session.user.id.uuidString
    }

    var adherence: [HealthAdherence] {
        let calendar = koreaCalendar
        let formatter = dateFormatter
        guard let start = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: Date())) else { return [] }
        let recent = checkIns.filter { row in
            guard let date = formatter.date(from: row.checkInDate) else { return false }
            return date >= start
        }
        let snackWeekdays = profile?.snackWeekdays ?? [1, 2, 3, 4, 5]
        var values: [String: (String, Int, Int)] = [
            "weight": ("체중 기록", 0, 0),
            "steps": ("걸음 수 기록", 0, 0),
            "briskWalk": ("빠르게 걷기", 0, 0),
            "plannedSnack": ("계획된 간식", 0, 0),
            "dinner": ("저녁 과식 방지", 0, 0),
            "weekendStrength": ("주말 근력운동", 0, 0)
        ]
        func add(_ key: String, done: Bool) {
            guard let value = values[key] else { return }
            values[key] = (value.0, value.1 + (done ? 1 : 0), value.2 + 1)
        }
        for row in recent {
            guard let date = formatter.date(from: row.checkInDate) else { continue }
            let appleWeekday = calendar.component(.weekday, from: date)
            let webWeekday = appleWeekday - 1
            add("weight", done: row.weightKg != nil)
            add("steps", done: row.steps != nil)
            if (1...5).contains(webWeekday) {
                add("briskWalk", done: ["DONE", "PARTIAL", "ALTERNATIVE"].contains(row.briskWalkStatus))
            }
            if snackWeekdays.contains(webWeekday) {
                add("plannedSnack", done: row.plannedSnackDone == true)
            }
            add("dinner", done: row.dinnerOvereating == false)
            if webWeekday == 0 || webWeekday == 6 {
                add("weekendStrength", done: ["FULL", "MINIMUM", "ALTERNATIVE"].contains(row.exerciseCompletion))
            }
        }
        let order = ["weight", "steps", "briskWalk", "plannedSnack", "dinner", "weekendStrength"]
        return order.compactMap { key in
            guard let value = values[key] else { return nil }
            let rate = value.2 == 0 ? nil : Int((Double(value.1) / Double(value.2) * 100).rounded())
            return HealthAdherence(id: key, label: value.0, done: value.1, planned: value.2, rate: rate)
        }
    }

    var feedback: String {
        let measured = adherence.filter { $0.rate != nil }
        guard let best = measured.max(by: { ($0.rate ?? 0) < ($1.rate ?? 0) }),
              let weakest = measured.min(by: { ($0.rate ?? 0) < ($1.rate ?? 0) }) else {
            return "아직 단정할 만큼 데이터가 충분하지 않습니다. 오늘 기록 하나부터 남겨도 충분합니다."
        }
        let weights = checkIns.filter { $0.weightKg != nil }.sorted { $0.checkInDate < $1.checkInDate }
        let trendText: String
        if weights.count < 4 {
            trendText = "체중 추세는 아직 데이터가 조금 더 필요합니다."
        } else {
            let midpoint = Int(ceil(Double(weights.count) / 2))
            let previous = weights[..<midpoint].compactMap(\.weightKg)
            let recent = weights[midpoint...].compactMap(\.weightKg)
            let difference = recent.reduce(0, +) / Double(recent.count) - previous.reduce(0, +) / Double(previous.count)
            trendText = difference > 0.005 ? "체중 평균은 최근 약간 올라간 흐름입니다." : difference < -0.005 ? "체중 평균은 천천히 내려가는 흐름입니다." : "체중 평균은 대체로 안정적입니다."
        }
        return "최근에는 \(best.label)을 가장 안정적으로 유지했습니다. \(trendText) 다음에는 \(weakest.label) 하나만 우선 조정해보세요. 휴식과 저에너지 모드는 실패가 아니라 계획 조정입니다."
    }

    private var koreaCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = koreaCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private func mutate(_ operation: () async throws -> Void) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await operation()
            await load()
            return true
        } catch {
            errorMessage = "변경사항을 저장하지 못했습니다: \(error.localizedDescription)"
            return false
        }
    }
}
