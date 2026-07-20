import Supabase
import SwiftUI

struct HealthView: View {
    private enum Page: String, CaseIterable, Identifiable {
        case today = "오늘"
        case weight = "체중"
        case report = "리포트"
        case workout = "운동"
        case settings = "설정"
        var id: Self { self }
    }

    @StateObject private var store: HealthStore
    @State private var page: Page = .today
    @State private var editingGoal: HealthWeightGoal?
    @State private var isCreatingGoal = false
    @State private var isEditingProfile = false
    @State private var didPopulateToday = false
    @State private var weight = ""
    @State private var steps = ""
    @State private var sleep = ""
    @State private var walk = "UNRECORDED"
    @State private var plannedSnack = ""
    @State private var exercise = "NOT_DONE"
    @State private var condition = ""
    @State private var stress = ""
    @State private var unplannedSnack = false
    @State private var dinnerOvereating = false
    @State private var freeMeal = false
    @State private var alcohol = false
    @State private var lowEnergyMode = false
    @State private var note = ""

    init(client: SupabaseClient) {
        _store = StateObject(wrappedValue: HealthStore(client: client))
    }

    var body: some View {
        VStack(spacing: 0) {
            pagePicker
            Group {
                switch page {
                case .today: todayView
                case .weight: weightView
                case .report: reportView
                case .workout: workoutView
                case .settings: settingsView
                }
            }
        }
        .navigationTitle("건강")
        .task {
            await store.load()
            populateTodayIfNeeded()
        }
        .refreshable {
            await store.load()
            populateTodayIfNeeded(force: true)
        }
        .sheet(isPresented: $isCreatingGoal) {
            NavigationStack { HealthGoalEditor(store: store) }
        }
        .sheet(item: $editingGoal) { goal in
            NavigationStack { HealthGoalEditor(store: store, item: goal) }
        }
        .sheet(isPresented: $isEditingProfile) {
            NavigationStack { HealthProfileEditor(store: store) }
        }
    }

