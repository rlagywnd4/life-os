import Supabase
import SwiftUI

struct CalendarView: View {
    private enum Mode: String, CaseIterable { case month = "월간"; case week = "주간" }
    @StateObject private var store: CalendarStore
    @State private var mode: Mode = .month
    @State private var selectedDate = Date()
    @State private var visibleDate = Date()
    @State private var isCreatingEvent = false
    @State private var editingEvent: CalendarEvent?
    @State private var movingAction: CalendarAction?

    init(client: SupabaseClient) { _store = StateObject(wrappedValue: CalendarStore(client: client)) }

    var body: some View {
        VStack(spacing: 0) {
            Picker("보기", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if mode == .month {
                    MonthCalendarGrid(store: store, visibleDate: $visibleDate, selectedDate: $selectedDate)
                } else {
                    WeekCalendarGrid(store: store, visibleDate: $visibleDate, selectedDate: $selectedDate)
                }
            }
            .frame(maxHeight: mode == .month ? 430 : 210)

            Divider()
            SelectedDayList(
                store: store, date: selectedDate,
                editEvent: { editingEvent = $0 }, moveAction: { movingAction = $0 }
            )
        }
        .navigationTitle("달력")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("오늘", systemImage: "calendar") { selectedDate = Date(); visibleDate = Date() }
                Button("일정 추가", systemImage: "plus") { isCreatingEvent = true }
            }
        }
        .overlay { if store.isLoading && store.actions.isEmpty { ProgressView() } }
        .task { await store.load() }
        .refreshable { await store.load() }
        .sheet(isPresented: $isCreatingEvent) {
            NavigationStack { CalendarEventEditor(store: store, initialDate: selectedDate) }
        }
        .sheet(item: $editingEvent) { event in
            NavigationStack { CalendarEventEditor(store: store, initialDate: selectedDate, event: event) }
        }
        .sheet(item: $movingAction) { action in
            NavigationStack { ActionRescheduleView(store: store, action: action) }
        }
    }
}

private struct MonthCalendarGrid: View {
    @ObservedObject var store: CalendarStore
    @Binding var visibleDate: Date
    @Binding var selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            CalendarPeriodHeader(title: monthTitle, previous: { shift(-1) }, next: { shift(1) })
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { Text($0).font(.caption.bold()).foregroundStyle(.secondary) }
                ForEach(monthDates, id: \.self) { date in
                    CalendarDayCell(store: store, date: date, isSelected: LifeOSDate.calendar.isDate(date, inSameDayAs: selectedDate),
                                    isInPeriod: LifeOSDate.calendar.isDate(date, equalTo: visibleDate, toGranularity: .month)) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var monthTitle: String { visibleDate.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).year().month(.wide)) }
    private var monthDates: [Date] {
        let calendar = LifeOSDate.calendar
        guard let month = calendar.dateInterval(of: .month, for: visibleDate),
              let gridStart = calendar.dateInterval(of: .weekOfYear, for: month.start)?.start else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }
    private func shift(_ value: Int) { if let date = LifeOSDate.calendar.date(byAdding: .month, value: value, to: visibleDate) { visibleDate = date; selectedDate = date } }
}

private struct WeekCalendarGrid: View {
    @ObservedObject var store: CalendarStore
    @Binding var visibleDate: Date
    @Binding var selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            CalendarPeriodHeader(title: weekTitle, previous: { shift(-1) }, next: { shift(1) })
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(weekDates, id: \.self) { date in
                    CalendarDayCell(store: store, date: date, isSelected: LifeOSDate.calendar.isDate(date, inSameDayAs: selectedDate), isInPeriod: true) { selectedDate = date }
                }
            }
        }
        .padding(.horizontal)
    }

    private var weekDates: [Date] {
        guard let start = LifeOSDate.calendar.dateInterval(of: .weekOfYear, for: visibleDate)?.start else { return [] }
        return (0..<7).compactMap { LifeOSDate.calendar.date(byAdding: .day, value: $0, to: start) }
    }
    private var weekTitle: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(first.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day())) – \(last.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day()))"
    }
    private func shift(_ value: Int) { if let date = LifeOSDate.calendar.date(byAdding: .weekOfYear, value: value, to: visibleDate) { visibleDate = date; selectedDate = date } }
}

