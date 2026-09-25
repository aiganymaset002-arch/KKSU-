//
//  KKSUNavigation.swift
//  KKSU Online
//
//  Маршруты всех модулей, ролевой доступ и карта 100 технических задач.
//

import SwiftUI

enum KKSURoute: String, Hashable, CaseIterable, Identifiable {
    // Кабинеты
    case studentCabinet, parentCabinet, teacherCabinet, expertCabinet, psychologistCabinet, partnerCabinet, adminPanel
    // Ученик
    case studentProfile, intake, application, consents, programs, trajectory, studyPlan, schedule, calendar
    case homework, grading, portfolio, achievements, progressDashboard, history
    // Библиотеки и тесты
    case videoLibrary, methodicalLibrary, documents, tests, testBuilder
    // Коммуникации
    case onlineLessons, chat, notifications, deadlines
    // Teacher Academy
    case teacherAcademy, academyRegistration, academyCourses, academyLibrary, academyTasks, certificates
    case methodologies, pilots, methodologyReview, pilotRegistry
    // Изобретения
    case inventions, teams, prototypes, youngInventors, yiApply, yiReview, exhibition
    // Международное и инженерия
    case globalClassroom, globalClasses, internationalProjects, internationalExperts
    case futureEngineers, engineeringCourses, challenges, mashstroyCases, araiAI, iken, ataMura
    case inclusiveEngineering, inclusiveCatalog
    // Доступность и AI
    case accessibility, learningSettings, recommendations
    case aiAssistant, teacherAI, aiTaskGenerator, progressAnalysis, teacherRecommendations
    // Impact, партнёры, аналитика
    case impactDashboard, impactReport, impactPublic
    case partners, internships, events, analytics
    case users, featureMap, legacyScreens

    var id: String { rawValue }

    var title: String {
        switch self {
        case .studentCabinet: return "Кабинет ученика"
        case .parentCabinet: return "Кабинет родителя"
        case .teacherCabinet: return "Кабинет педагога"
        case .expertCabinet: return "Кабинет эксперта / наставника"
        case .psychologistCabinet: return "Кабинет психолога"
        case .partnerCabinet: return "Кабинет партнёра"
        case .adminPanel: return "Административная панель"
        case .studentProfile: return "Профиль ученика"
        case .intake: return "Анкета поступления"
        case .application: return "Заявка на обучение"
        case .consents: return "Согласия родителей"
        case .programs: return "Каталог программ"
        case .trajectory: return "Образовательная траектория"
        case .studyPlan: return "Индивидуальный учебный план"
        case .schedule: return "Расписание"
        case .calendar: return "Календарь"
        case .homework: return "Домашние задания"
        case .grading: return "Проверка работ"
        case .portfolio: return "Портфолио"
        case .achievements: return "Достижения и сертификаты"
        case .progressDashboard: return "Дашборд прогресса"
        case .history: return "История обучения"
        case .videoLibrary: return "Видеоуроки"
        case .methodicalLibrary: return "Методические материалы"
        case .documents: return "PDF, презентации, учебники"
        case .tests: return "Онлайн-тестирование"
        case .testBuilder: return "Конструктор тестов"
        case .onlineLessons: return "Онлайн-занятия"
        case .chat: return "Чат"
        case .notifications: return "Уведомления"
        case .deadlines: return "Дедлайны"
        case .teacherAcademy: return "KKSU Teacher Academy"
        case .academyRegistration: return "Регистрация в Academy"
        case .academyCourses: return "Курсы повышения квалификации"
        case .academyLibrary: return "Методическая библиотека Academy"
        case .academyTasks: return "Задания и тесты педагогов"
        case .certificates: return "Электронные сертификаты"
        case .methodologies: return "Авторские методики KKSU"
        case .pilots: return "Апробация методик"
        case .methodologyReview: return "Экспертная оценка методик"
        case .pilotRegistry: return "Реестр результатов апробации"
        case .inventions: return "KKSU Inventions"
        case .teams: return "Проектные команды"
        case .prototypes: return "Каталог прототипов"
        case .youngInventors: return "Young Inventors 30"
        case .yiApply: return "Заявка в Young Inventors"
        case .yiReview: return "Экспертиза проектов"
        case .exhibition: return "Виртуальная выставка"
        case .globalClassroom: return "Global Classroom"
        case .globalClasses: return "Международные онлайн-классы"
        case .internationalProjects: return "Международные проекты"
        case .internationalExperts: return "Международные эксперты"
        case .futureEngineers: return "Future Engineers"
        case .engineeringCourses: return "Инженерные онлайн-курсы"
        case .challenges: return "Виртуальные инженерные задания"
        case .mashstroyCases: return "Кейсы MASHSTROY"
        case .araiAI: return "ARAI AI"
        case .iken: return "Проекты IKEN"
        case .ataMura: return "Проекты ATA MURA"
        case .inclusiveEngineering: return "Inclusive Engineering"
        case .inclusiveCatalog: return "Каталог инклюзивных разработок"
        case .accessibility: return "Доступность интерфейса"
        case .learningSettings: return "Настройки обучения"
        case .recommendations: return "Рекомендации"
        case .aiAssistant: return "AI-помощник KKSU"
        case .teacherAI: return "AI-помощник педагога"
        case .aiTaskGenerator: return "Генерация заданий AI"
        case .progressAnalysis: return "Анализ прогресса"
        case .teacherRecommendations: return "Рекомендации педагогу"
        case .impactDashboard: return "Impact Dashboard"
        case .impactReport: return "KKSU Impact Report"
        case .impactPublic: return "Публичная страница Impact"
        case .partners: return "Партнёры KKSU"
        case .internships: return "Стажировки"
        case .events: return "Конференции и мероприятия"
        case .analytics: return "Аналитика KKSU"
        case .users: return "Пользователи и роли"
        case .featureMap: return "Карта 100 задач"
        case .legacyScreens: return "Прототипы экранов"
        }
    }

