import Foundation

struct InboxItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var categoryLabel: String {
        Self.categoryName(category)
    }

    static func categoryName(_ category: String) -> String {
        categoryLabels[category] ?? category
    }

    var statusLabel: String {
        Self.statusLabels[status] ?? status
    }

    private static let categoryLabels = [
        "SERVICE_IDEA": "서비스 아이디어",
        "STUDY": "공부",
        "CAREER": "커리어",
        "EXERCISE": "운동",
        "CONTENT": "콘텐츠",
        "HOBBY": "취미",
        "LIFE": "생활",
        "TRAVEL": "여행",
        "PURCHASE": "구매",
        "ETC": "기타"
    ]

    private static let statusLabels = [
        "UNREVIEWED": "미검토",
        "CONVERTED_TO_PROJECT": "프로젝트 전환됨",
        "SOMEDAY": "언젠가",
        "DISCARDED": "폐기",
        "ARCHIVED": "보관됨"
    ]
}
