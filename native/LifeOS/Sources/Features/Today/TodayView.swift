import Supabase
import SwiftUI

struct TodayView: View {
    @StateObject private var store: TodayStore
    @State private var energyLevel = "MEDIUM"
    @State private var dayMode = "NORMAL"
    @State private var note = ""
    @State private var restReason = ""

    init(client: SupabaseClient) {
        _store = StateObject(wrappedValue: TodayStore(client: client))
    }

    var body: some View {
        Form {
            Section("오늘 · \(store.today)") {
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
                Button(store.isSaving ? "저장 중" : "오늘 계획 저장") {
                    Task { await store.savePlan(energyLevel: energyLevel, dayMode: dayMode, note: note, restReason: restReason) }
                }
                .disabled(store.isSaving)
            }

            Section("행동 선택") {
                ForEach(store.actions) { action in
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
                if store.actions.isEmpty && !store.isLoading {
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
        }
        .refreshable { await store.load() }
    }
}
