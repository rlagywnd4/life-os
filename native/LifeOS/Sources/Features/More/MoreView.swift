import Supabase
import SwiftUI

private struct SomedayRow: Codable, Identifiable { let id: UUID; let title: String; let description: String?; let category: String }
private struct HistoryAction: Codable, Identifiable { let id: UUID; let title: String; let status: String }
private struct HistoryPlan: Codable, Identifiable { let id: UUID; let planDate: String; let energyLevel: String; let dayMode: String; enum CodingKeys: String, CodingKey { case id; case planDate = "plan_date"; case energyLevel = "energy_level"; case dayMode = "day_mode" } }
private struct ReviewRow: Codable, Identifiable {
    let id: UUID
    let weekStartDate: String
    let status: String
    let wentWell: String?
    let wasDifficult: String?
    let nextWeekDirection: String?
    enum CodingKeys: String, CodingKey {
        case id, status
        case weekStartDate = "week_start_date"
        case wentWell = "went_well"
        case wasDifficult = "was_difficult"
        case nextWeekDirection = "next_week_direction"
    }
}
private struct WeeklyReviewMutation: Encodable {
    let userId: String
    let weekStartDate: String
    let weekEndDate: String
    let status: String
    let currentStep: Int
    let wentWell: String?
    let wasDifficult: String?
    let nextWeekDirection: String?
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
        case status, currentStep
        case wentWell = "went_well"
        case wasDifficult = "was_difficult"
        case nextWeekDirection = "next_week_direction"
    }
}
private struct ProfileRow: Codable { let displayName: String?; let timezone: String; let maxActiveProjects: Int; let maxCoreActions: Int; let recommendedActionMinutes: Int; enum CodingKeys: String, CodingKey { case displayName = "display_name"; case timezone; case maxActiveProjects = "max_active_projects"; case maxCoreActions = "max_core_actions"; case recommendedActionMinutes = "recommended_action_minutes" } }

@MainActor private final class MoreStore: ObservableObject {
    @Published var someday: [SomedayRow] = []
    @Published var actions: [HistoryAction] = []
    @Published var plans: [HistoryPlan] = []
    @Published var reviews: [ReviewRow] = []
    @Published var activeProjects: [LifeProject] = []
    @Published var inbox: [InboxItem] = []
    @Published var profile: ProfileRow?
    @Published var error: String?
    @Published var isSaving = false
    let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func load() async {
        do {
            async let somedayRows: [SomedayRow] = client.from("someday_items").select("id,title,description,category").order("created_at", ascending: false).execute().value
            async let actionRows: [HistoryAction] = client.from("action_items").select("id,title,status").order("updated_at", ascending: false).limit(30).execute().value
            async let planRows: [HistoryPlan] = client.from("daily_plans").select("id,plan_date,energy_level,day_mode").order("plan_date", ascending: false).limit(14).execute().value
            async let reviewRows: [ReviewRow] = client.from("weekly_reviews").select("id,week_start_date,status,went_well,was_difficult,next_week_direction").order("week_start_date", ascending: false).limit(4).execute().value
            async let projectRows: [LifeProject] = client.from("projects").select("id,title,description,reason,desired_outcome,status,updated_at").eq("status", value: "ACTIVE").execute().value
            async let inboxRows: [InboxItem] = client.from("inbox_items").select("id,title,description,category,status,created_at,updated_at").eq("status", value: "UNREVIEWED").limit(5).execute().value
            async let profiles: [ProfileRow] = client.from("profiles").select("display_name,timezone,max_active_projects,max_core_actions,recommended_action_minutes").limit(1).execute().value
            someday = try await somedayRows; actions = try await actionRows; plans = try await planRows; reviews = try await reviewRows; activeProjects = try await projectRows; inbox = try await inboxRows; profile = try await profiles.first
        } catch { self.error = "기록을 불러오지 못했습니다: \(error.localizedDescription)" }
    }

    func saveCurrentReview(wentWell: String, wasDifficult: String, nextWeekDirection: String) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let session = try await client.auth.session
            let dates = currentWeekDates()
            let mutation = WeeklyReviewMutation(
                userId: session.user.id.uuidString,
                weekStartDate: dates.start, weekEndDate: dates.end,
                status: "IN_PROGRESS", currentStep: 5,
                wentWell: wentWell.isEmpty ? nil : wentWell,
                wasDifficult: wasDifficult.isEmpty ? nil : wasDifficult,
                nextWeekDirection: nextWeekDirection.isEmpty ? nil : nextWeekDirection
            )
            try await client.from("weekly_reviews")
                .upsert(mutation, onConflict: "user_id,week_start_date").execute()
            await load()
            return true
        } catch {
            self.error = "주간 리뷰를 저장하지 못했습니다: \(error.localizedDescription)"
            return false
        }
    }

    func currentReview() -> ReviewRow? {
        let start = currentWeekDates().start
        return reviews.first(where: { $0.weekStartDate == start })
    }

    private func currentWeekDates() -> (start: String, end: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let startOfToday = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysFromMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfToday)!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return (formatter.string(from: start), formatter.string(from: end))
    }
}