    var icon: String {
        switch self {
        case .studentCabinet: return "graduationcap.fill"
        case .parentCabinet: return "person.2.fill"
        case .teacherCabinet: return "person.fill.viewfinder"
        case .expertCabinet: return "checkmark.seal.fill"
        case .psychologistCabinet: return "heart.text.square.fill"
        case .partnerCabinet: return "building.2.fill"
        case .adminPanel: return "gearshape.2.fill"
        case .studentProfile: return "person.crop.circle"
        case .intake: return "list.clipboard.fill"
        case .application: return "doc.text.fill"
        case .consents: return "signature"
        case .programs: return "square.grid.2x2.fill"
        case .trajectory: return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .studyPlan: return "tablecells.fill"
        case .schedule: return "clock.fill"
        case .calendar: return "calendar"
        case .homework: return "house.and.flag.fill"
        case .grading: return "checkmark.rectangle.stack.fill"
        case .portfolio: return "briefcase.fill"
        case .achievements: return "trophy.fill"
        case .progressDashboard: return "chart.line.uptrend.xyaxis"
        case .history: return "clock.arrow.circlepath"
        case .videoLibrary: return "play.rectangle.fill"
        case .methodicalLibrary: return "text.book.closed.fill"
        case .documents: return "doc.richtext.fill"
        case .tests: return "checklist"
        case .testBuilder: return "hammer.fill"
        case .onlineLessons: return "video.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .notifications: return "bell.fill"
        case .deadlines: return "clock.badge.exclamationmark.fill"
        case .teacherAcademy: return "building.columns.fill"
        case .academyRegistration: return "person.badge.plus"
        case .academyCourses: return "person.crop.rectangle.stack.fill"
        case .academyLibrary: return "books.vertical.fill"
        case .academyTasks: return "pencil.and.list.clipboard"
        case .certificates: return "doc.badge.ellipsis"
        case .methodologies: return "lightbulb.2.fill"
        case .pilots: return "testtube.2"
        case .methodologyReview: return "star.leadinghalf.filled"
        case .pilotRegistry: return "list.bullet.rectangle.fill"
        case .inventions: return "lightbulb.max.fill"
        case .teams: return "person.3.fill"
        case .prototypes: return "cube.transparent.fill"
        case .youngInventors: return "sparkles"
        case .yiApply: return "paperplane.fill"
        case .yiReview: return "checkmark.seal"
        case .exhibition: return "building.fill"
        case .globalClassroom: return "globe.europe.africa.fill"
        case .globalClasses: return "video.bubble.fill"
        case .internationalProjects: return "globe"
        case .internationalExperts: return "person.crop.square.filled.and.at.rectangle"
        case .futureEngineers: return "wrench.and.screwdriver.fill"
        case .engineeringCourses: return "book.and.wrench.fill"
        case .challenges: return "puzzlepiece.extension.fill"
        case .mashstroyCases: return "gearshape.2.fill"
        case .araiAI: return "brain.head.profile"
        case .iken: return "leaf.fill"
        case .ataMura: return "building.columns"
        case .inclusiveEngineering: return "figure.roll"
        case .inclusiveCatalog: return "accessibility"
        case .accessibility: return "textformat.size"
        case .learningSettings: return "slider.horizontal.3"
        case .recommendations: return "hand.thumbsup.fill"
        case .aiAssistant: return "sparkles"
        case .teacherAI: return "wand.and.stars"
        case .aiTaskGenerator: return "text.badge.plus"
        case .progressAnalysis: return "waveform.path.ecg"
        case .teacherRecommendations: return "lightbulb.fill"
        case .impactDashboard: return "chart.bar.xaxis"
        case .impactReport: return "doc.text.image.fill"
        case .impactPublic: return "megaphone.fill"
        case .partners: return "handshake.fill"
        case .internships: return "briefcase.circle.fill"
        case .events: return "calendar.badge.plus"
        case .analytics: return "chart.pie.fill"
        case .users: return "person.3.sequence.fill"
        case .featureMap: return "map.fill"
        case .legacyScreens: return "iphone.gen3"
        }
    }

