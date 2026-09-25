//
//  KKSUGlobalAndEngineering.swift
//  KKSU Online
//
//  Global Classroom (60), международные онлайн-классы (61), совместные проекты (62),
//  международные преподаватели и эксперты (63), Future Engineers (64),
//  инженерные онлайн-курсы (65), виртуальные задания (66), кейсы MASHSTROY (67),
//  ARAI AI (68), IKEN (69), ATA MURA (70), Inclusive Engineering (71, 72).
//

import SwiftUI

// MARK: - Global Classroom (задача 60)

struct GlobalClassroomView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let m = ImpactMetrics(db: store.db)
        KPage("Global Classroom") {
            KCard {
                Label("Global Classroom", systemImage: "globe.europe.africa.fill").font(.title2.bold()).foregroundStyle(.tint)
                Text("Международные онлайн-классы, совместные проекты со школами других стран и лекции зарубежных экспертов.")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                KStatTile(title: "Стран", value: "\(m.countries)", icon: "flag.fill")
                KStatTile(title: "Онлайн-классов", value: "\(m.globalClasses)", icon: "video.bubble.fill", color: KKSUTheme.accent)
                KStatTile(title: "Совместных проектов", value: "\(m.internationalProjects)", icon: "globe", color: KKSUTheme.success)
                KStatTile(title: "Экспертов", value: "\(m.internationalExperts)", icon: "person.crop.square.filled.and.at.rectangle", color: .purple)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                RouteTile(route: .globalClasses)
                RouteTile(route: .internationalProjects)
                RouteTile(route: .internationalExperts)
            }
            if !store.db.globalClasses.isEmpty {
                KSectionHeader(title: "Ближайший класс", icon: "calendar")
                if let next = store.db.globalClasses.filter({ $0.start > Date() }).min(by: { $0.start < $1.start }) {
                    GlobalClassCard(globalClass: next)
                }
            }
        }
    }
}

// MARK: - Международные онлайн-классы (задача 61)

struct GlobalClassesView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false

    var body: some View {
        KPage("Международные онлайн-классы") {
            ForEach(store.db.globalClasses.sorted { $0.start < $1.start }) { GlobalClassCard(globalClass: $0) }
            if store.role.canTeach {
                PrimaryButton(title: "Новый международный класс", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { GlobalClassEditorView() } }
    }
}

struct GlobalClassCard: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.openURL) private var openURL
    let globalClass: GlobalClass

    var body: some View {
        let me = store.currentUser?.id
        let joined = me.map { globalClass.participantIDs.contains($0) } ?? false
        let url = URL(string: globalClass.meetingURL.isEmpty ? "https://meet.jit.si/KKSU-Global-\(globalClass.id.uuidString.prefix(8))" : globalClass.meetingURL)
        KCard {
            HStack {
                Text(globalClass.title).font(.headline)
                Spacer()
                KBadge(text: globalClass.country)
            }
            Text("\(globalClass.partnerSchool) · \(globalClass.teacherName) · язык: \(globalClass.language)").font(.caption).foregroundStyle(.secondary)
            Text(globalClass.summary).font(.callout)
            Text(globalClass.start.kksuDateTime).font(.caption)
            HStack {
                if store.role == .student, !joined, let index = store.db.globalClasses.firstIndex(where: { $0.id == globalClass.id }), let me {
                    Button("Записаться") {
                        store.db.globalClasses[index].participantIDs.append(me)
                        store.log(me, "Запись в Global Classroom", details: globalClass.title, icon: "globe")
                    }
                    .buttonStyle(.borderedProminent)
                } else if joined {
                    KBadge(text: "Вы участник", color: KKSUTheme.success)
                }
                Spacer()
                if let url {
                    Button { openURL(url) } label: { Label("Подключиться", systemImage: "video.fill") }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct GlobalClassEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var item = GlobalClass(title: "", country: "", language: "English", partnerSchool: "", teacherName: "", start: Date().addingTimeInterval(7 * 86400), summary: "")

    var body: some View {
        Form {
            TextField("Тема класса", text: $item.title)
            TextField("Страна партнёра", text: $item.country)
            TextField("Школа-партнёр", text: $item.partnerSchool)
            TextField("Преподаватель", text: $item.teacherName)
            TextField("Язык", text: $item.language)
            DatePicker("Дата и время", selection: $item.start)
            TextField("Ссылка (пусто — комната Jitsi создастся автоматически)", text: $item.meetingURL)
            TextField("Описание", text: $item.summary, axis: .vertical)
        }
        .navigationTitle("Международный класс")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    store.db.globalClasses.append(item)
                    dismiss()
                }
                .disabled(item.title.isEmpty || item.country.isEmpty)
            }
        }
    }
}