struct MoreView: View {
    @StateObject private var store: MoreStore
    init(client: SupabaseClient) { _store = StateObject(wrappedValue: MoreStore(client: client)) }
    var body: some View {
        List {
            NavigationLink("Someday") { SimpleSectionList(title: "Someday", rows: store.someday.map { ($0.title, $0.description ?? $0.category) }) }
            NavigationLink("주간 리뷰") { WeeklyReviewNativeView(store: store) }
            NavigationLink("히스토리") { HistoryNativeView(store: store) }
            NavigationLink("설정") { SettingsNativeView(profile: store.profile) }
            if let error = store.error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("더보기")
        .task { await store.load() }
        .refreshable { await store.load() }
    }
}

private struct SimpleSectionList: View { let title: String; let rows: [(String, String)]; var body: some View { List(rows, id: \.0) { row in VStack(alignment: .leading) { Text(row.0).font(.headline); Text(row.1).font(.caption).foregroundStyle(.secondary) } }.navigationTitle(title) } }
private struct WeeklyReviewNativeView: View {
    @ObservedObject var store: MoreStore
    @State private var wentWell = ""
    @State private var wasDifficult = ""
    @State private var nextWeekDirection = ""
    @State private var didPopulate = false

    var body: some View {
        List {
            Section("5단계") {
                Text("1. Inbox 검토")
                Text("2. 활성 프로젝트 검토")
                Text("3. 완료 행동 확인")
                Text("4. 다음 주 초점")
                Text("5. 회고 작성")
            }
            Section("검토할 Inbox") { ForEach(store.inbox) { Text($0.title) } }
            Section("활성 프로젝트") { ForEach(store.activeProjects) { Text($0.title) } }
            Section("최근 결과") {
                ForEach(Array(store.actions.filter { ["DONE", "SKIPPED"].contains($0.status) }.prefix(8))) { Text($0.title) }
            }
            Section("회고 작성") {
                TextField("잘 된 점", text: $wentWell, axis: .vertical)
                TextField("어려웠던 점", text: $wasDifficult, axis: .vertical)
                TextField("다음 주 방향", text: $nextWeekDirection, axis: .vertical)
                Button(store.isSaving ? "저장 중" : "회고 임시 저장") {
                    Task { _ = await store.saveCurrentReview(wentWell: wentWell, wasDifficult: wasDifficult, nextWeekDirection: nextWeekDirection) }
                }
                .disabled(store.isSaving)
            }
            Section("최근 회고") { ForEach(store.reviews) { Text("\($0.weekStartDate) · \($0.status)") } }
            if let error = store.error { Section { Text(error).foregroundStyle(.red) } }
        }
        .navigationTitle("주간 리뷰")
        .task {
            guard !didPopulate else { return }
            didPopulate = true
            if let review = store.currentReview() {
                wentWell = review.wentWell ?? ""
                wasDifficult = review.wasDifficult ?? ""
                nextWeekDirection = review.nextWeekDirection ?? ""
            }
        }
    }
}
private struct HistoryNativeView: View { @ObservedObject var store: MoreStore; var body: some View { List { Section("최근 행동") { ForEach(store.actions) { Text("\($0.title) · \($0.status)") } }; Section("최근 14일") { ForEach(store.plans) { Text("\($0.planDate) · \($0.energyLevel) · \($0.dayMode)") } }; Section("주간 회고") { ForEach(store.reviews) { Text("\($0.weekStartDate) · \($0.status)") } } }.navigationTitle("히스토리") } }
private struct SettingsNativeView: View { let profile: ProfileRow?; var body: some View { Form { LabeledContent("표시 이름", value: profile?.displayName ?? "-"); LabeledContent("시간대", value: profile?.timezone ?? "Asia/Seoul"); LabeledContent("활성 프로젝트", value: "\(profile?.maxActiveProjects ?? 3)"); LabeledContent("핵심 행동", value: "\(profile?.maxCoreActions ?? 3)"); LabeledContent("권장 활동", value: "\(profile?.recommendedActionMinutes ?? 30)분") }.navigationTitle("설정") } }
