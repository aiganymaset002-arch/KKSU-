//
//  KKSUCabinets.swift
//  KKSU Online
//
//  Кабинеты: ученик (5), эксперт/наставник (8), психолог (роль из задачи 4),
//  партнёр (94), администратор (9) и управление пользователями/ролями (2–4).
//  Кабинеты родителя и педагога — в ParentHomeView.swift и TeacherHomeView.swift.
//

import SwiftUI

// MARK: - Приветствие

struct CabinetHeader: View {
    @EnvironmentObject private var store: KKSUStore
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            KAvatar(name: store.currentUser?.fullName ?? "", size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("Здравствуйте, \(store.currentUser?.firstName ?? "")!").font(.title2.bold())
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink(value: KKSURoute.notifications) {
                Image(systemName: store.unreadCount > 0 ? "bell.badge.fill" : "bell")
                    .font(.title3)
            }
            .accessibilityLabel("Уведомления: \(store.unreadCount) непрочитанных")
        }
    }
}

// MARK: - Кабинет ученика (задача 5)

struct StudentCabinetView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.kksuAccessibility) private var a11y

    var body: some View {
        let me = store.currentUser?.role == .student ? store.currentUser?.id : store.visibleStudents.first?.id
        KPage("Кабинет ученика") {
            CabinetHeader(subtitle: "Учись в своём темпе")
            if let me {
                let analysis = ProgressAnalyzer.analyze(me, db: store.db, store: store)
                KCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Мой прогресс").font(.headline)
                            Text(analysis.risk == .low ? "Ты отлично справляешься!" : "Давай подтянем пару тем вместе")
                                .font(.callout).foregroundStyle(.secondary)
                            if let xp = store.profile(for: me)?.xp {
                                KBadge(text: "\(xp) XP", color: KKSUTheme.accent)
                            }
                        }
                        Spacer()
                        ProgressCircle(progress: analysis.overall)
                    }
                    NavigationLink("Подробный дашборд", value: KKSURoute.progressDashboard)
                }

                KSectionHeader(title: "Сегодня", icon: "sun.max.fill")
                let today = store.db.sessions.filter { Calendar.current.isDateInToday($0.start) && $0.participantIDs.contains(me) }.sorted { $0.start < $1.start }
                if today.isEmpty {
                    KEmptyState(text: "Сегодня занятий нет", icon: "cup.and.saucer")
                } else {
                    ForEach(today) { SessionCard(session: $0) }
                }

                KSectionHeader(title: "Ближайшие дедлайны", icon: "clock.badge.exclamationmark")
                let upcoming = store.assignments(for: me).filter { $0.dueDate > Date() && store.submission(for: $0.id, studentID: me) == nil }.prefix(3)
                if upcoming.isEmpty {
                    KEmptyState(text: "Все задания сданы 🎉", icon: "checkmark.circle")
                } else {
                    ForEach(Array(upcoming)) { assignment in
                        NavigationLink { AssignmentDetailView(assignment: assignment, studentID: me) } label: {
                            DeadlineRow(assignment: assignment)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !a11y.simplifiedInterface {
                    KSectionHeader(title: "Рекомендуем", icon: "hand.thumbsup.fill")
                    ForEach(RecommendationEngine.recommendations(for: me, store: store).prefix(3)) { rec in
                        RecommendationRow(recommendation: rec)
                    }
                }

                KCard {
                    Label("AI-помощник KKSU", systemImage: "sparkles").font(.headline).foregroundStyle(.tint)
                    Text("Спроси, как решить задачу, или попроси объяснить тему простыми словами.").font(.callout)
                    NavigationLink(value: KKSURoute.aiAssistant) {
                        Text("Открыть помощника").fontWeight(.semibold)
                    }
                }
            }
            KSectionHeader(title: "Быстрый доступ", icon: "square.grid.2x2")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: a11y.simplifiedInterface ? 200 : 140), spacing: 10)], spacing: 10) {
                ForEach([KKSURoute.homework, .schedule, .tests, .trajectory, .portfolio, .inventions, .videoLibrary, .achievements], id: \.self) {
                    RouteTile(route: $0)
                }
            }
        }
    }
}

