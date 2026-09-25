//
//  KKSUPartnersEventsAnalytics.swift
//  KKSU Online
//
//  Каталог партнёров (93), стажировки (95), заявки учеников на стажировки (96),
//  конференции и мероприятия (97), регистрация (98), сертификаты участников (99),
//  единая административная аналитика KKSU (100).
//

import SwiftUI
import Charts

// MARK: - Каталог партнёров (задача 93)

struct PartnersView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var kind: PartnerKind?
    @State private var showEditor = false

    var body: some View {
        KPage("Партнёры KKSU") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все", selected: kind == nil) { kind = nil }
                    ForEach(PartnerKind.allCases) { item in
                        FilterChip(title: item.title, selected: kind == item) { kind = item }
                    }
                }
            }
            ForEach(store.db.partners.filter { kind == nil || $0.kind == kind }) { partner in
                NavigationLink { PartnerDetailView(partnerID: partner.id) } label: {
                    KCard {
                        HStack {
                            KAvatar(name: partner.name, size: 44)
                            VStack(alignment: .leading) {
                                Text(partner.name).font(.headline)
                                Text("\(partner.kind.title) · \(partner.country) · с \(partner.since.formatted(.dateTime.year()))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if partner.isInternational { Image(systemName: "globe").foregroundStyle(.tint) }
                        }
                        Text(partner.summary).font(.callout).lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
            }
            if store.role == .admin {
                PrimaryButton(title: "Добавить партнёра", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { PartnerEditorView() } }
    }
}

struct PartnerDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let partnerID: UUID

    var body: some View {
        if let partner = store.partner(partnerID) {
            KPage(partner.name) {
                KCard {
                    Text(partner.name).font(.title2.bold())
                    KBadge(text: partner.kind.title)
                    Text(partner.summary)
                    KInfoRow(label: "Страна", value: partner.country)
                    KInfoRow(label: "Партнёр с", value: partner.since.kksuShort)
                    if let url = URL(string: partner.website) { Link(partner.website, destination: url) }
                    if let mail = URL(string: "mailto:\(partner.email)") { Link(partner.email, destination: mail) }
                }
                let internships = store.db.internships.filter { $0.partnerID == partner.id }
                if !internships.isEmpty {
                    KSectionHeader(title: "Стажировки", icon: "briefcase.fill")
                    ForEach(internships) { InternshipCard(internship: $0) }
                }
                let cases = store.db.challenges.filter { $0.company == partner.name }
                if !cases.isEmpty {
                    KSectionHeader(title: "Кейсы", icon: "gearshape.2.fill")
                    ForEach(cases) { ChallengeCard(challenge: $0) }
                }
            }
        }
    }
}

struct PartnerEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var partner = Partner(name: "", kind: .company, country: "Казахстан", summary: "", email: "", website: "https://", since: Date())

    var body: some View {
        Form {
            TextField("Название", text: $partner.name)
            Picker("Тип", selection: $partner.kind) {
                ForEach(PartnerKind.allCases) { Text($0.title).tag($0) }
            }
            TextField("Страна", text: $partner.country)
            TextField("Описание сотрудничества", text: $partner.summary, axis: .vertical)
            TextField("Email", text: $partner.email)
            TextField("Сайт", text: $partner.website)
            DatePicker("Партнёр с", selection: $partner.since, displayedComponents: .date)
        }
        .navigationTitle("Новый партнёр")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    store.db.partners.append(partner)
                    dismiss()
                }
                .disabled(partner.name.isEmpty)
            }
        }
    }
}

// MARK: - Стажировки (задачи 95, 96)

