import XCTest
@testable import LifeOS

final class ProjectModelsTests: XCTestCase {
    func testDecodesHierarchicalAction() throws {
        let parentId = "12d2fe7d-7bb0-4664-b569-2087957f7e76"
        let data = """
        {
          "id": "8f1d92c7-6152-4cd3-babb-04d00a41de45",
          "project_id": "2dc401be-d677-4567-bdc7-b9e5521622ce",
          "parent_action_id": "\(parentId)",
          "title": "첫 하위 행동",
          "description": "30분 안에 끝내기",
          "estimated_minutes": 30,
          "status": "TODO",
          "scheduled_date": null,
          "scheduled_time": null,
          "due_date": null,
          "completed_at": null
        }
        """.data(using: .utf8)!

        let action = try JSONDecoder().decode(ProjectAction.self, from: data)

        XCTAssertEqual(action.parentActionId?.uuidString.lowercased(), parentId)
        XCTAssertEqual(action.estimatedMinutes, 30)
        XCTAssertEqual(action.statusLabel, "할 일")
    }

    func testProgressPercentageRoundsToWholeNumber() {
        let progress = ProjectActionProgress(completed: 2, total: 3)

        XCTAssertEqual(progress.percentage, 67)
        XCTAssertFalse(progress.allCompleted)
    }
}