// MARK: - Совместные международные проекты (задача 62)

struct InternationalProjectsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var title = ""
    @State private var countries = ""
    @State private var partners = ""
    @State private var summary = ""

    var body: some View {
        KPage("Международные проекты") {
            ForEach(store.db.internationalProjects) { project in
                KCard {
                    HStack {
                        Text(project.title).font(.headline)
                        Spacer()
                        KBadge(text: project.isActive ? "Активен" : "Завершён", color: project.isActive ? KKSUTheme.success : .secondary)
                    }
                    Text(project.countries.joined(separator: " · ")).font(.caption).foregroundStyle(.tint)
                    Text("Партнёры: \(project.partners)").font(.caption).foregroundStyle(.secondary)
                    Text(project.summary).font(.callout)
                    Text("Участники KKSU: \(project.participantIDs.map { store.userName($0) }.joined(separator: ", "))").font(.caption)
                    if let me = store.currentUser?.id, store.role == .student, !project.participantIDs.contains(me),
                       let index = store.db.internationalProjects.firstIndex(where: { $0.id == project.id }) {
                        let consent = store.db.consents.last { $0.studentID == me && $0.type == .international }?.granted ?? false
                        Button("Присоединиться") { store.db.internationalProjects[index].participantIDs.append(me) }
                            .disabled(!consent)
                        if !consent {
                            Text("Нужно согласие родителя на участие в международных проектах.").font(.caption2).foregroundStyle(KKSUTheme.danger)
                        }
                    }
                }
            }
            RouteRow(route: .inventions, subtitle: "Проекты Global Classroom в KKSU Inventions")
            if store.role.canTeach {
                KCard {
                    Text("Новый международный проект").font(.headline)
                    TextField("Название", text: $title).textFieldStyle(.roundedBorder)
                    TextField("Страны через запятую", text: $countries).textFieldStyle(.roundedBorder)
                    TextField("Организации-партнёры", text: $partners).textFieldStyle(.roundedBorder)
                    TextField("Описание", text: $summary, axis: .vertical).textFieldStyle(.roundedBorder)
                    Button("Создать") {
                        let list = countries.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        store.db.internationalProjects.append(InternationalProject(title: title, countries: list, partners: partners, summary: summary))
                        title = ""; countries = ""; partners = ""; summary = ""
                    }
                    .disabled(title.isEmpty || countries.isEmpty)
                }
            }
        }
    }
}

// MARK: - Международные преподаватели и эксперты (задача 63)