struct InternshipsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        let myApps = store.db.internshipApplications.filter { $0.studentID == me }
        KPage("Стажировки") {
            Text("Стажировки у партнёров KKSU: инженерия, AI, экология. Подайте заявку — партнёр рассмотрит её и пригласит на собеседование.")
                .font(.callout).foregroundStyle(.secondary)
            if !myApps.isEmpty {
                KSectionHeader(title: "Мои заявки", icon: "tray.full.fill")
                ForEach(myApps) { app in
                    KCard {
                        HStack {
                            Text(store.db.internships.first { $0.id == app.internshipID }?.title ?? "").font(.headline)
                            Spacer()
                            KBadge(text: app.status.title, color: app.status == .rejected ? KKSUTheme.danger : KKSUTheme.success)
                        }
                        Text("Подана \(app.date.kksuShort)").font(.caption)
                    }
                }
            }
            KSectionHeader(title: "Открытые стажировки", icon: "briefcase.fill")
            ForEach(store.db.internships.filter(\.isOpen)) { InternshipCard(internship: $0) }
            if store.role == .admin {
                KSectionHeader(title: "Все заявки", icon: "list.bullet")
                ForEach(store.db.internshipApplications) { InternshipApplicationReviewRow(applicationID: $0.id) }
            }
        }
    }
}

struct InternshipCard: View {
    @EnvironmentObject private var store: KKSUStore
    let internship: Internship
    @State private var showApply = false

    var body: some View {
        let me = store.currentUser?.id
        let applied = store.db.internshipApplications.contains { $0.internshipID == internship.id && $0.studentID == me }
        let taken = store.db.internshipApplications.filter { $0.internshipID == internship.id && ($0.status == .accepted || $0.status == .completed) }.count
        KCard {
            HStack {
                Text(internship.title).font(.headline)
                Spacer()
                KBadge(text: internship.isOpen ? "Набор открыт" : "Набор закрыт", color: internship.isOpen ? KKSUTheme.success : .secondary)
            }
            Text(store.partner(internship.partnerID)?.name ?? "").font(.caption).foregroundStyle(.tint)
            Text(internship.summary).font(.callout)
            KInfoRow(label: "Требования", value: internship.requirements)
            KInfoRow(label: "Старт", value: "\(internship.start.kksuShort), \(internship.durationWeeks) нед.")
            KInfoRow(label: "Мест", value: "\(max(internship.seats - taken, 0)) из \(internship.seats)")
            if store.role == .student && internship.isOpen {
                if applied {
                    Label("Заявка подана", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success)
                } else {
                    Button("Подать заявку") { showApply = true }.buttonStyle(.borderedProminent)
                }
            }
            if (store.role == .partner && store.currentUser?.partnerID == internship.partnerID) || store.role == .admin,
               let index = store.db.internships.firstIndex(where: { $0.id == internship.id }) {
                Toggle("Набор открыт", isOn: $store.db.internships[index].isOpen)
            }
        }
        .sheet(isPresented: $showApply) {
            NavigationStack { InternshipApplyView(internship: internship) }
        }
    }
}

struct InternshipApplyView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let internship: Internship
    @State private var motivation = ""

    var body: some View {
        Form {
            Section(internship.title) {
                Text(internship.summary)
                Text("Требования: \(internship.requirements)").font(.caption)
            }
            Section("Мотивационное письмо") {
                TextField("Почему вы хотите пройти эту стажировку?", text: $motivation, axis: .vertical)
                    .lineLimit(4...10)
            }
            Section {
                Text("Партнёр увидит ваше портфолио и проекты.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Заявка на стажировку")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Отправить") {
                    guard let me = store.currentUser?.id else { return }
                    store.db.internshipApplications.append(InternshipApplication(internshipID: internship.id, studentID: me, motivation: motivation))
                    for partnerUser in store.db.users where partnerUser.role == .partner && partnerUser.partnerID == internship.partnerID {
                        store.notify(partnerUser.id, "Новая заявка на стажировку", "\(store.userName(me)) — \(internship.title)", kind: .info)
                    }
                    store.log(me, "Заявка на стажировку", details: internship.title, icon: "briefcase")
                    dismiss()
                }
                .disabled(motivation.count < 20)
            }
        }
    }
}