    /// Роли, которым доступен модуль. Пустой список — доступно всем.
    var roles: [KKSURole] {
        switch self {
        case .studentCabinet, .homework, .portfolio, .trajectory, .studyPlan, .intake: return [.student, .parent, .teacher, .psychologist, .mentor, .admin]
        case .parentCabinet, .consents: return [.parent, .admin]
        case .teacherCabinet, .grading, .testBuilder, .teacherAI, .aiTaskGenerator, .teacherRecommendations: return [.teacher, .admin]
        case .expertCabinet, .methodologyReview, .yiReview: return [.expert, .mentor, .admin]
        case .psychologistCabinet: return [.psychologist, .admin]
        case .partnerCabinet: return [.partner, .admin]
        case .adminPanel, .analytics, .users, .impactReport: return [.admin]
        case .teacherAcademy, .academyRegistration, .academyCourses, .academyLibrary, .academyTasks, .methodologies, .pilots, .pilotRegistry:
            return [.teacher, .psychologist, .expert, .mentor, .admin]
        case .progressAnalysis: return [.teacher, .psychologist, .parent, .mentor, .admin]
        case .impactDashboard: return [.admin, .partner, .expert, .teacher]
        default: return []
        }
    }

    func isAvailable(for role: KKSURole) -> Bool { roles.isEmpty || roles.contains(role) }

    static func cabinet(for role: KKSURole) -> KKSURoute {
        switch role {
        case .student: return .studentCabinet
        case .parent: return .parentCabinet
        case .teacher: return .teacherCabinet
        case .psychologist: return .psychologistCabinet
        case .expert, .mentor: return .expertCabinet
        case .partner: return .partnerCabinet
        case .admin: return .adminPanel
        }
    }