private struct CalendarPeriodHeader: View {
    let title: String
    let previous: () -> Void
    let next: () -> Void
    var body: some View {
        HStack {
            Button("이전", systemImage: "chevron.left", action: previous).labelStyle(.iconOnly)
            Spacer()
            Text(title).font(.headline)
            Spacer()
            Button("다음", systemImage: "chevron.right", action: next).labelStyle(.iconOnly)
        }
    }
}

private struct CalendarDayCell: View {
    @ObservedObject var store: CalendarStore
    let date: Date
    let isSelected: Bool
    let isInPeriod: Bool
    let select: () -> Void

    var body: some View {
        let load = store.items(on: date)
        Button(action: select) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.bold()).foregroundStyle(isInPeriod ? .primary : .tertiary)
                HStack(spacing: 3) {
                    if !load.events.isEmpty { Circle().fill(.blue).frame(width: 6, height: 6) }
                    if !load.actions.isEmpty { Circle().fill(.green).frame(width: 6, height: 6) }
                    if !load.dueActions.isEmpty { Circle().fill(.orange).frame(width: 6, height: 6) }
                }
                Text(load.actions.first?.title ?? load.events.first?.title ?? " ")
                    .font(.system(size: 9)).lineLimit(1).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
            .padding(5)
            .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { values, _ in
            guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
            Task { _ = await store.moveAction(id: id, to: date) }
            return true
        }
        .accessibilityLabel("\(LifeOSDate.string(date)), 활동 \(load.actions.count)개, 일정 \(load.events.count)개")
    }
}

private struct SelectedDayList: View {
    @ObservedObject var store: CalendarStore
    let date: Date
    let editEvent: (CalendarEvent) -> Void
    let moveAction: (CalendarAction) -> Void

    var body: some View {
        let load = store.items(on: date)
        List {
            Section {
                LabeledContent("예상 계획", value: "\(load.plannedMinutes)분")
                if load.overloadMinutes > 0 {
                    Label("가능한 시간보다 \(load.overloadMinutes)분 많습니다. 일부를 옮겨도 괜찮습니다.", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            } header: { Text(date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide))) }

            if !load.events.isEmpty {
                Section("일정") {
                    ForEach(load.events) { event in
                        Button { editEvent(event) } label: {
                            CalendarItemLabel(title: event.title, subtitle: event.isAllDay ? "종일 · \(event.categoryLabel)" : "\(LifeOSDate.timeLabel(event.startTime)) · \(event.categoryLabel)", color: .blue)
                        }.buttonStyle(.plain)
                    }
                }
            }
            if !load.actions.isEmpty {
                Section("활동") {
                    ForEach(load.actions) { action in
                        HStack {
                            Button { Task { _ = await store.toggleCompletion(action) } } label: {
                                Image(systemName: action.isDone ? "checkmark.circle.fill" : "circle")
                            }.buttonStyle(.plain)
                            CalendarItemLabel(title: action.title, subtitle: "\(LifeOSDate.timeLabel(action.scheduledTime)) · \(action.estimatedMinutes)분", color: .green)
                                .strikethrough(action.isDone)
                                .draggable(action.id.uuidString)
                            Spacer()
                            Button("이동", systemImage: "calendar.badge.clock") { moveAction(action) }.labelStyle(.iconOnly)
                        }
                    }
                }
            }
            if !load.dueActions.isEmpty {
                Section("마감") {
                    ForEach(load.dueActions) { CalendarItemLabel(title: $0.title, subtitle: "마감일", color: .orange) }
                }
            }
            if load.events.isEmpty && load.actions.isEmpty && load.dueActions.isEmpty && !store.isLoading {
                ContentUnavailableView("배치된 항목이 없습니다", systemImage: "calendar", description: Text("실행하기로 정한 활동과 일정만 여기에 표시됩니다."))
            }
            if let error = store.errorMessage { Section { Text(error).foregroundStyle(.red) } }
        }
    }
}