struct InternshipApplicationReviewRow: View {
    @EnvironmentObject private var store: KKSUStore
    let applicationID: UUID

    var body: some View {
        if let index = store.db.internshipApplications.firstIndex(where: { $0.id == applicationID }) {
            let app = store.db.internshipApplications[index]
            KCard {
                HStack {
                    KAvatar(name: store.userName(app.studentID), size: 36)
                    VStack(alignment: .leading) {
                        Text(store.userName(app.studentID)).font(.headline)
                        Text(store.db.internships.first { $0.id == app.internshipID }?.title ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(app.motivation).font(.callout)
                NavigationLink("Портфолио ученика") {
                    KPage("Портфолио") {
                        ForEach(store.db.portfolio.filter { $0.studentID == app.studentID }) { item in
                            KCard {
                                Text(item.title).font(.headline)
                                Text(item.summary).font(.callout)
                            }
                        }
                        ForEach(store.db.projects.filter { $0.authorIDs.contains(app.studentID) }) { ProjectCard(project: $0) }
                    }
                }
                .font(.caption)
                Picker("Статус", selection: $store.db.internshipApplications[index].status) {
                    ForEach(InternshipStatus.allCases) { Text($0.title).tag($0) }
                }
                .onChange(of: store.db.internshipApplications[index].status) { _, status in
                    let title = store.db.internships.first { $0.id == app.internshipID }?.title ?? ""
                    store.notify(app.studentID, "Стажировка: \(status.title)", title, kind: .info)
                    if status == .completed {
                        store.issueCertificate(to: app.studentID, title: "Стажировка «\(title)»", issuer: .internship)
                    }
                }
            }
        }
    }
}

struct InternshipEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let partnerID: UUID
    @State private var internship = Internship(partnerID: UUID(), title: "", summary: "", requirements: "", start: Date().addingTimeInterval(30 * 86400), durationWeeks: 2, seats: 5)

    var body: some View {
        Form {
            TextField("Название", text: $internship.title)
            TextField("Описание", text: $internship.summary, axis: .vertical)
            TextField("Требования", text: $internship.requirements)
            DatePicker("Начало", selection: $internship.start, displayedComponents: .date)
            Stepper("Недель: \(internship.durationWeeks)", value: $internship.durationWeeks, in: 1...26)
            Stepper("Мест: \(internship.seats)", value: $internship.seats, in: 1...100)
        }
        .navigationTitle("Новая стажировка")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Опубликовать") {
                    internship.partnerID = partnerID
                    store.db.internships.append(internship)
                    for student in store.students {
                        store.notify(student.id, "Новая стажировка", "\(store.partner(partnerID)?.name ?? ""): \(internship.title)", kind: .info)
                    }
                    dismiss()
                }
                .disabled(internship.title.isEmpty)
            }
        }
    }
}

// MARK: - Конференции и мероприятия (задачи 97, 98, 99)

struct EventsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false

    var body: some View {
        let upcoming = store.db.events.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }.sorted { $0.date < $1.date }
        let past = store.db.events.filter { $0.date < Calendar.current.startOfDay(for: Date()) }.sorted { $0.date > $1.date }
        KPage("Конференции и мероприятия") {
            KSectionHeader(title: "Предстоящие", icon: "calendar.badge.plus")
            if upcoming.isEmpty { KEmptyState(text: "Нет запланированных мероприятий", icon: "calendar") }
            ForEach(upcoming) { EventCard(event: $0) }
            KSectionHeader(title: "Прошедшие", icon: "clock.arrow.circlepath")
            ForEach(past) { EventCard(event: $0) }
            if store.role == .admin {
                PrimaryButton(title: "Добавить мероприятие", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { EventEditorView() } }
    }
}

struct EventCard: View {
    @EnvironmentObject private var store: KKSUStore
    let event: KKSUEvent
    @State private var role: EventRole = .listener
    @State private var talk = ""
    @State private var registering = false

