import XCTest
@testable import LifeOS

final class CalendarModelsTests: XCTestCase {
    func testDecodesScheduledActionAndDueDate() throws {
        let data = """
        {
          "id": "8f1d92c7-6152-4cd3-babb-04d00a41de45",
          "project_id": "2dc401be-d677-4567-bdc7-b9e5521622ce",
          "title": "지도학습 개념 학습",
          "estimated_minutes": 40,
          "status": "PLANNED",
          "scheduled_date": "2026-07-21",
          "scheduled_time": "21:10:00",
          "due_date": "2026-07-27"
        }
        """.data(using: .utf8)!

        let action = try JSONDecoder().decode(CalendarAction.self, from: data)
        XCTAssertEqual(action.scheduledDate, "2026-07-21")
        XCTAssertEqual(action.scheduledTime, "21:10:00")
        XCTAssertEqual(action.dueDate, "2026-07-27")
        XCTAssertEqual(LifeOSDate.timeLabel(action.scheduledTime), "오후 9:10")
    }

    func testDayLoadCountsOnlyIncompletePlannedMinutes() {
        let projectId = UUID()
        let actions = [
            CalendarAction(id: UUID(), projectId: projectId, title: "학습", estimatedMinutes: 40, status: "PLANNED", scheduledDate: "2026-07-21", scheduledTime: nil, dueDate: nil),
            CalendarAction(id: UUID(), projectId: projectId, title: "완료", estimatedMinutes: 30, status: "DONE", scheduledDate: "2026-07-21", scheduledTime: nil, dueDate: nil)
        ]
        let load = CalendarDayLoad(actions: actions, events: [], dueActions: [], availableMinutes: 30)
        XCTAssertEqual(load.plannedMinutes, 40)
        XCTAssertEqual(load.overloadMinutes, 10)
    }
}