struct InternationalExpertsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showTeachers: Bool?

    var body: some View {
        KPage("Международные эксперты") {
            HStack {
                FilterChip(title: "Все", selected: showTeachers == nil) { showTeachers = nil }
                FilterChip(title: "Преподаватели", selected: showTeachers == true) { showTeachers = true }
                FilterChip(title: "Эксперты", selected: showTeachers == false) { showTeachers = false }
            }
            ForEach(store.db.internationalExperts.filter { showTeachers == nil || $0.isTeacher == showTeachers }) { expert in
                KCard {
                    HStack(spacing: 12) {
                        KAvatar(name: expert.name, size: 48)
                        VStack(alignment: .leading) {
                            Text(expert.name).font(.headline)
                            Text("\(expert.country) · \(expert.expertise)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        KBadge(text: expert.isTeacher ? "Преподаватель" : "Эксперт")
                    }
                    Text(expert.bio).font(.callout)
                    if let url = URL(string: "mailto:\(expert.email)") {
                        Link(destination: url) { Label(expert.email, systemImage: "envelope") }.font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Future Engineers (задача 64)

struct FutureEngineersView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Future Engineers") {
            KCard {
                Label("Future Engineers", systemImage: "wrench.and.screwdriver.fill").font(.title2.bold()).foregroundStyle(.tint)
                Text("Инженерная школа KKSU: онлайн-курсы, виртуальные задания, индустриальные кейсы и проекты партнёров.")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach([KKSURoute.engineeringCourses, .challenges, .mashstroyCases, .araiAI, .iken, .ataMura, .inclusiveEngineering, .inclusiveCatalog], id: \.self) {
                    RouteTile(route: $0)
                }
            }
            if let me = store.currentUser?.id {
                let points = store.db.challenges.filter { $0.completedIDs.contains(me) }.reduce(0) { $0 + $1.points }
                KCard {
                    Text("Мой инженерный рейтинг").font(.headline)
                    Text("\(points) баллов").font(.title.bold()).foregroundStyle(KKSUTheme.accent)
                    Text("Выполнено заданий: \(store.db.challenges.filter { $0.completedIDs.contains(me) }.count) из \(store.db.challenges.count)").font(.caption)
                }
            }
        }
    }
}

// MARK: - Инженерные онлайн-курсы (задача 65)

struct EngineeringCoursesView: View {
    @EnvironmentObject private var store: KKSUStore
    let track: ProjectTrack?

    var body: some View {
        KPage("Инженерные онлайн-курсы") {
            ForEach(store.db.engineeringCourses.filter { track == nil || $0.track == track }) { course in
                EngineeringCourseCard(course: course)
            }
        }
    }
}

struct EngineeringCourseCard: View {
    @EnvironmentObject private var store: KKSUStore
    let course: EngineeringCourse
    @State private var expanded = false

    var body: some View {
        let me = store.currentUser?.id
        let enrolled = me.map { course.enrolledIDs.contains($0) } ?? false
        KCard {
            HStack {
                Label(course.title, systemImage: course.track.icon).font(.headline)
                Spacer()
                KBadge(text: course.level)
            }
            Text(course.track.title).font(.caption).foregroundStyle(.tint)
            Text(course.summary).font(.callout)
            DisclosureGroup("Уроки (\(course.lessons.count))", isExpanded: $expanded) {
                ForEach(Array(course.lessons.enumerated()), id: \.offset) { index, lesson in
                    Text("\(index + 1). \(lesson)").font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if enrolled {
                KBadge(text: "Вы записаны", color: KKSUTheme.success)
            } else if let me, store.role == .student, let index = store.db.engineeringCourses.firstIndex(where: { $0.id == course.id }) {
                Button("Записаться на курс") {
                    store.db.engineeringCourses[index].enrolledIDs.append(me)
                    store.log(me, "Запись на инженерный курс", details: course.title, icon: "book.and.wrench")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Виртуальные инженерные задания и кейсы (задачи 66, 67)

struct ChallengesView: View {
    @EnvironmentObject private var store: KKSUStore
    let track: ProjectTrack?
    let industryOnly: Bool

    var body: some View {
        let items = store.db.challenges.filter { (track == nil || $0.track == track) && (!industryOnly || $0.isIndustryCase) }
        KPage(industryOnly ? "Проектные кейсы \(track?.title ?? "")" : "Виртуальные инженерные задания") {
            if industryOnly {
                Text("Реальные производственные задачи от инженеров партнёра. Решения оцениваются специалистами компании.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            ForEach(items) { ChallengeCard(challenge: $0) }
        }
    }
}

struct ChallengeCard: View {
    @EnvironmentObject private var store: KKSUStore
    let challenge: EngineeringChallenge

    var body: some View {
        NavigationLink { ChallengeDetailView(challengeID: challenge.id) } label: {
            KCard {
                HStack {
                    Text(challenge.title).font(.headline)
                    Spacer()
                    if let me = store.currentUser?.id, challenge.completedIDs.contains(me) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                    }
                }
                HStack {
                    if challenge.isIndustryCase { KBadge(text: "Кейс \(challenge.company)", color: KKSUTheme.accent) }
                    KBadge(text: challenge.track.title)
                    Text(String(repeating: "★", count: challenge.difficulty) + String(repeating: "☆", count: max(0, 5 - challenge.difficulty)))
                        .font(.caption)
                        .accessibilityLabel("Сложность \(challenge.difficulty) из 5")
                    Spacer()
                    Text("+\(challenge.points)").font(.caption.bold())
                }
                Text(challenge.summary).font(.callout)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ChallengeDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let challengeID: UUID
    @State private var doneSteps: Set<Int> = []
    @State private var solution = ""
    @State private var attachments: [Attachment] = []

    var body: some View {
        if let index = store.db.challenges.firstIndex(where: { $0.id == challengeID }) {
            let challenge = store.db.challenges[index]
            let me = store.currentUser?.id
            let completed = me.map { challenge.completedIDs.contains($0) } ?? false
            KPage(challenge.title) {
                ChallengeCard(challenge: challenge).disabled(true)
                KCard {
                    Text("Шаги выполнения").font(.headline)
                    ForEach(Array(challenge.steps.enumerated()), id: \.offset) { offset, step in
                        Button {
                            if doneSteps.contains(offset) { doneSteps.remove(offset) } else { doneSteps.insert(offset) }
                        } label: {
                            HStack {
                                Image(systemName: doneSteps.contains(offset) || completed ? "checkmark.square.fill" : "square").foregroundStyle(.tint)
                                Text("\(offset + 1). \(step)")
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    KProgressBar(value: completed ? 1 : Double(doneSteps.count) / Double(max(challenge.steps.count, 1)))
                }
                if completed {
                    Label("Задание выполнено! +\(challenge.points) баллов", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                } else if let me, store.role == .student {
                    KCard {
                        Text("Решение").font(.headline)
                        TextField("Опишите решение, расчёты, выводы", text: $solution, axis: .vertical)
                            .lineLimit(3...10)
                            .textFieldStyle(.roundedBorder)
                        AttachmentPicker(attachments: $attachments)
                        Button("Отправить решение") {
                            store.db.challenges[index].completedIDs.append(me)
                            store.db.portfolio.append(PortfolioItem(studentID: me, title: challenge.title, category: challenge.isIndustryCase ? "Индустриальный кейс" : "Инженерное задание", summary: solution, attachments: attachments))
                            store.award(me, "Инженер: \(challenge.title)", icon: "wrench.and.screwdriver.fill", points: challenge.points)
                            store.log(me, "Выполнено инженерное задание", details: challenge.title, icon: "puzzlepiece.extension")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(doneSteps.count < challenge.steps.count || solution.isEmpty)
                        if doneSteps.count < challenge.steps.count {
                            Text("Отметьте все шаги, чтобы отправить решение.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Разделы партнёров: ARAI AI, IKEN, ATA MURA, Inclusive Engineering (задачи 68–71)

struct TrackHubView: View {
    @EnvironmentObject private var store: KKSUStore
    let track: ProjectTrack

    private var partnerName: String? {
        switch track {
        case .araiAI: return "ARAI AI"
        case .iken: return "IKEN"
        case .ataMura: return "ATA MURA"
        case .mashstroy: return "MASHSTROY"
        default: return nil
        }
    }

    var body: some View {
        let projects = store.db.projects.filter { $0.track == track }
        let courses = store.db.engineeringCourses.filter { $0.track == track }
        let challenges = store.db.challenges.filter { $0.track == track }
        KPage(track.title) {
            KCard {
                Label(track.title, systemImage: track.icon).font(.title2.bold()).foregroundStyle(.tint)
                Text(track.summary)
                if let partnerName, let partner = store.db.partners.first(where: { $0.name == partnerName }) {
                    Text(partner.summary).font(.callout).foregroundStyle(.secondary)
                    if let url = URL(string: partner.website) {
                        Link(destination: url) { Label(partner.website, systemImage: "safari") }.font(.caption)
                    }
                }
            }
            if track == .araiAI {
                ARAIIntegrationCard()
            }
            if track == .inclusiveEngineering {
                KCard {
                    Text("Принципы инклюзивной инженерии").font(.headline)
                    ForEach(["Проектируй вместе с пользователем", "Универсальный дизайн: удобно всем", "Доступная стоимость и ремонтопригодность", "Тестирование с людьми с инвалидностью"], id: \.self) {
                        Label($0, systemImage: "checkmark.circle").font(.callout)
                    }
                }
                RouteRow(route: .inclusiveCatalog, subtitle: "Все инклюзивные разработки KKSU")
            }
            KSectionHeader(title: "Проекты · \(projects.count)", icon: "lightbulb.fill")
            if projects.isEmpty { KEmptyState(text: "Проектов пока нет — создайте первый!", icon: "lightbulb") }
            ForEach(projects) { project in
                NavigationLink { ProjectDetailView(projectID: project.id) } label: { ProjectCard(project: project) }
                    .buttonStyle(.plain)
            }
            NavigationLink { InventionsView(track: track) } label: {
                Label("Все проекты и создание нового", systemImage: "plus.circle")
            }
            if !courses.isEmpty {
                KSectionHeader(title: "Курсы", icon: "book.and.wrench.fill")
                ForEach(courses) { EngineeringCourseCard(course: $0) }
            }
            if !challenges.isEmpty {
                KSectionHeader(title: "Задания", icon: "puzzlepiece.extension.fill")
                ForEach(challenges) { ChallengeCard(challenge: $0) }
            }
        }
    }
}

/// Интеграционный раздел ARAI AI (задача 68): AI-сервисы, доступные в учебных проектах.
struct ARAIIntegrationCard: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KCard {
            Text("Интеграция ARAI AI").font(.headline)
            Text("AI-сервисы для проектов учеников: распознавание изображений, чат-боты, анализ данных. На платформе KKSU AI-модули подключаются через единый AI-шлюз (см. AI-помощник).")
                .font(.callout)
            ForEach([("camera.viewfinder", "Компьютерное зрение", "Распознавание объектов для роботов"),
                     ("bubble.left.and.text.bubble.right", "Диалоговые боты", "Боты-помощники для школьных сервисов"),
                     ("chart.xyaxis.line", "Анализ данных", "Обработка измерений из лабораторной тетради")], id: \.1) { item in
                HStack(alignment: .top) {
                    Image(systemName: item.0).foregroundStyle(.tint).frame(width: 28)
                    VStack(alignment: .leading) {
                        Text(item.1).font(.callout.weight(.semibold))
                        Text(item.2).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Circle().fill(KKSUAIService.shared.isConfigured ? KKSUTheme.success : KKSUTheme.warning).frame(width: 10, height: 10)
                Text(KKSUAIService.shared.isConfigured ? "AI-шлюз подключён" : "Работает локальный AI-режим; ключ API настраивается в AI-помощнике")
                    .font(.caption)
            }
            NavigationLink(value: KKSURoute.aiAssistant) { Label("Открыть AI-помощника", systemImage: "sparkles") }
        }
    }
}

// MARK: - Каталог инклюзивных разработок (задача 72)

struct InclusiveCatalogView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var target = ""

    var body: some View {
        let items = store.db.projects.filter { $0.track == .inclusiveEngineering || !$0.inclusiveTarget.isEmpty }
        let challenges = store.db.challenges.filter { $0.track == .inclusiveEngineering }
        let targets = Array(Set(items.map(\.inclusiveTarget).filter { !$0.isEmpty })).sorted()
        KPage("Каталог инклюзивных разработок") {
            Text("Инженерные решения учеников KKSU для людей с особыми потребностями: вспомогательные устройства, адаптированная среда, цифровые сервисы.")
                .font(.callout).foregroundStyle(.secondary)
            if !targets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "Все", selected: target.isEmpty) { target = "" }
                        ForEach(targets, id: \.self) { item in
                            FilterChip(title: item, selected: target == item) { target = item }
                        }
                    }
                }
            }
            ForEach(items.filter { target.isEmpty || $0.inclusiveTarget == target }) { project in
                NavigationLink { ProjectDetailView(projectID: project.id) } label: {
                    KCard {
                        Label(project.title, systemImage: "figure.roll").font(.headline)
                        if !project.inclusiveTarget.isEmpty {
                            KBadge(text: "Для: \(project.inclusiveTarget)", color: .purple)
                        }
                        Text(project.summary).font(.callout)
                        if !project.solution.isEmpty { Text("Решение: \(project.solution)").font(.caption) }
                        StageProgress(stage: project.stage)
                    }
                }
                .buttonStyle(.plain)
            }
            if !challenges.isEmpty {
                KSectionHeader(title: "Инклюзивные инженерные задания", icon: "puzzlepiece.extension")
                ForEach(challenges) { ChallengeCard(challenge: $0) }
            }
        }
    }
}