    var body: some View {
        let me = store.currentUser?.id
        let registrations = store.db.eventRegistrations.filter { $0.eventID == event.id }
        let mine = registrations.first { $0.userID == me }
        KCard {
            HStack {
                KBadge(text: event.kind.title)
                if event.isInternational { KBadge(text: "Международное", color: .purple) }
                Spacer()
                Text("\(registrations.count)/\(event.capacity)").font(.caption).foregroundStyle(.secondary)
            }
            Text(event.title).font(.headline)
            Text("\(event.date.kksuDateTime) · \(event.location) · \(event.hours) ч").font(.caption).foregroundStyle(.secondary)
            Text(event.summary).font(.callout)
            if event.isOnline, let url = URL(string: event.meetingURL), !event.meetingURL.isEmpty, mine != nil {
                Link(destination: url) { Label("Ссылка на трансляцию", systemImage: "video.fill") }
            }
            if let mine {
                HStack {
                    Label("Вы зарегистрированы: \(mine.role.title)", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success)
                    Spacer()
                }
                if let certID = mine.certificateID, let cert = store.db.certificates.first(where: { $0.id == certID }) {
                    CertificateCard(certificate: cert)
                }
            } else if event.date > Date(), registrations.count < event.capacity, store.currentUser != nil {
                if registering {
                    Picker("Роль", selection: $role) {
                        ForEach(EventRole.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if role == .speaker {
                        TextField("Тема доклада", text: $talk).textFieldStyle(.roundedBorder)
                    }
                    Button("Подтвердить регистрацию") {
                        store.register(eventID: event.id, role: role, talk: talk)
                        registering = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(role == .speaker && talk.isEmpty)
                } else {
                    Button("Зарегистрироваться") { registering = true }.buttonStyle(.borderedProminent)
                }
            }
            if store.role == .admin && !registrations.isEmpty {
                DisclosureGroup("Участники (\(registrations.count))") {
                    ForEach(registrations) { reg in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(store.userName(reg.userID)).font(.callout)
                                Text(reg.role.title + (reg.talkTitle.isEmpty ? "" : ": \(reg.talkTitle)")).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if reg.attended {
                                Label("Сертификат", systemImage: "rosette").font(.caption).foregroundStyle(KKSUTheme.success)
                            } else {
                                Button("Присутствовал") { store.confirmAttendance(registrationID: reg.id) }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    Button("Выдать сертификаты всем участникам") {
                        registrations.filter { !$0.attended }.forEach { store.confirmAttendance(registrationID: $0.id) }
                    }
                    .font(.caption)
                }
            }
        }
    }
}

struct EventEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var event = KKSUEvent(title: "", kind: .conference, date: Date().addingTimeInterval(14 * 86400), location: "KKSU", isOnline: false, summary: "", capacity: 100)

    var body: some View {
        Form {
            TextField("Название", text: $event.title)
            Picker("Тип", selection: $event.kind) {
                ForEach(EventKind.allCases) { Text($0.title).tag($0) }
            }
            DatePicker("Дата и время", selection: $event.date)
            Toggle("Онлайн", isOn: $event.isOnline)
            if event.isOnline {
                TextField("Ссылка на трансляцию", text: $event.meetingURL)
            }
            TextField("Место", text: $event.location)
            Stepper("Мест: \(event.capacity)", value: $event.capacity, in: 5...5000, step: 5)
            Stepper("Часов (в сертификат): \(event.hours)", value: $event.hours, in: 1...72)
            Toggle("Международное", isOn: $event.isInternational)
            TextField("Описание", text: $event.summary, axis: .vertical)
        }
        .navigationTitle("Новое мероприятие")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    if event.isOnline && event.meetingURL.isEmpty {
                        event.meetingURL = "https://meet.jit.si/KKSU-event-\(event.id.uuidString.prefix(8))"
                    }
                    store.db.events.append(event)
                    for user in store.db.users { store.notify(user.id, "Новое мероприятие", event.title, kind: .event) }
                    dismiss()
                }
                .disabled(event.title.isEmpty)
            }
        }
    }
}

// MARK: - Единая административная аналитика KKSU (задача 100)

struct AnalyticsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var days = 30

