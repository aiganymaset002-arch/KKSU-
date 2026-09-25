//
//  LessonsView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Задачи 17, 32, 33: расписание занятий, модуль онлайн-занятий
//  и интеграция видеоконференций (Jitsi — автосоздание комнаты, Zoom, Meet, Teams).
//

import SwiftUI

struct LessonsView: View {
    @EnvironmentObject private var store: KKSUStore
    var onlyOnline = false
    @State private var weekOffset = 0
    @State private var showEditor = false

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = (cal.component(.weekday, from: today) + 5) % 7   // понедельник = 0
        let monday = cal.date(byAdding: .day, value: -weekday + weekOffset * 7, to: today) ?? today
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private func sessions(on day: Date) -> [ScheduleSession] {
        let me = store.currentUser
        return store.db.sessions.filter { session in
            guard Calendar.current.isDate(session.start, inSameDayAs: day) else { return false }
            if onlyOnline && !session.isOnline { return false }
            switch me?.role {
            case .student: return session.participantIDs.contains(me?.id ?? UUID())
            case .parent: return !Set(session.participantIDs).isDisjoint(with: me?.linkedStudentIDs ?? [])
            case .teacher: return session.teacherID == me?.id
            default: return true
            }
        }
        .sorted { $0.start < $1.start }
    }

    var body: some View {
        KPage(onlyOnline ? "Онлайн-занятия" : "Расписание") {
            HStack {
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Предыдущая неделя")
                Spacer()
                Text("\(weekDays.first?.kksuShort ?? "") — \(weekDays.last?.kksuShort ?? "")").font(.headline)
                Spacer()
                Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Следующая неделя")
            }
            if store.role.canTeach {
                PrimaryButton(title: "Запланировать занятие", icon: "plus") { showEditor = true }
            }
            ForEach(weekDays, id: \.self) { day in
                let list = sessions(on: day)
                VStack(alignment: .leading, spacing: 8) {
                    Text(day.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Calendar.current.isDateInToday(day) ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    if list.isEmpty {
                        Text("Нет занятий").font(.caption).foregroundStyle(.tertiary)
                    }
                    ForEach(list) { SessionCard(session: $0) }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { SessionEditorView() }
        }
    }
}

// MARK: - Карточка занятия с подключением к видеоконференции

struct SessionCard: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.openURL) private var openURL
    let session: ScheduleSession

    var body: some View {
        let now = Date()
        let isLive = session.start <= now && session.end >= now
        let startsSoon = session.start > now && session.start.timeIntervalSince(now) < 15 * 60
        KCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title).font(.headline)
                    Text("\(session.subject) · \(store.userName(session.teacherID))").font(.caption).foregroundStyle(.secondary)
                    Text("\(session.start.kksuTime)–\(session.end.kksuTime) · \(session.isOnline ? session.platform.title : (session.room.isEmpty ? "Очно" : session.room))")
                        .font(.caption)
                }
                Spacer()
                if isLive { KBadge(text: "Идёт сейчас", color: KKSUTheme.danger) }
                else if startsSoon { KBadge(text: "Скоро", color: KKSUTheme.warning) }
                else { Image(systemName: session.isOnline ? "video.fill" : "person.3.fill").foregroundStyle(.tint) }
            }
            if session.isOnline, let url = session.joinURL {
                HStack {
                    Button {
                        markAttendance()
                        openURL(url)
                    } label: {
                        Label("Подключиться", systemImage: "video.badge.checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    ShareLink(item: url) { Image(systemName: "link") }
                        .accessibilityLabel("Поделиться ссылкой")
                }
            }
            if !session.recordingURL.isEmpty, let url = URL(string: session.recordingURL) {
                Link(destination: url) { Label("Запись занятия", systemImage: "play.rectangle") }.font(.caption)
            }
            if store.role.canTeach && session.start < now {
                NavigationLink { AttendanceView(sessionID: session.id) } label: {
                    Label("Посещаемость: \(session.attendedIDs.count)/\(session.participantIDs.count)", systemImage: "person.fill.checkmark")
                        .font(.caption)
                }
            }
        }
    }

    private func markAttendance() {
        guard let me = store.currentUser?.id,
              let index = store.db.sessions.firstIndex(where: { $0.id == session.id }),
              store.db.sessions[index].participantIDs.contains(me),
              !store.db.sessions[index].attendedIDs.contains(me) else { return }
        store.db.sessions[index].attendedIDs.append(me)
        store.log(me, "Посещено онлайн-занятие", details: session.title, icon: "video.fill")
    }
}

struct AttendanceView: View {
    @EnvironmentObject private var store: KKSUStore
    let sessionID: UUID

    var body: some View {
        if let index = store.db.sessions.firstIndex(where: { $0.id == sessionID }) {
            Form {
                Section("Отметьте присутствующих") {
                    ForEach(store.db.sessions[index].participantIDs, id: \.self) { studentID in
                        Toggle(store.userName(studentID), isOn: Binding(
                            get: { store.db.sessions[index].attendedIDs.contains(studentID) },
                            set: { on in
                                if on { store.db.sessions[index].attendedIDs.append(studentID) }
                                else { store.db.sessions[index].attendedIDs.removeAll { $0 == studentID } }
                            }))
                    }
                }
                Section("Запись занятия") {
                    TextField("Ссылка на запись", text: $store.db.sessions[index].recordingURL)
                }
            }
            .navigationTitle(store.db.sessions[index].title)
        }
    }
}

struct SessionEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var session = ScheduleSession(title: "", subject: "", start: Date().addingTimeInterval(86400))
    @State private var repeatWeeks = 1

    var body: some View {
        Form {
            Section("Занятие") {
                TextField("Тема", text: $session.title)
                TextField("Предмет", text: $session.subject)
                DatePicker("Начало", selection: $session.start)
                Stepper("Длительность: \(session.durationMinutes) мин", value: $session.durationMinutes, in: 15...180, step: 5)
                Stepper("Повторять недель: \(repeatWeeks)", value: $repeatWeeks, in: 1...36)
            }
            Section("Формат") {
                Toggle("Онлайн", isOn: $session.isOnline)
                if session.isOnline {
                    Picker("Платформа", selection: $session.platform) {
                        ForEach(ConferencePlatform.allCases) { Text($0.title).tag($0) }
                    }
                    if session.platform == .jitsi {
                        Text("Комната Jitsi Meet будет создана автоматически.").font(.caption).foregroundStyle(.secondary)
                    }
                    TextField("Ссылка на конференцию", text: $session.meetingURL)
                        .autocorrectionDisabled()
                } else {
                    TextField("Кабинет", text: $session.room)
                }
            }
            Section("Участники") {
                ForEach(store.students) { student in
                    Toggle(student.fullName, isOn: Binding(
                        get: { session.participantIDs.contains(student.id) },
                        set: { on in
                            if on { session.participantIDs.append(student.id) } else { session.participantIDs.removeAll { $0 == student.id } }
                        }))
                }
            }
        }
        .navigationTitle("Новое занятие")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") { save() }
                    .disabled(session.title.isEmpty || session.participantIDs.isEmpty)
            }
        }
    }

    private func save() {
        session.teacherID = store.currentUser?.id
        for week in 0..<repeatWeeks {
            var copy = session
            copy.id = UUID()
            copy.start = Calendar.current.date(byAdding: .weekOfYear, value: week, to: session.start) ?? session.start
            store.db.sessions.append(copy)
        }
        for student in session.participantIDs {
            store.notify(student, "Новое занятие в расписании", "\(session.title) — \(session.start.kksuDateTime)", kind: .event)
        }
        dismiss()
    }
}