struct DeadlineRow: View {
    let assignment: Assignment

    var body: some View {
        let hours = assignment.dueDate.timeIntervalSinceNow / 3600
        let color: Color = hours < 0 ? KKSUTheme.danger : (hours < 48 ? KKSUTheme.warning : KKSUTheme.success)
        KCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title).font(.headline)
                    Text(assignment.subject).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    KBadge(text: hours < 0 ? "Просрочено" : assignment.dueDate.formatted(.relative(presentation: .named)), color: color)
                    Text(assignment.dueDate.kksuDateTime).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Кабинет эксперта / наставника (задача 8)

struct ExpertCabinetView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        let myReviews = store.db.reviews.filter { $0.expertID == me }
        let pendingYI = store.db.yiApplications.filter { app in app.status == .submitted || app.status == .underReview }
            .filter { app in !store.db.reviews.contains { $0.targetID == app.id && $0.expertID == me } }
        let pendingMethods = store.db.methodologies.filter { m in m.status == .piloting || m.status == .reviewed }
            .filter { m in !store.db.reviews.contains { $0.targetID == m.id && $0.expertID == me } }
        let mentored = store.db.projects.filter { $0.mentorID == me }

        KPage(store.role == .mentor ? "Кабинет наставника" : "Кабинет эксперта") {
            CabinetHeader(subtitle: store.role.title)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Заявок Young Inventors на экспертизу", value: "\(pendingYI.count)", icon: "sparkles", color: KKSUTheme.accent)
                KStatTile(title: "Методик на экспертизу", value: "\(pendingMethods.count)", icon: "lightbulb.2.fill")
                KStatTile(title: "Проектов под наставничеством", value: "\(mentored.count)", icon: "figure.2.and.child.holdinghands", color: KKSUTheme.success)
                KStatTile(title: "Выполнено экспертиз", value: "\(myReviews.count)", icon: "checkmark.seal.fill", color: .purple)
            }
            KSectionHeader(title: "Очередь экспертизы", icon: "tray.full.fill")
            RouteRow(route: .yiReview, subtitle: "\(pendingYI.count) заявок ожидают оценки")
            RouteRow(route: .methodologyReview, subtitle: "\(pendingMethods.count) методик ожидают оценки")

            KSectionHeader(title: "Мои проекты", icon: "lightbulb.fill")
            if mentored.isEmpty {
                KEmptyState(text: "Вы пока не назначены наставником проектов.", icon: "person.crop.circle.badge.questionmark")
            }
            ForEach(mentored) { project in
                NavigationLink { ProjectDetailView(projectID: project.id) } label: { ProjectCard(project: project) }
                    .buttonStyle(.plain)
            }
            KSectionHeader(title: "Подопечные", icon: "person.3.fill")
            ForEach(store.visibleStudents) { student in
                NavigationLink { StudentOverviewView(studentID: student.id) } label: {
                    StudentRow(studentID: student.id)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Кабинет психолога

struct PsychologistCabinetView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Кабинет психолога") {
            CabinetHeader(subtitle: "Психолого-педагогическое сопровождение")
            Text("Доступ к данным ученика открывается только при наличии согласия родителя на сопровождение психолога.")
                .font(.footnote).foregroundStyle(.secondary)
            ForEach(store.students) { student in
                let consent = store.db.consents.first { $0.studentID == student.id && $0.type == .psychologist }
                let allowed = consent?.granted ?? false
                KCard {
                    HStack {
                        StudentRow(studentID: student.id)
                        Spacer()
                        KBadge(text: allowed ? "Согласие есть" : "Нет согласия", color: allowed ? KKSUTheme.success : KKSUTheme.danger)
                    }
                    if allowed {
                        PsychologistNotesEditor(studentID: student.id)
                        NavigationLink("Анализ прогресса и рисков") { StudentOverviewView(studentID: student.id) }
                    }
                }
            }
        }
    }
}