private struct CalendarItemLabel: View {
    let title: String
    let subtitle: String
    let color: Color
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 4, height: 34)
            VStack(alignment: .leading) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

private struct CalendarEventEditor: View {
    @ObservedObject var store: CalendarStore
    let event: CalendarEvent?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var startTime: Date
    @State private var hasEndTime: Bool
    @State private var endTime: Date
    @State private var category: String
    @State private var location: String

    init(store: CalendarStore, initialDate: Date, event: CalendarEvent? = nil) {
        self.store = store; self.event = event
        _title = State(initialValue: event?.title ?? "")
        _description = State(initialValue: event?.description ?? "")
        _date = State(initialValue: LifeOSDate.date(event?.eventDate) ?? initialDate)
        _hasTime = State(initialValue: event.map { !$0.isAllDay } ?? true)
        _startTime = State(initialValue: LifeOSDate.time(event?.startTime) ?? Date())
        _hasEndTime = State(initialValue: event?.endTime != nil)
        _endTime = State(initialValue: LifeOSDate.time(event?.endTime) ?? Date().addingTimeInterval(3600))
        _category = State(initialValue: event?.category ?? "GENERAL")
        _location = State(initialValue: event?.location ?? "")
    }

    var body: some View {
        Form {
            TextField("일정 제목", text: $title)
            TextField("설명", text: $description, axis: .vertical)
            DatePicker("날짜", selection: $date, displayedComponents: .date)
            Toggle("시간 지정", isOn: $hasTime)
            if hasTime {
                DatePicker("시작", selection: $startTime, displayedComponents: .hourAndMinute)
                Toggle("종료 시간", isOn: $hasEndTime)
                if hasEndTime { DatePicker("종료", selection: $endTime, displayedComponents: .hourAndMinute) }
            }
            Picker("종류", selection: $category) {
                Text("일반").tag("GENERAL"); Text("약속").tag("APPOINTMENT"); Text("여행").tag("TRAVEL"); Text("마일스톤").tag("MILESTONE")
            }
            TextField("장소", text: $location)
            if let event {
                Button("일정 삭제", role: .destructive) { Task { if await store.deleteEvent(event) { dismiss() } } }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(event == nil ? "일정 추가" : "일정 수정")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { Task { if await store.saveEvent(id: event?.id, title: title, description: description, date: date, hasTime: hasTime, startTime: startTime, hasEndTime: hasEndTime, endTime: endTime, category: category, location: location) { dismiss() } } }.disabled(store.isSaving)
            }
        }
    }
}

private struct ActionRescheduleView: View {
    @ObservedObject var store: CalendarStore
    let action: CalendarAction
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var reason = ""

    init(store: CalendarStore, action: CalendarAction) {
        self.store = store; self.action = action
        _date = State(initialValue: LifeOSDate.date(action.scheduledDate) ?? Date())
        _hasTime = State(initialValue: action.scheduledTime != nil)
        _time = State(initialValue: LifeOSDate.time(action.scheduledTime) ?? Date())
    }
    var body: some View {
        Form {
            Text(action.title).font(.headline)
            DatePicker("실행일", selection: $date, displayedComponents: .date)
            Toggle("시간 지정", isOn: $hasTime)
            if hasTime { DatePicker("시작 시간", selection: $time, displayedComponents: .hourAndMinute) }
            TextField("옮기는 이유 (선택)", text: $reason, axis: .vertical)
            Text("실행일만 바뀌며 마감일은 유지됩니다.").font(.caption).foregroundStyle(.secondary)
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("활동 재배치")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("이동") { Task { if await store.reschedule(action, to: date, hasTime: hasTime, time: time, reason: reason) { dismiss() } } }.disabled(store.isSaving) }
        }
    }
}