    private var pagePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Page.allCases) { item in
                    Button(item.rawValue) { page = item }
                        .buttonStyle(.borderedProminent)
                        .tint(page == item ? .accentColor : .gray.opacity(0.35))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var todayView: some View {
        Form {
            if let profile = store.profile {
                Section("오늘 · \(store.today)") {
                    LabeledContent("예정 간식", value: "\(profile.defaultSnackName) · \(String(profile.snackReminderTime.prefix(5)))")
                    LabeledContent("평일 빠르게 걷기", value: "\(profile.weekdayBriskWalkMinutes)분")
                    LabeledContent("저에너지 모드", value: "\(profile.lowEnergyWalkMinutes)분")
                }
            } else {
                Section {
                    Text("현재 체중과 목표 체중을 먼저 설정하면 체크인을 시작할 수 있습니다.")
                    Button("건강 프로필 만들기") { isEditingProfile = true }
                }
            }
            Section("30초 체크인") {
                TextField("오늘 체중 kg", text: $weight)
                TextField("걸음 수", text: $steps)
                TextField("수면 시간", text: $sleep)
                Picker("빠르게 걷기", selection: $walk) {
                    Text("미기록").tag("UNRECORDED")
                    Text("완료").tag("DONE")
                    Text("부분 완료").tag("PARTIAL")
                    Text("대체 활동").tag("ALTERNATIVE")
                    Text("휴식").tag("REST")
                }
                Picker("계획된 간식", selection: $plannedSnack) {
                    Text("미기록").tag("")
                    Text("실행").tag("true")
                    Text("미실행").tag("false")
                }
                Picker("운동 완료 형태", selection: $exercise) {
                    Text("미실행").tag("NOT_DONE")
                    Text("전체 운동").tag("FULL")
                    Text("최소 운동").tag("MINIMUM")
                    Text("대체 운동").tag("ALTERNATIVE")
                    Text("휴식").tag("REST")
                }
                Picker("컨디션", selection: $condition) {
                    Text("미기록").tag("")
                    Text("매우 낮음").tag("VERY_LOW")
                    Text("낮음").tag("LOW")
                    Text("보통").tag("NORMAL")
                    Text("좋음").tag("GOOD")
                    Text("매우 좋음").tag("VERY_GOOD")
                }
                Picker("스트레스", selection: $stress) {
                    Text("미기록").tag("")
                    Text("낮음").tag("LOW")
                    Text("보통").tag("NORMAL")
                    Text("높음").tag("HIGH")
                }
            }
            Section("상태") {
                Toggle("계획 밖 간식", isOn: $unplannedSnack)
                Toggle("저녁 과식", isOn: $dinnerOvereating)
                Toggle("자유식", isOn: $freeMeal)
                Toggle("음주", isOn: $alcohol)
                Toggle("저에너지 모드", isOn: $lowEnergyMode)
                TextField("짧은 메모", text: $note, axis: .vertical)
            }
            Section {
                Button(store.isSaving ? "저장 중" : "체크인 저장") {
                    Task {
                        _ = await store.saveCheckIn(
                            weight: Double(weight), steps: Int(steps), sleep: Double(sleep), walk: walk,
                            plannedSnackDone: plannedSnack.isEmpty ? nil : plannedSnack == "true",
                            exercise: exercise, condition: condition.isEmpty ? nil : condition,
                            stress: stress.isEmpty ? nil : stress, unplannedSnack: unplannedSnack,
                            dinnerOvereating: dinnerOvereating, freeMeal: freeMeal, alcohol: alcohol,
                            lowEnergyMode: lowEnergyMode, note: note
                        )
                    }
                }
                .disabled(store.isSaving || store.profile == nil)
            }
            errorSection
        }
    }

    private var weightView: some View {
        List {
            if let profile = store.profile {
                Section("체중 흐름") {
                    LabeledContent("현재 체중", value: "\(format(profile.currentWeightKg)) kg")
                    LabeledContent("최종 목표", value: "\(format(profile.targetWeightKg)) kg")
                    LabeledContent("최근 기록", value: store.checkIns.compactMap(\.weightKg).first.map { "\(format($0)) kg" } ?? "-")
                }
            }
            Section("단계별 목표 체중") {
                ForEach(store.goals) { goal in
                    Button { editingGoal = goal } label: {
                        HStack {
                            Image(systemName: goal.achieved ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading) {
                                Text(goal.goalName)
                                Text("\(format(goal.targetWeightKg)) kg · 순서 \(goal.sortOrder)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let date = goal.achievedDate { Text(date).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Button("목표 추가", systemImage: "plus") { isCreatingGoal = true }
            }
            Section("최근 체중 기록") {
                ForEach(store.checkIns.filter { $0.weightKg != nil }.prefix(14)) { row in
                    LabeledContent(row.checkInDate, value: "\(format(row.weightKg!)) kg")
                }
            }
            errorSection
        }
    }

    private var reportView: some View {
        List {
            Section("이번 주 피드백") { Text(store.feedback) }
            Section("최근 14일 행동 유지율") {
                ForEach(store.adherence) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.label).font(.headline)
                            Spacer()
                            Text(item.rate.map { "\($0)%" } ?? "데이터 없음").font(.headline)
                        }
                        ProgressView(value: Double(item.rate ?? 0), total: 100)
                        Text("완료 \(item.done) / 계획 기록일 \(item.planned)").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            errorSection
        }
    }

    private var workoutView: some View {
        List {
            workoutSection("주말 운동 A 루틴", items: [
                "의자 스쿼트 10회 x 3세트", "벽 또는 높은 지지대 푸시업 8회 x 3세트",
                "글루트 브리지 12회 x 3세트", "버드독 좌우 각 8회 x 2세트", "제자리 걷기 5분"
            ])
            workoutSection("A 최소 버전", items: ["의자 스쿼트 10회", "벽 푸시업 8회", "글루트 브리지 10회", "제자리 걷기 3분"])
            workoutSection("주말 운동 B 루틴", items: [
                "스텝업 또는 낮은 계단 오르기 좌우 각 8회 x 3세트", "힙 힌지 10회 x 3세트",
                "밴드 또는 수건 로우 10회 x 3세트", "무릎을 댄 플랭크 15~20초 x 3세트", "가벼운 전신 스트레칭 5분"
            ])
            workoutSection("B 최소 버전", items: ["스텝업 좌우 각 5회", "힙 힌지 10회", "버드독 좌우 각 5회", "스트레칭 3분"])
            Section("대체 동작과 안전") {
                Text("스텝업이 부담되면 제자리 무릎 들기나 낮은 턱 오르내리기로 바꿉니다.")
                Text("로우가 어렵다면 가슴을 펴고 팔꿈치를 뒤로 당기는 동작으로 대체합니다.")
                Text("플랭크가 불편하면 벽을 짚은 기울어진 플랭크로 바꿉니다.")
                Label("통증이 생기면 운동을 중단하고 무리하지 마세요.", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var settingsView: some View {
        List {
            if let profile = store.profile {
                Section("다이어트 프로필") {
                    LabeledContent("현재 체중", value: "\(format(profile.currentWeightKg)) kg")
                    LabeledContent("최종 목표", value: "\(format(profile.targetWeightKg)) kg")
                    if let height = profile.heightCm { LabeledContent("키", value: "\(format(height)) cm") }
                    if let description = profile.goalDescription { Text(description).foregroundStyle(.secondary) }
                }
                Section("빠르게 걷기와 간식") {
                    LabeledContent("평일 걷기", value: "\(profile.weekdayBriskWalkMinutes)분")
                    LabeledContent("저에너지 걷기", value: "\(profile.lowEnergyWalkMinutes)분")
                    LabeledContent("기본 간식", value: profile.defaultSnackName)
                    LabeledContent("알림 시간", value: String(profile.snackReminderTime.prefix(5)))
                }
            } else {
                ContentUnavailableView("건강 프로필이 없습니다", systemImage: "heart.text.square")
            }
            Section { Button(store.profile == nil ? "프로필 만들기" : "건강 설정 수정") { isEditingProfile = true } }
            errorSection
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = store.errorMessage { Section { Text(error).foregroundStyle(.red) } }
    }

    private func workoutSection(_ title: String, items: [String]) -> some View {
        Section(title) { ForEach(Array(items.enumerated()), id: \.offset) { index, item in Text("\(index + 1). \(item)") } }
    }

    private func populateTodayIfNeeded(force: Bool = false) {
        guard force || !didPopulateToday else { return }
        didPopulateToday = true
        guard let today = store.checkIns.first(where: { $0.checkInDate == store.today }) else { return }
        weight = today.weightKg.map { String($0) } ?? ""
        steps = today.steps.map { String($0) } ?? ""
        sleep = today.sleepHours.map { String($0) } ?? ""
        walk = today.briskWalkStatus
        plannedSnack = today.plannedSnackDone.map { $0 ? "true" : "false" } ?? ""
        exercise = today.exerciseCompletion
        condition = today.conditionLevel ?? ""
        stress = today.stressLevel ?? ""
        unplannedSnack = today.unplannedSnack ?? false
        dinnerOvereating = today.dinnerOvereating ?? false
        freeMeal = today.freeMeal ?? false
        alcohol = today.alcohol ?? false
        lowEnergyMode = today.lowEnergyMode
        note = today.note ?? ""
    }

    private func format(_ value: Double) -> String { String(format: "%.1f", value) }
}

private struct HealthGoalEditor: View {
    @ObservedObject var store: HealthStore
    let item: HealthWeightGoal?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var weight: String
    @State private var order: Int
    @State private var achieved: Bool
    @State private var achievedDate: Date
    @State private var confirmDelete = false

    init(store: HealthStore, item: HealthWeightGoal? = nil) {
        self.store = store
        self.item = item
        _name = State(initialValue: item?.goalName ?? "")
        _weight = State(initialValue: item.map { String($0.targetWeightKg) } ?? "")
        _order = State(initialValue: item?.sortOrder ?? store.goals.count + 1)
        _achieved = State(initialValue: item?.achieved ?? false)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        _achievedDate = State(initialValue: item?.achievedDate.flatMap(formatter.date(from:)) ?? Date())
    }

    var body: some View {
        Form {
            TextField("목표 이름", text: $name)
            TextField("목표 체중 kg", text: $weight)
            Stepper("순서 \(order)", value: $order, in: 0...100)
            Toggle("달성", isOn: $achieved)
            if achieved { DatePicker("달성 일자", selection: $achievedDate, displayedComponents: .date) }
            if item != nil { Button("목표 삭제", role: .destructive) { confirmDelete = true } }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(item == nil ? "체중 목표 추가" : "체중 목표 수정")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        guard let userId = try? await store.userId() else { return }
                        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
                        let mutation = HealthGoalMutation(
                            userId: userId, targetWeightKg: Double(weight) ?? 0,
                            goalName: name, sortOrder: order, achieved: achieved,
                            achievedDate: achieved ? formatter.string(from: achievedDate) : nil
                        )
                        if await store.saveGoal(item: item, mutation: mutation) { dismiss() }
                    }
                }.disabled(store.isSaving)
            }
        }
        .alert("체중 목표를 삭제할까요?", isPresented: $confirmDelete) {
            Button("삭제", role: .destructive) { Task { if await store.deleteGoal(item!) { dismiss() } } }
        }
    }
}

private struct HealthProfileEditor: View {
    @ObservedObject var store: HealthStore
    @Environment(\.dismiss) private var dismiss
    @State private var height: String
    @State private var birthYear: String
    @State private var currentWeight: String
    @State private var targetWeight: String
    @State private var goalDescription: String
    @State private var activityLevel: String
    @State private var weighInTime: String
    @State private var weeklyLoss: String
    @State private var weekdayWalk: Int
    @State private var lowEnergyWalk: Int
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var snackWeekdays: Set<Int>
    @State private var snackName: String
    @State private var snackNote: String

    init(store: HealthStore) {
        self.store = store
        let profile = store.profile
        _height = State(initialValue: profile?.heightCm.map { String($0) } ?? "")
        _birthYear = State(initialValue: profile?.birthYear.map { String($0) } ?? "")
        _currentWeight = State(initialValue: profile.map { String($0.currentWeightKg) } ?? "")
        _targetWeight = State(initialValue: profile.map { String($0.targetWeightKg) } ?? "")
        _goalDescription = State(initialValue: profile?.goalDescription ?? "")
        _activityLevel = State(initialValue: profile?.activityLevel ?? "")
        _weighInTime = State(initialValue: profile?.usualWeighInTime ?? "")
        _weeklyLoss = State(initialValue: profile.map { String($0.weeklyLossRateKg) } ?? "0.5")
        _weekdayWalk = State(initialValue: profile?.weekdayBriskWalkMinutes ?? 20)
        _lowEnergyWalk = State(initialValue: profile?.lowEnergyWalkMinutes ?? 5)
        _reminderEnabled = State(initialValue: profile?.snackReminderEnabled ?? true)
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "HH:mm:ss"
        _reminderTime = State(initialValue: profile.flatMap { timeFormatter.date(from: $0.snackReminderTime) } ?? Date())
        _snackWeekdays = State(initialValue: Set(profile?.snackWeekdays ?? [1, 2, 3, 4, 5]))
        _snackName = State(initialValue: profile?.defaultSnackName ?? "퇴근 전 계획된 간식")
        _snackNote = State(initialValue: profile?.defaultSnackNote ?? "")
    }

    var body: some View {
        Form {
            Section("다이어트 프로필") {
                TextField("현재 체중 kg *", text: $currentWeight)
                TextField("최종 목표 체중 kg *", text: $targetWeight)
                TextField("키 cm", text: $height)
                TextField("출생연도", text: $birthYear)
                TextField("목표 설명", text: $goalDescription, axis: .vertical)
                Picker("활동 수준", selection: $activityLevel) {
                    Text("선택 안 함").tag(""); Text("낮음").tag("LOW"); Text("가벼움").tag("LIGHT"); Text("보통").tag("MODERATE"); Text("높음").tag("HIGH")
                }
                Picker("평소 측정 시간", selection: $weighInTime) {
                    Text("선택 안 함").tag(""); Text("아침").tag("MORNING"); Text("퇴근 후").tag("AFTER_WORK"); Text("저녁").tag("EVENING"); Text("자기 전").tag("BEFORE_SLEEP"); Text("기타").tag("OTHER")
                }
                TextField("주간 권장 감량 kg", text: $weeklyLoss)
            }
            Section("빠르게 걷기") {
                Stepper("평일 목표 \(weekdayWalk)분", value: $weekdayWalk, in: 1...180)
                Stepper("저에너지 목표 \(lowEnergyWalk)분", value: $lowEnergyWalk, in: 1...60)
            }
            Section("계획된 간식") {
                Toggle("알림 사용", isOn: $reminderEnabled)
                DatePicker("알림 시간", selection: $reminderTime, displayedComponents: .hourAndMinute)
                TextField("기본 간식 이름", text: $snackName)
                TextField("예상 섭취량 또는 메모", text: $snackNote)
                HStack {
                    ForEach([(1, "월"), (2, "화"), (3, "수"), (4, "목"), (5, "금"), (6, "토"), (0, "일")], id: \.0) { value, label in
                        Button(label) {
                            if snackWeekdays.contains(value) { snackWeekdays.remove(value) } else { snackWeekdays.insert(value) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(snackWeekdays.contains(value) ? .accentColor : .gray.opacity(0.35))
                    }
                }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("건강 설정")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        guard let userId = try? await store.userId() else { return }
                        let formatter = DateFormatter(); formatter.dateFormat = "HH:mm:ss"
                        let mutation = HealthProfileMutation(
                            userId: userId, heightCm: Double(height), birthYear: Int(birthYear),
                            currentWeightKg: Double(currentWeight) ?? 0, targetWeightKg: Double(targetWeight) ?? 0,
                            goalDescription: goalDescription.isEmpty ? nil : goalDescription,
                            activityLevel: activityLevel.isEmpty ? nil : activityLevel,
                            usualWeighInTime: weighInTime.isEmpty ? nil : weighInTime,
                            weeklyLossRateKg: Double(weeklyLoss) ?? 0.5,
                            weekdayBriskWalkMinutes: weekdayWalk, lowEnergyWalkMinutes: lowEnergyWalk,
                            snackReminderEnabled: reminderEnabled, snackReminderTime: formatter.string(from: reminderTime),
                            snackWeekdays: snackWeekdays.sorted(), defaultSnackName: snackName,
                            defaultSnackNote: snackNote.isEmpty ? nil : snackNote
                        )
                        if await store.saveProfile(mutation) { dismiss() }
                    }
                }.disabled(store.isSaving)
            }
        }
    }
}
