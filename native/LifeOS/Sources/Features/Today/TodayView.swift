import Supabase
import SwiftUI

struct TodayView: View {
    @StateObject private var store: TodayStore
    @State private var energyLevel = "MEDIUM"
    @State private var dayMode = "NORMAL"
    @State private var note = ""
    @State private var restReason = ""
    @State private var availableMinutes = 120

    init(client: SupabaseClient) {
        _store = StateObject(wrappedValue: TodayStore(client: client))
    }

    var body: some View {
        Form {
            Section("오늘 · \(store.today)") {
                Text("권장 핵심 행동 \(recommendedRange.min)~\(recommendedRange.max)개")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("에너지", selection: $energyLevel) {
                    Text("낮음").tag("LOW")
                    Text("보통").tag("MEDIUM")
                    Text("높음").tag("HIGH")
                }
                Picker("오늘 모드", selection: $dayMode) {
                    Text("일반").tag("NORMAL")
                    Text("휴식").tag("REST")
                    Text("회복").tag("RECOVERY")
                    Text("이동/여행").tag("TRAVEL")
                    Text("바쁨").tag("BUSY")
                }
                TextField("하루 메모", text: $note, axis: .vertical)
                TextField("휴식 또는 회복을 선택한 이유", text: $restReason, axis: .vertical)
                Stepper("오늘 가능한 시간 \(availableMinutes)분", value: $availableMinutes, in: 0...720, step: 15)
                Button(store.isSaving ? "저장 중" : "오늘 계획 저장") {
                    Task { await store.savePlan(energyLevel: energyLevel, dayMode: dayMode, note: note, restReason: restReason, availableMinutes: availableMinutes) }
                }
                .disabled(store.isSaving)
                if dayMode == "REST" || dayMode == "RECOVERY" {
                    Label("오늘은 회복을 선택한 날입니다. 쉬는 것도 계획의 일부입니다.", systemImage: "moon.stars")
                        .foregroundStyle(.secondary)
                }
            }

            if store.plannedMinutes > availableMinutes {
                Section {
                    Label("오늘 계획이 가능한 시간보다 \(store.plannedMinutes - availableMinutes)분 많습니다. 일부 활동을 옮겨도 괜찮습니다.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("오늘의 시간표") {
                ForEach(store.events) { event in
                    VStack(alignment: .leading) {
                        Text(event.title).font(.headline)
                        Text(event.isAllDay ? "종일 일정" : LifeOSDate.timeLabel(event.startTime)).font(.caption).foregroundStyle(.secondary)
                    }
                }
                ForEach(store.scheduledActions.filter { $0.scheduledTime != nil }) { action in
                    TodayPlannedActionRow(store: store, action: action)
                }
                if store.events.isEmpty && store.scheduledActions.allSatisfy({ $0.scheduledTime == nil }) {
                    Text("시간이 정해진 일정이나 활동이 없습니다.").foregroundStyle(.secondary)
                }
            }

            Section("오늘 중 완료") {
                ForEach(store.scheduledActions.filter { $0.scheduledTime == nil }) { action in
                    TodayPlannedActionRow(store: store, action: action)
                }
                if store.scheduledActions.allSatisfy({ $0.scheduledTime != nil }) { Text("시간 미정 활동이 없습니다.").foregroundStyle(.secondary) }
            }

            Section("오늘에 배치할 활동") {
                ForEach(store.unscheduledActions) { action in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(action.title).font(.headline)
                        Text("\(action.estimatedMinutes)분").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Button("오늘로") { Task { await store.addToToday(action: action, makeCore: false) } }
                            Button("핵심으로") { Task { await store.addToToday(action: action, makeCore: true) } }
                            Button("완료") { Task { await store.complete(action: action) } }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                if store.unscheduledActions.isEmpty && !store.isLoading {
                    Text("선택할 활동이 없습니다. 프로젝트에서 활동을 추가해 보세요.")
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage = store.errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Today")
        .task {
            await store.load()
            energyLevel = store.plan?.energyLevel ?? "MEDIUM"
            dayMode = store.plan?.dayMode ?? "NORMAL"
            note = store.plan?.note ?? ""
            restReason = store.plan?.restReason ?? ""
            availableMinutes = store.plan?.availableMinutes ?? 120
        }
        .refreshable { await store.load() }
    }

    private var recommendedRange: (min: Int, max: Int) {
        switch energyLevel {
        case "LOW": return (0, 1)
        case "HIGH": return (1, 3)
        default: return (1, 2)
        }
    }
}

private struct TodayPlannedActionRow: View {
    @ObservedObject var store: TodayStore
    let action: TodayAction
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(action.title).font(.headline)
            Text("\(LifeOSDate.timeLabel(action.scheduledTime)) · \(action.estimatedMinutes)분").font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("완료") { Task { await store.complete(action: action) } }
                Button("내일로") { Task { await store.moveToTomorrow(action: action) } }
            }.buttonStyle(.bordered)
        }
    }
}