    private struct DayCount: Identifiable {
        let id = UUID()
        let day: Date
        let count: Int
        let series: String
    }

    var body: some View {
        let db = store.db
        let m = ImpactMetrics(db: db)
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: Date())) ?? Date()
        let activity: [DayCount] = (0...days).compactMap { offset -> [DayCount]? in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let actions = db.history.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            let subs = db.submissions.filter { cal.isDate($0.submittedAt, inSameDayAs: day) }.count
            return [DayCount(day: day, count: actions, series: "Действия"), DayCount(day: day, count: subs, series: "Сданные работы")]
        }.flatMap { $0 }
        let roles = KKSURole.allCases.map { role in (role, db.users.filter { $0.role == role }.count) }.filter { $0.1 > 0 }
        let subjects = subjectAverages(db)
        let appStatuses = ApplicationStatus.allCases.map { status in (status, db.applications.filter { $0.status == status }.count) }
        let aiRequests = db.history.filter { $0.icon == "sparkles" }.count
        let activeUsers = Set(db.users.filter { ($0.lastLogin ?? .distantPast) > start }.map(\.id)).count

        KPage("Аналитика KKSU") {
            Picker("Период", selection: $days) {
                Text("7 дней").tag(7)
                Text("30 дней").tag(30)
                Text("90 дней").tag(90)
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Всего пользователей", value: "\(db.users.count)", icon: "person.3.fill")
                KStatTile(title: "Активных за период", value: "\(activeUsers)", icon: "person.fill.checkmark", color: KKSUTheme.success)
                KStatTile(title: "Заявок на обучение", value: "\(db.applications.count)", icon: "doc.text.fill", color: KKSUTheme.accent)
                KStatTile(title: "Запросов к AI", value: "\(aiRequests)", icon: "sparkles", color: .purple)
                KStatTile(title: "Работ сдано", value: "\(db.submissions.count)", icon: "tray.and.arrow.up.fill")
                KStatTile(title: "Попыток тестов", value: "\(db.attempts.count)", icon: "checklist", color: KKSUTheme.accent)
                KStatTile(title: "Материалов в библиотеке", value: "\(db.library.count)", icon: "books.vertical.fill", color: KKSUTheme.success)
                KStatTile(title: "Сертификатов", value: "\(db.certificates.count)", icon: "rosette", color: .purple)
            }

            KCard {
                Text("Активность платформы").font(.headline)
                Chart(activity) { item in
                    LineMark(x: .value("День", item.day, unit: .day), y: .value("Количество", item.count))
                        .foregroundStyle(by: .value("Показатель", item.series))
                        .interpolationMethod(.monotone)
                }
                .frame(height: 200)
            }
            KCard {
                Text("Пользователи по ролям").font(.headline)
                Chart(roles, id: \.0) { item in
                    BarMark(x: .value("Количество", item.1), y: .value("Роль", item.0.title))
                        .foregroundStyle(KKSUTheme.primary)
                        .annotation(position: .trailing) { Text("\(item.1)").font(.caption2) }
                }
                .frame(height: CGFloat(roles.count) * 30 + 20)
            }
            if !subjects.isEmpty {
                KCard {
                    Text("Средний балл по предметам").font(.headline)
                    Chart(subjects, id: \.subject) { item in
                        BarMark(x: .value("Предмет", item.subject), y: .value("Средний балл, %", item.avg))
                            .foregroundStyle(KKSUTheme.accent)
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 200)
                }
            }
            KCard {
                Text("Воронка приёма").font(.headline)
                Chart(appStatuses, id: \.0) { item in
                    BarMark(x: .value("Статус", item.0.title), y: .value("Заявок", item.1))
                        .foregroundStyle(KKSUTheme.success)
                }
                .frame(height: 160)
            }
            KCard {
                Text("Сводка по направлениям").font(.headline)
                KInfoRow(label: "Проекты / прототипы / результаты", value: "\(m.projects) / \(m.prototypes) / \(m.projectsByStage.last?.1 ?? 0)")
                KInfoRow(label: "Teacher Academy: слушатели / выпускники", value: "\(db.academyProfiles.count) / \(m.academyGraduates)")
                KInfoRow(label: "Методики / апробации", value: "\(db.methodologies.count) / \(db.pilots.count)")
                KInfoRow(label: "Young Inventors: заявки / финалисты", value: "\(m.yiApplications) / \(m.yiFinalists)")
                KInfoRow(label: "Стажировки: заявки / принято", value: "\(m.internshipApplications) / \(m.internshipAccepted)")
                KInfoRow(label: "Мероприятия / участники", value: "\(m.events) / \(m.eventParticipants)")
                KInfoRow(label: "Страны / международные проекты", value: "\(m.countries) / \(m.internationalProjects)")
                KInfoRow(label: "Посещаемость / выполнение заданий", value: "\(Int(m.attendanceRate * 100))% / \(Int(m.completionRate * 100))%")
            }
            KCard {
                Text("Ученики в зоне риска").font(.headline)
                let risky = store.students.map { ProgressAnalyzer.analyze($0.id, db: db, store: store) }.filter { $0.risk != .low }
                if risky.isEmpty { Text("Нет").foregroundStyle(.secondary) }
                ForEach(risky) { a in
                    NavigationLink { StudentOverviewView(studentID: a.studentID) } label: { StudentRow(studentID: a.studentID) }
                        .buttonStyle(.plain)
                }
            }
            if let url = exportCSV(m) {
                ShareLink(item: url) { Label("Экспорт сводки в CSV", systemImage: "tablecells") }
            }
            RouteRow(route: .impactDashboard)
            RouteRow(route: .impactReport)
        }
    }

    private func subjectAverages(_ db: KKSUDatabase) -> [(subject: String, avg: Double)] {
        var scores: [String: [Double]] = [:]
        for sub in db.submissions {
            guard let score = sub.score, let a = db.assignments.first(where: { $0.id == sub.assignmentID }) else { continue }
            scores[a.subject, default: []].append(Double(score) / Double(max(a.maxScore, 1)) * 100)
        }
        return scores.map { key, values in (subject: key, avg: values.reduce(0, +) / Double(values.count)) }
            .sorted { $0.subject < $1.subject }
    }

    private func exportCSV(_ m: ImpactMetrics) -> URL? {
        let rows: [(String, String)] = [
            ("Учеников", "\(m.students)"), ("Педагогов", "\(m.teachers)"), ("Проведено занятий", "\(m.lessonsHeld)"),
            ("Проектов", "\(m.projects)"), ("Прототипов", "\(m.prototypes)"), ("Результатов", "\(m.results)"),
            ("Средний балл, %", "\(Int(m.averageScore * 100))"), ("Выполнение заданий, %", "\(Int(m.completionRate * 100))"),
            ("Посещаемость, %", "\(Int(m.attendanceRate * 100))"), ("Сертификатов", "\(m.certificates)"),
            ("Партнёров", "\(m.partners)"), ("Стажировок", "\(m.internships)"), ("Стран", "\(m.countries)"),
            ("Международных проектов", "\(m.internationalProjects)"), ("Мероприятий", "\(m.events)")
        ]
        let csv = "Показатель;Значение\n" + rows.map { "\($0.0);\($0.1)" }.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KKSU-analytics.csv")
        return (try? csv.data(using: .utf8)?.write(to: url)) != nil ? url : nil
    }
}
