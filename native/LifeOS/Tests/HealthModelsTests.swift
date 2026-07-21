import XCTest
@testable import LifeOS

final class HealthModelsTests: XCTestCase {
    func testDecodesCompleteHealthCheckIn() throws {
        let data = """
        {
          "id": "8f1d92c7-6152-4cd3-babb-04d00a41de45",
          "check_in_date": "2026-07-20",
          "weight_kg": 78.4,
          "steps": 8400,
          "brisk_walk_status": "DONE",
          "planned_snack_done": true,
          "unplanned_snack": false,
          "dinner_overeating": false,
          "free_meal": false,
          "alcohol": false,
          "exercise_completion": "MINIMUM",
          "sleep_hours": 7.5,
          "condition_level": "GOOD",
          "stress_level": "LOW",
          "low_energy_mode": false,
          "note": "가볍게 완료"
        }
        """.data(using: .utf8)!

        let checkIn = try JSONDecoder().decode(HealthCheckIn.self, from: data)

        XCTAssertEqual(checkIn.checkInDate, "2026-07-20")
        XCTAssertEqual(checkIn.weightKg, 78.4)
        XCTAssertEqual(checkIn.steps, 8400)
        XCTAssertEqual(checkIn.plannedSnackDone, true)
        XCTAssertEqual(checkIn.exerciseCompletion, "MINIMUM")
    }

    func testDecodesHealthProfileArraysAndDefaults() throws {
        let data = """
        {
          "height_cm": 175.0,
          "birth_year": 1990,
          "current_weight_kg": 78.4,
          "target_weight_kg": 70.0,
          "goal_description": "천천히 감량",
          "activity_level": "LIGHT",
          "usual_weigh_in_time": "MORNING",
          "weekly_loss_rate_kg": 0.5,
          "weekday_brisk_walk_minutes": 20,
          "low_energy_walk_minutes": 5,
          "snack_reminder_enabled": true,
          "snack_reminder_time": "17:30:00",
          "snack_weekdays": [1, 2, 3, 4, 5],
          "default_snack_name": "퇴근 전 간식",
          "default_snack_note": null
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(HealthProfile.self, from: data)

        XCTAssertEqual(profile.snackWeekdays, [1, 2, 3, 4, 5])
        XCTAssertEqual(profile.weekdayBriskWalkMinutes, 20)
        XCTAssertEqual(profile.defaultSnackName, "퇴근 전 간식")
    }
}
