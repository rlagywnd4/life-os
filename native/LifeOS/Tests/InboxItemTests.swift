import XCTest
@testable import LifeOS

final class InboxItemTests: XCTestCase {
    func testDecodesDatabaseColumnNames() throws {
        let data = """
        {
          "id": "8f1d92c7-6152-4cd3-babb-04d00a41de45",
          "title": "운동 계획 다시 잡기",
          "description": "이번 주말에 가능한 시간을 확인한다.",
          "category": "EXERCISE",
          "status": "UNREVIEWED",
          "created_at": "2026-07-18T00:00:00+00:00",
          "updated_at": "2026-07-18T00:00:00+00:00"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(InboxItem.self, from: data)

        XCTAssertEqual(item.title, "운동 계획 다시 잡기")
        XCTAssertEqual(item.categoryLabel, "운동")
    }

    func testUsesRawCategoryWhenNoKoreanLabelExists() {
        let item = InboxItem(
            id: UUID(),
            title: "확장 카테고리",
            description: nil,
            category: "NEW_CATEGORY",
            status: "UNREVIEWED",
            createdAt: "",
            updatedAt: ""
        )

        XCTAssertEqual(item.categoryLabel, "NEW_CATEGORY")
    }
}