    @MainActor
    var destination: AnyView {
        switch self {
        case .studentCabinet: return AnyView(StudentCabinetView())
        case .parentCabinet: return AnyView(ParentHomeView())
        case .teacherCabinet: return AnyView(TeacherHomeView())
        case .expertCabinet: return AnyView(ExpertCabinetView())
        case .psychologistCabinet: return AnyView(PsychologistCabinetView())
        case .partnerCabinet: return AnyView(PartnerCabinetView())
        case .adminPanel: return AnyView(AdminPanelView())
        case .studentProfile: return AnyView(StudentProfileEditorView())
        case .intake: return AnyView(IntakeQuestionnaireView())
        case .application: return AnyView(EnrollmentApplicationView())
        case .consents: return AnyView(ConsentsView())
        case .programs: return AnyView(ProgramCatalogView())
        case .trajectory: return AnyView(TrajectoryView())
        case .studyPlan: return AnyView(StudyPlanView())
        case .schedule: return AnyView(LessonsView())
        case .calendar: return AnyView(StudentCalendarView())
        case .homework: return AnyView(HomeworkListView())
        case .grading: return AnyView(GradingQueueView())
        case .portfolio: return AnyView(PortfolioView())
        case .achievements: return AnyView(AchievementsView())
        case .progressDashboard: return AnyView(ProgressDashboardView())
        case .history: return AnyView(LearningHistoryView())
        case .videoLibrary: return AnyView(LibraryListView(kinds: [.video], title: "Видеоуроки"))
        case .methodicalLibrary: return AnyView(LibraryListView(kinds: [.methodical], title: "Методические материалы"))
        case .documents: return AnyView(LibraryListView(kinds: [.pdf, .presentation, .instruction, .textbook], title: "PDF, презентации, учебники"))
        case .tests: return AnyView(TestListView(audience: .students))
        case .testBuilder: return AnyView(TestBuilderView())
        case .onlineLessons: return AnyView(LessonsView(onlyOnline: true))
        case .chat: return AnyView(ChatListView())
        case .notifications: return AnyView(NotificationsView())
        case .deadlines: return AnyView(DeadlinesView())
        case .teacherAcademy: return AnyView(TeacherAcademyView())
        case .academyRegistration: return AnyView(AcademyRegistrationView())
        case .academyCourses: return AnyView(AcademyCoursesView())
        case .academyLibrary: return AnyView(LibraryListView(kinds: LibraryKind.allCases, title: "Методическая библиотека", teacherAcademyOnly: true))
        case .academyTasks: return AnyView(AcademyTasksView())
        case .certificates: return AnyView(CertificatesView())
        case .methodologies: return AnyView(MethodologyCatalogView())
        case .pilots: return AnyView(PilotsView())
        case .methodologyReview: return AnyView(MethodologyReviewQueueView())
        case .pilotRegistry: return AnyView(PilotRegistryView())
        case .inventions: return AnyView(InventionsView(track: nil))
        case .teams: return AnyView(TeamsView())
        case .prototypes: return AnyView(PrototypeCatalogView())
        case .youngInventors: return AnyView(YoungInventorsView())
        case .yiApply: return AnyView(YoungInventorsApplyView())
        case .yiReview: return AnyView(YoungInventorsReviewView())
        case .exhibition: return AnyView(VirtualExhibitionView())
        case .globalClassroom: return AnyView(GlobalClassroomView())
        case .globalClasses: return AnyView(GlobalClassesView())
        case .internationalProjects: return AnyView(InternationalProjectsView())
        case .internationalExperts: return AnyView(InternationalExpertsView())
        case .futureEngineers: return AnyView(FutureEngineersView())
        case .engineeringCourses: return AnyView(EngineeringCoursesView(track: nil))
        case .challenges: return AnyView(ChallengesView(track: nil, industryOnly: false))
        case .mashstroyCases: return AnyView(ChallengesView(track: .mashstroy, industryOnly: true))
        case .araiAI: return AnyView(TrackHubView(track: .araiAI))
        case .iken: return AnyView(TrackHubView(track: .iken))
        case .ataMura: return AnyView(TrackHubView(track: .ataMura))
        case .inclusiveEngineering: return AnyView(TrackHubView(track: .inclusiveEngineering))
        case .inclusiveCatalog: return AnyView(InclusiveCatalogView())
        case .accessibility: return AnyView(AccessibilitySettingsView())
        case .learningSettings: return AnyView(LearningSettingsView())
        case .recommendations: return AnyView(RecommendationsView())
        case .aiAssistant: return AnyView(AIAssistantView(mode: .student))
        case .teacherAI: return AnyView(AIAssistantView(mode: .teacher))
        case .aiTaskGenerator: return AnyView(AITaskGeneratorView())
        case .progressAnalysis: return AnyView(ProgressAnalysisView())
        case .teacherRecommendations: return AnyView(TeacherRecommendationsView())
        case .impactDashboard: return AnyView(ImpactDashboardView())
        case .impactReport: return AnyView(ImpactReportView())
        case .impactPublic: return AnyView(ImpactPublicView())
        case .partners: return AnyView(PartnersView())
        case .internships: return AnyView(InternshipsView())
        case .events: return AnyView(EventsView())
        case .analytics: return AnyView(AnalyticsView())
        case .users: return AnyView(UserManagementView())
        case .featureMap: return AnyView(FeatureMapView())
        case .legacyScreens: return AnyView(LegacyScreensView())
        }
    }
}

