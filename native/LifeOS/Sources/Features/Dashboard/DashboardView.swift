import Foundation
import Supabase
import SwiftUI

private struct DashboardProfile: Codable {
    let displayName: String
    let maxActiveProjects: Int
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case maxActiveProjects = "max_active_projects"
    }
}
private struct DashboardID: Codable { let id: UUID }
private struct DashboardPlan: Codable {
    let energyLevel: String
    let dayMode: String
    enum CodingKeys: String, CodingKey {
        case energyLevel = "energy_level"
        case dayMode = "day_mode"
    }
}
private struct DashboardInboxMutation: Encodable {
    let title: String
    let category: String
}

@MainActor
private final class DashboardStore: ObservableObject {
    @Published var profile: DashboardProfile?
    @Published var inboxCount = 0
    @Published var activeProjectCount = 0
    @Published var completedActionCount = 0
    @Published var plan: DashboardPlan?
    @Published var isSaving = false
    @Published var errorMessage: String?
    let today: String
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        today = formatter.string(from: Date())
    }

    func load() async {
        errorMessage = nil
        do {
            async let profiles: [DashboardProfile] = client.from("profiles")
                .select("display_name,max_active_projects").limit(1).execute().value
            async let inbox: [DashboardID] = client.from("inbox_items")
                .select("id").eq("status", value: "UNREVIEWED").execute().value
            async let projects: [DashboardID] = client.from("projects")
                .select("id").eq("status", value: "ACTIVE").execute().value
            async let completed: [DashboardID] = client.from("action_items")
                .select("id").eq("status", value: "DONE").execute().value
            async let plans: [DashboardPlan] = client.from("daily_plans")
                .select("energy_level,day_mode").eq("plan_date", value: today).limit(1).execute().value
            profile = try await profiles.first
            inboxCount = try await inbox.count
            activeProjectCount = try await projects.count
            completedActionCount = try await completed.count
            plan = try await plans.first
        } catch {
            errorMessage = "대시보드를 불러오지 못했습니다: \(error.localizedDescription)"
        }
    }

    func quickAddInbox(_ title: String) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { errorMessage = "Inbox 제목을 입력해 주세요."; return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await client.from("inbox_items")
                .insert(DashboardInboxMutation(title: title, category: "ETC")).execute()
            await load()
            return true
        } catch {
            errorMessage = "Inbox에 저장하지 못했습니다: \(error.localizedDescription)"
            return false
        }
    }
}

struct DashboardView: View {
    @StateObject private var store: DashboardStore
    private let client: SupabaseClient
    @State private var quickInboxTitle = ""

    init(client: SupabaseClient) {
        self.client = client
        _store = StateObject(wrappedValue: DashboardStore(client: client))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.today).foregroundStyle(.secondary)
                    Text("\(store.profile?.displayName ?? "사용자")님의 LifeOS")
                        .font(.title2.bold())
                }
                .padding(.vertical, 4)
            }

            Section("빠른 Inbox") {
                TextField("떠오른 것을 바로 기록", text: $quickInboxTitle)
                Button(store.isSaving ? "저장 중" : "Inbox에 추가", systemImage: "plus") {
                    Task { if await store.quickAddInbox(quickInboxTitle) { quickInboxTitle = "" } }
                }
                .disabled(store.isSaving)
            }

            Section("현재 상태") {
                DashboardMetric(label: "미검토 Inbox", value: "\(store.inboxCount)", icon: "tray.full")
                DashboardMetric(label: "활성 프로젝트", value: "\(store.activeProjectCount) / \(store.profile?.maxActiveProjects ?? 3)", icon: "folder")
                DashboardMetric(label: "오늘 에너지", value: energyLabel(store.plan?.energyLevel), icon: "bolt")
                DashboardMetric(label: "완료한 작은 행동", value: "\(store.completedActionCount)", icon: "checkmark.circle")
            }

            Section("바로가기") {
                NavigationLink { TodayView(client: client) } label: {
                    Label(store.plan?.dayMode == "REST" || store.plan?.dayMode == "RECOVERY" ? "오늘은 회복하는 날" : "오늘 계획 만들기", systemImage: "sun.max")
                }
                NavigationLink { InboxListView(client: client) } label: { Label("Inbox 정리하기", systemImage: "tray.full") }
                NavigationLink { ProjectsView(client: client) } label: { Label("프로젝트 열기", systemImage: "folder") }
                NavigationLink { MoreView(client: client) } label: { Label("주간 리뷰와 기록", systemImage: "calendar.badge.clock") }
            }

            if let error = store.errorMessage { Section { Text(error).foregroundStyle(.red) } }
        }
        .navigationTitle("홈")
        .task { await store.load() }
        .refreshable { await store.load() }
    }

    private func energyLabel(_ value: String?) -> String {
        ["LOW": "낮음", "MEDIUM": "보통", "HIGH": "높음"][value ?? ""] ?? "미정"
    }
}

private struct DashboardMetric: View {
    let label: String
    let value: String
    let icon: String
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value).font(.headline)
        }
    }
}
