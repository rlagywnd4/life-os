import Foundation

struct HealthProfile: Codable {
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
struct HealthCheckIn: Codable, Identifiable {
    let id: UUID
    let checkInDate: String
    let weightKg: Double?
    let steps: Int?
    let briskWalkStatus: String
    let plannedSnackDone: Bool?
    let unplannedSnack: Bool?
    let dinnerOvereating: Bool?
    let freeMeal: Bool?
    let alcohol: Bool?
    let exerciseCompletion: String
    let sleepHours: Double?
    let conditionLevel: String?
    let stressLevel: String?
    let lowEnergyMode: Bool
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
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

struct HealthWeightGoal: Codable, Identifiable {
    let id: UUID
    let targetWeightKg: Double
    let goalName: String
    let sortOrder: Int
    let achieved: Bool
    let achievedDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case targetWeightKg = "target_weight_kg"
        case goalName = "goal_name"
        case sortOrder = "sort_order"
        case achieved
        case achievedDate = "achieved_date"
    }
}

struct HealthAdherence: Identifiable {
    let id: String
    let label: String
    let done: Int
    let planned: Int
    let rate: Int?
}