struct PsychologistNotesEditor: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        if let index = store.db.studentProfiles.firstIndex(where: { $0.userID == studentID }) {
            let questionnaire = store.db.questionnaires.first { $0.studentID == studentID }
            if let questionnaire {
                KInfoRow(label: "Трудности (анкета)", value: questionnaire.difficulties.isEmpty ? "—" : questionnaire.difficulties)
                KInfoRow(label: "Коммуникация", value: questionnaire.communication.isEmpty ? "—" : questionnaire.communication)
            }
            KInfoRow(label: "Особые потребности", value: store.db.studentProfiles[index].specialNeeds.isEmpty ? "—" : store.db.studentProfiles[index].specialNeeds)
            TextField("Рекомендации по сопровождению", text: $store.db.studentProfiles[index].supportNotes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Кабинет организации-партнёра (задача 94)

struct PartnerCabinetView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showNewInternship = false

    var body: some View {
        let partnerID = store.currentUser?.partnerID ?? store.db.partners.first?.id
        KPage("Кабинет партнёра") {
            CabinetHeader(subtitle: store.partner(partnerID)?.name ?? "Организация-партнёр")
            if let partnerID, let pIndex = store.db.partners.firstIndex(where: { $0.id == partnerID }) {
                KCard {
                    Text("Профиль организации").font(.headline)
                    TextField("Название", text: $store.db.partners[pIndex].name).textFieldStyle(.roundedBorder)
                    TextField("Описание", text: $store.db.partners[pIndex].summary, axis: .vertical).textFieldStyle(.roundedBorder)
                    TextField("Сайт", text: $store.db.partners[pIndex].website).textFieldStyle(.roundedBorder)
                    TextField("Email для связи", text: $store.db.partners[pIndex].email).textFieldStyle(.roundedBorder)
                }
                let internships = store.db.internships.filter { $0.partnerID == partnerID }
                let apps = store.db.internshipApplications.filter { app in internships.contains { $0.id == app.internshipID } }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    KStatTile(title: "Стажировок", value: "\(internships.count)", icon: "briefcase.fill")
                    KStatTile(title: "Заявок учеников", value: "\(apps.count)", icon: "person.crop.rectangle.stack", color: KKSUTheme.accent)
                    KStatTile(title: "Принято", value: "\(apps.filter { $0.status == .accepted || $0.status == .completed }.count)", icon: "checkmark.circle.fill", color: KKSUTheme.success)
                    KStatTile(title: "Кейсов", value: "\(store.db.challenges.filter { $0.company == store.partner(partnerID)?.name }.count)", icon: "gearshape.2.fill", color: .purple)
                }
                HStack {
                    KSectionHeader(title: "Стажировки", icon: "briefcase.fill")
                    Button { showNewInternship = true } label: { Label("Добавить", systemImage: "plus") }
                }
                ForEach(internships) { internship in
                    InternshipCard(internship: internship)
                }
                KSectionHeader(title: "Заявки на стажировки", icon: "tray.full.fill")
                if apps.isEmpty { KEmptyState(text: "Заявок пока нет") }
                ForEach(apps) { app in
                    InternshipApplicationReviewRow(applicationID: app.id)
                }
            }
            RouteRow(route: .impactDashboard, subtitle: "Вклад партнёров в показатели KKSU")
            RouteRow(route: .events)
        }
        .sheet(isPresented: $showNewInternship) {
            if let partnerID {
                NavigationStack { InternshipEditorView(partnerID: partnerID) }
            }
        }
    }
}

// MARK: - Административная панель (задача 9)