// MARK: - Разделы хаба модулей

struct KKSUModuleSection: Identifiable {
    let id = UUID()
    let title: String
    let routes: [KKSURoute]

    static let all: [KKSUModuleSection] = [
        KKSUModuleSection(title: "Обучение", routes: [.programs, .trajectory, .studyPlan, .schedule, .calendar, .homework, .deadlines, .tests, .progressDashboard, .history]),
        KKSUModuleSection(title: "Моё", routes: [.studentProfile, .portfolio, .achievements, .certificates, .intake, .application, .consents]),
        KKSUModuleSection(title: "Библиотеки", routes: [.videoLibrary, .methodicalLibrary, .documents]),
        KKSUModuleSection(title: "Связь", routes: [.onlineLessons, .chat, .notifications]),
        KKSUModuleSection(title: "Педагогу", routes: [.grading, .testBuilder, .teacherAI, .aiTaskGenerator, .progressAnalysis, .teacherRecommendations]),
        KKSUModuleSection(title: "KKSU Teacher Academy", routes: [.teacherAcademy, .academyRegistration, .academyCourses, .academyLibrary, .academyTasks, .methodologies, .pilots, .methodologyReview, .pilotRegistry]),
        KKSUModuleSection(title: "Изобретения", routes: [.inventions, .teams, .prototypes, .youngInventors, .yiApply, .yiReview, .exhibition]),
        KKSUModuleSection(title: "Global Classroom", routes: [.globalClassroom, .globalClasses, .internationalProjects, .internationalExperts]),
        KKSUModuleSection(title: "Future Engineers", routes: [.futureEngineers, .engineeringCourses, .challenges, .mashstroyCases, .araiAI, .iken, .ataMura, .inclusiveEngineering, .inclusiveCatalog]),
        KKSUModuleSection(title: "AI и персонализация", routes: [.aiAssistant, .recommendations, .learningSettings, .accessibility]),
        KKSUModuleSection(title: "Партнёрство и события", routes: [.partners, .internships, .events]),
        KKSUModuleSection(title: "Impact и управление", routes: [.impactDashboard, .impactReport, .impactPublic, .analytics, .users, .adminPanel]),
        KKSUModuleSection(title: "О платформе", routes: [.featureMap, .legacyScreens])
    ]
}