struct AdminPanelView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let m = ImpactMetrics(db: store.db)
        let pendingApps = store.db.applications.filter { $0.status == .submitted || $0.status == .review }
        let pendingAI = store.db.assignments.filter { $0.isAIGenerated && !$0.approvedByTeacher }
        KPage("Административная панель") {
            CabinetHeader(subtitle: "Управление платформой KKSU Online")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Пользователей", value: "\(store.db.users.count)", icon: "person.3.fill")
                KStatTile(title: "Учеников", value: "\(m.students)", icon: "graduationcap.fill", color: KKSUTheme.success)
                KStatTile(title: "Новых заявок", value: "\(pendingApps.count)", icon: "doc.text.fill", color: KKSUTheme.accent)
                KStatTile(title: "AI-заданий на проверке", value: "\(pendingAI.count)", icon: "sparkles", color: .purple)
            }
            KSectionHeader(title: "Заявки на обучение", icon: "doc.text.fill")
            if pendingApps.isEmpty { KEmptyState(text: "Новых заявок нет") }
            ForEach(pendingApps) { app in
                ApplicationReviewCard(applicationID: app.id)
            }
            KSectionHeader(title: "Управление", icon: "gearshape.2.fill")
            KCard {
                RouteRow(route: .users, subtitle: "Роли, блокировка, привязка детей")
                Divider()
                RouteRow(route: .analytics, subtitle: "Единая аналитика KKSU")
                Divider()
                RouteRow(route: .impactReport, subtitle: "Сформировать отчёт в PDF")
                Divider()
                RouteRow(route: .programs, subtitle: "Каталог программ")
                Divider()
                RouteRow(route: .partners, subtitle: "Партнёры и стажировки")
                Divider()
                RouteRow(route: .events, subtitle: "Мероприятия и сертификаты")
                Divider()
                RouteRow(route: .featureMap, subtitle: "Статус 100 модулей")
            }
        }
    }
}

struct ApplicationReviewCard: View {
    @EnvironmentObject private var store: KKSUStore
    let applicationID: UUID

    var body: some View {
        if let index = store.db.applications.firstIndex(where: { $0.id == applicationID }) {
            let app = store.db.applications[index]
            KCard {
                HStack {
                    Text(app.childName).font(.headline)
                    Spacer()
                    KBadge(text: app.status.title, color: KKSUTheme.accent)
                }
                Text("\(app.childAge) лет · \(store.program(app.programID)?.title ?? "Программа не выбрана") · \(app.format.title)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Родитель: \(app.parentName), \(app.email), \(app.phone)").font(.caption)
                if !app.comment.isEmpty { Text(app.comment).font(.callout) }
                Picker("Статус", selection: $store.db.applications[index].status) {
                    ForEach(ApplicationStatus.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .onChange(of: store.db.applications[index].status) { _, status in
                    if let user = app.applicantUserID {
                        store.notify(user, "Статус заявки: \(status.title)", app.childName, kind: .system)
                    }
                }
            }
        }
    }
}

// MARK: - Пользователи и роли (задачи 2–4)

struct UserManagementView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var query = ""
    @State private var roleFilter: KKSURole?

    var body: some View {
        List {
            Section {
                Picker("Роль", selection: $roleFilter) {
                    Text("Все роли").tag(KKSURole?.none)
                    ForEach(KKSURole.allCases) { Text($0.title).tag(KKSURole?.some($0)) }
                }
            }
            ForEach(KKSURole.allCases.filter { roleFilter == nil || $0 == roleFilter }) { role in
                let users = store.db.users.filter { $0.role == role && (query.isEmpty || $0.fullName.localizedCaseInsensitiveContains(query) || $0.email.localizedCaseInsensitiveContains(query)) }
                if !users.isEmpty {
                    Section("\(role.title) · \(users.count)") {
                        ForEach(users) { user in
                            NavigationLink { UserEditorView(userID: user.id) } label: {
                                HStack {
                                    KAvatar(name: user.fullName, size: 34)
                                    VStack(alignment: .leading) {
                                        Text(user.fullName)
                                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if user.isBlocked { Image(systemName: "lock.fill").foregroundStyle(KKSUTheme.danger) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Имя или email")
        .navigationTitle("Пользователи и роли")
    }
}

struct UserEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    let userID: UUID

    var body: some View {
        if let index = store.db.users.firstIndex(where: { $0.id == userID }) {
            Form {
                Section("Данные") {
                    TextField("ФИО", text: $store.db.users[index].fullName)
                    TextField("Email", text: $store.db.users[index].email)
                    TextField("Телефон", text: $store.db.users[index].phone)
                    KInfoRow(label: "Зарегистрирован", value: store.db.users[index].createdAt.kksuShort)
                    KInfoRow(label: "Последний вход", value: store.db.users[index].lastLogin?.kksuDateTime ?? "—")
                }
                Section("Роль и доступ") {
                    Picker("Роль", selection: $store.db.users[index].role) {
                        ForEach(KKSURole.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .disabled(store.db.users[index].id == store.currentUser?.id)
                    Toggle("Заблокирован", isOn: $store.db.users[index].isBlocked)
                        .disabled(store.db.users[index].id == store.currentUser?.id)
                }
                let role = store.db.users[index].role
                if role == .parent || role == .mentor {
                    Section(role == .parent ? "Дети" : "Подопечные") {
                        ForEach(store.students) { student in
                            Toggle(student.fullName, isOn: Binding(
                                get: { store.db.users[index].linkedStudentIDs.contains(student.id) },
                                set: { on in
                                    if on { store.db.users[index].linkedStudentIDs.append(student.id) }
                                    else { store.db.users[index].linkedStudentIDs.removeAll { $0 == student.id } }
                                }))
                        }
                    }
                }
                if role == .partner {
                    Section("Организация") {
                        Picker("Партнёр", selection: $store.db.users[index].partnerID) {
                            Text("—").tag(UUID?.none)
                            ForEach(store.db.partners) { Text($0.name).tag(UUID?.some($0.id)) }
                        }
                    }
                }
                if role == .student && store.profile(for: userID) == nil {
                    Button("Создать профиль ученика") { store.db.studentProfiles.append(StudentProfile(userID: userID)) }
                }
            }
            .navigationTitle(store.db.users[index].fullName)
        }
    }
}

// MARK: - Общие элементы для списков учеников

struct StudentRow: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        let analysis = ProgressAnalyzer.analyze(studentID, db: store.db, store: store)
        HStack(spacing: 12) {
            KAvatar(name: store.userName(studentID), size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.userName(studentID)).font(.headline)
                Text("Класс \(store.profile(for: studentID)?.grade ?? "—") · прогресс \(Int(analysis.overall * 100))%")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            KBadge(text: analysis.risk.title, color: analysis.risk.color)
        }
        .contentShape(Rectangle())
    }
}

/// Обзор ученика для родителя, педагога, психолога, наставника.
struct StudentOverviewView: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        KPage(store.userName(studentID)) {
            StudentRow(studentID: studentID)
            ProgressDashboardContent(studentID: studentID)
            KSectionHeader(title: "Работы", icon: "tray.full")
            ForEach(store.db.submissions.filter { $0.studentID == studentID }.sorted { $0.submittedAt > $1.submittedAt }) { sub in
                SubmissionSummaryRow(submission: sub)
            }
            KSectionHeader(title: "Связь", icon: "bubble.left")
            if let teacher = store.users(with: .teacher).first, store.currentUser?.role != .teacher {
                NavigationLink { ChatThreadView(otherID: teacher.id) } label: {
                    Label("Написать педагогу (\(teacher.fullName))", systemImage: "bubble.left.and.bubble.right")
                }
            } else {
                NavigationLink { ChatThreadView(otherID: studentID) } label: {
                    Label("Написать ученику", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
    }
}