// MARK: - Карта 100 технических задач

struct KKSUFeature: Identifiable {
    let id: Int
    let title: String
    let route: KKSURoute
    var note: String = ""

    static let all: [KKSUFeature] = [
        KKSUFeature(id: 1, title: "Главная страница KKSU Online", route: .impactPublic, note: "Стартовый экран до входа (KKSULandingView)"),
        KKSUFeature(id: 2, title: "Регистрация пользователей", route: .users, note: "RegistrationView"),
        KKSUFeature(id: 3, title: "Вход и восстановление пароля", route: .users, note: "LoginView, ForgotPasswordView"),
        KKSUFeature(id: 4, title: "Роли: ученик, родитель, педагог, психолог, эксперт, наставник, партнёр, администратор", route: .users),
        KKSUFeature(id: 5, title: "Личный кабинет ученика", route: .studentCabinet),
        KKSUFeature(id: 6, title: "Кабинет родителя", route: .parentCabinet),
        KKSUFeature(id: 7, title: "Кабинет преподавателя", route: .teacherCabinet),
        KKSUFeature(id: 8, title: "Кабинет эксперта/наставника", route: .expertCabinet),
        KKSUFeature(id: 9, title: "Административная панель", route: .adminPanel),
        KKSUFeature(id: 10, title: "Профиль ученика", route: .studentProfile),
        KKSUFeature(id: 11, title: "Цифровая анкета первичного поступления", route: .intake),
        KKSUFeature(id: 12, title: "Онлайн-заявка на обучение", route: .application),
        KKSUFeature(id: 13, title: "Система согласий родителей", route: .consents),
        KKSUFeature(id: 14, title: "Каталог образовательных программ", route: .programs),
        KKSUFeature(id: 15, title: "Индивидуальная образовательная траектория", route: .trajectory),
        KKSUFeature(id: 16, title: "Индивидуальный учебный план", route: .studyPlan),
        KKSUFeature(id: 17, title: "Расписание занятий", route: .schedule),
        KKSUFeature(id: 18, title: "Календарь ученика", route: .calendar),
        KKSUFeature(id: 19, title: "Система домашних заданий", route: .homework),
        KKSUFeature(id: 20, title: "Загрузка выполненных работ", route: .homework, note: "Фото, видео, документы"),
        KKSUFeature(id: 21, title: "Оценки и обратная связь преподавателя", route: .grading),
        KKSUFeature(id: 22, title: "Электронное портфолио ученика", route: .portfolio),
        KKSUFeature(id: 23, title: "Система достижений и сертификатов", route: .achievements),
        KKSUFeature(id: 24, title: "Дашборд прогресса", route: .progressDashboard),
        KKSUFeature(id: 25, title: "История обучения", route: .history),
        KKSUFeature(id: 26, title: "Библиотека видеоуроков", route: .videoLibrary),
        KKSUFeature(id: 27, title: "Библиотека методических материалов", route: .methodicalLibrary),
        KKSUFeature(id: 28, title: "База PDF, презентаций, инструкций и учебников", route: .documents),
        KKSUFeature(id: 29, title: "Онлайн-тестирование", route: .tests),
        KKSUFeature(id: 30, title: "Автоматическая проверка тестов", route: .tests, note: "Один/несколько ответов, число, текст"),
        KKSUFeature(id: 31, title: "Конструктор тестов для преподавателей", route: .testBuilder),
        KKSUFeature(id: 32, title: "Модуль онлайн-занятий", route: .onlineLessons),
        KKSUFeature(id: 33, title: "Ссылки/интеграция видеоконференций", route: .onlineLessons, note: "Jitsi (автокомната), Zoom, Meet, Teams"),
        KKSUFeature(id: 34, title: "Внутренний чат ученик–преподаватель", route: .chat),
        KKSUFeature(id: 35, title: "Уведомления", route: .notifications, note: "В приложении + системные"),
        KKSUFeature(id: 36, title: "Система дедлайнов", route: .deadlines),
        KKSUFeature(id: 37, title: "KKSU Teacher Academy", route: .teacherAcademy),
        KKSUFeature(id: 38, title: "Регистрация педагогов в Teacher Academy", route: .academyRegistration),
        KKSUFeature(id: 39, title: "Курсы повышения квалификации", route: .academyCourses),
        KKSUFeature(id: 40, title: "Методическая библиотека Teacher Academy", route: .academyLibrary),
        KKSUFeature(id: 41, title: "Задания и тестирование педагогов", route: .academyTasks),
        KKSUFeature(id: 42, title: "Электронные сертификаты Teacher Academy", route: .certificates, note: "Автовыдача после курса, PDF"),
        KKSUFeature(id: 43, title: "Каталог авторских методик KKSU", route: .methodologies),
        KKSUFeature(id: 44, title: "Раздел апробации методик", route: .pilots),
        KKSUFeature(id: 45, title: "Форма экспертной оценки методик", route: .methodologyReview),
        KKSUFeature(id: 46, title: "Реестр результатов апробации", route: .pilotRegistry),
        KKSUFeature(id: 47, title: "KKSU Inventions", route: .inventions),
        KKSUFeature(id: 48, title: "Карточка изобретения/проекта", route: .inventions, note: "ProjectDetailView"),
        KKSUFeature(id: 49, title: "Фото, видео, чертежи и документы проекта", route: .inventions, note: "Вкладка «Материалы» в карточке"),
        KKSUFeature(id: 50, title: "Проектные команды учеников", route: .teams),
        KKSUFeature(id: 51, title: "Назначение наставника на проект", route: .inventions, note: "В карточке проекта"),
        KKSUFeature(id: 52, title: "Стадии проекта Idea → Research → Prototype → Testing → Result", route: .inventions),
        KKSUFeature(id: 53, title: "Журнал экспериментов", route: .inventions, note: "Вкладка в карточке проекта"),
        KKSUFeature(id: 54, title: "Электронная лабораторная тетрадь", route: .inventions, note: "Вкладка в карточке проекта"),
        KKSUFeature(id: 55, title: "Каталог прототипов KKSU", route: .prototypes),
        KKSUFeature(id: 56, title: "Young Inventors 30", route: .youngInventors),
        KKSUFeature(id: 57, title: "Подача заявок в Young Inventors", route: .yiApply),
        KKSUFeature(id: 58, title: "Экспертное рассмотрение проектов", route: .yiReview),
        KKSUFeature(id: 59, title: "Виртуальная выставка изобретений", route: .exhibition),
        KKSUFeature(id: 60, title: "Global Classroom", route: .globalClassroom),
        KKSUFeature(id: 61, title: "Международные онлайн-классы", route: .globalClasses),
        KKSUFeature(id: 62, title: "Совместные международные проекты", route: .internationalProjects),
        KKSUFeature(id: 63, title: "Международные преподаватели и эксперты", route: .internationalExperts),
        KKSUFeature(id: 64, title: "Future Engineers", route: .futureEngineers),
        KKSUFeature(id: 65, title: "Инженерные онлайн-курсы", route: .engineeringCourses),
        KKSUFeature(id: 66, title: "Виртуальные инженерные задания", route: .challenges),
        KKSUFeature(id: 67, title: "Проектные кейсы MASHSTROY", route: .mashstroyCases),
        KKSUFeature(id: 68, title: "Интеграционный раздел ARAI AI", route: .araiAI),
        KKSUFeature(id: 69, title: "Проекты IKEN", route: .iken),
        KKSUFeature(id: 70, title: "Проекты ATA MURA", route: .ataMura),
        KKSUFeature(id: 71, title: "Раздел Inclusive Engineering", route: .inclusiveEngineering),
        KKSUFeature(id: 72, title: "Каталог инклюзивных инженерных разработок", route: .inclusiveCatalog),
        KKSUFeature(id: 73, title: "Адаптивный интерфейс платформы", route: .accessibility, note: "iPhone/iPad, Dynamic Type, VoiceOver"),
        KKSUFeature(id: 74, title: "Размер текста, контраст и интерфейс", route: .accessibility),
        KKSUFeature(id: 75, title: "Субтитры к видео", route: .videoLibrary),
        KKSUFeature(id: 76, title: "Текстовые альтернативы материалам", route: .documents),
        KKSUFeature(id: 77, title: "Индивидуальные настройки обучения", route: .learningSettings),
        KKSUFeature(id: 78, title: "Рекомендации образовательного контента", route: .recommendations),
        KKSUFeature(id: 79, title: "AI-помощник KKSU", route: .aiAssistant),
        KKSUFeature(id: 80, title: "AI-помощник преподавателя", route: .teacherAI),
        KKSUFeature(id: 81, title: "Генерация индивидуальных заданий с проверкой педагогом", route: .aiTaskGenerator),
        KKSUFeature(id: 82, title: "Анализ учебного прогресса", route: .progressAnalysis),
        KKSUFeature(id: 83, title: "Рекомендации преподавателю на основе данных", route: .teacherRecommendations),
        KKSUFeature(id: 84, title: "Impact Dashboard", route: .impactDashboard),
        KKSUFeature(id: 85, title: "Автоподсчёт учеников, занятий, проектов и результатов", route: .impactDashboard),
        KKSUFeature(id: 86, title: "Показатели образовательного прогресса", route: .impactDashboard),
        KKSUFeature(id: 87, title: "Показатели проектов и изобретений", route: .impactDashboard),
        KKSUFeature(id: 88, title: "Показатели партнёрств", route: .impactDashboard),
        KKSUFeature(id: 89, title: "Показатели международной деятельности", route: .impactDashboard),
        KKSUFeature(id: 90, title: "Генератор KKSU Impact Report", route: .impactReport),
        KKSUFeature(id: 91, title: "Impact Report в PDF", route: .impactReport),
        KKSUFeature(id: 92, title: "Публичная страница Impact", route: .impactPublic),
        KKSUFeature(id: 93, title: "Каталог партнёров KKSU", route: .partners),
        KKSUFeature(id: 94, title: "Кабинет организации-партнёра", route: .partnerCabinet),
        KKSUFeature(id: 95, title: "Раздел стажировок", route: .internships),
        KKSUFeature(id: 96, title: "Заявки учеников на стажировки", route: .internships),
        KKSUFeature(id: 97, title: "Конференции и мероприятия", route: .events),
        KKSUFeature(id: 98, title: "Регистрация на конференции", route: .events),
        KKSUFeature(id: 99, title: "Электронные сертификаты участников", route: .certificates),
        KKSUFeature(id: 100, title: "Единая административная аналитика KKSU", route: .analytics)
    ]
}

// MARK: - Строка навигации к модулю

struct RouteRow: View {
    let route: KKSURoute
    var subtitle: String?

    var body: some View {
        NavigationLink(value: route) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.title)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: route.icon).foregroundStyle(.tint)
            }
        }
    }
}

struct RouteTile: View {
    let route: KKSURoute

    var body: some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: route.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text(route.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.18)))
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// Подключает все маршруты модулей к NavigationStack.
    func kksuRoutes() -> some View {
        navigationDestination(for: KKSURoute.self) { route in
            RouteGate(route: route)
        }
    }
}

/// Проверка ролевого доступа перед открытием модуля.
struct RouteGate: View {
    @EnvironmentObject private var store: KKSUStore
    let route: KKSURoute

    var body: some View {
        if route.isAvailable(for: store.role) {
            route.destination
        } else {
            KEmptyState(text: "Раздел «\(route.title)» недоступен для роли «\(store.role.title)».", icon: "lock.fill")
                .navigationTitle(route.title)
        }
    }
}
