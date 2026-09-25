//
//  KKSURootViews.swift
//  KKSU Online
//
//  Корневой экран, главная страница (задача 1), вкладки по ролям,
//  хаб модулей, аккаунт и карта 100 задач.
//

import SwiftUI

struct KKSURootView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        Group {
            if store.currentUser != nil {
                KKSUMainView()
            } else {
                KKSULandingView()
            }
        }
        .kksuAdaptive(store.accessibility)
    }
}

// MARK: - Главная страница KKSU Online (задача 1)

struct KKSULandingView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showLogin = false
    @State private var showRegistration = false

    private let initiatives: [(String, String, String)] = [
        ("building.columns.fill", "KKSU Teacher Academy", "Повышение квалификации педагогов и авторские методики"),
        ("lightbulb.max.fill", "KKSU Inventions", "Проекты учеников: от идеи до прототипа"),
        ("sparkles", "Young Inventors 30", "Конкурс 30 молодых изобретателей"),
        ("globe.europe.africa.fill", "Global Classroom", "Международные онлайн-классы и проекты"),
        ("wrench.and.screwdriver.fill", "Future Engineers", "Инженерные курсы, кейсы MASHSTROY, ARAI AI, IKEN, ATA MURA"),
        ("figure.roll", "Inclusive Engineering", "Инженерные решения для людей с особыми потребностями")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    stats
                    KSectionHeader(title: "Направления", icon: "square.grid.2x2.fill")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                        ForEach(initiatives, id: \.1) { item in
                            KCard {
                                Label(item.1, systemImage: item.0).font(.headline).foregroundStyle(.tint)
                                Text(item.2).font(.callout).foregroundStyle(.secondary)
                            }
                        }
                    }
                    KSectionHeader(title: "Образовательные программы", icon: "books.vertical.fill")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(store.db.programs) { program in
                                KCard {
                                    Image(systemName: program.direction.icon).foregroundStyle(.tint)
                                    Text(program.title).font(.headline)
                                    Text("\(program.ageRange) лет · \(program.durationWeeks) нед. · \(program.format.title)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(width: 230)
                            }
                        }
                    }
                    KSectionHeader(title: "Ближайшие мероприятия", icon: "calendar")
                    ForEach(store.db.events.filter { $0.date > Date() }.sorted { $0.date < $1.date }) { event in
                        KCard {
                            Text(event.title).font(.headline)
                            Text("\(event.kind.title) · \(event.date.kksuDateTime) · \(event.location)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    KSectionHeader(title: "Партнёры", icon: "handshake.fill")
                    Text(store.db.partners.map(\.name).joined(separator: " · "))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 12) {
                        NavigationLink {
                            EnrollmentApplicationView()
                        } label: {
                            Label("Подать заявку на обучение", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        NavigationLink {
                            ImpactPublicView()
                        } label: {
                            Label("Наш Impact — публичный отчёт", systemImage: "megaphone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        NavigationLink {
                            AccessibilitySettingsView()
                        } label: {
                            Label("Настройки доступности", systemImage: "textformat.size")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("KKSU Online")
            .kksuRoutes()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Войти") { showLogin = true }
                }
            }
            .sheet(isPresented: $showLogin) { LoginView() }
            .sheet(isPresented: $showRegistration) {
                NavigationStack { RegistrationView() }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Комфортная школа-университет")
                .font(.largeTitle.bold())
                .foregroundStyle(.tint)
            Text("Инклюзивная онлайн-платформа KKSU: обучение в своём темпе, изобретательство, инженерия, международные проекты и AI-поддержка для каждого ученика.")
                .font(.body)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                PrimaryButton(title: "Войти", icon: "arrow.right.circle.fill") { showLogin = true }
                PrimaryButton(title: "Регистрация", icon: "person.badge.plus", style: .outlined) { showRegistration = true }
            }
        }
        .padding(20)
        .background(KKSUTheme.softBlue.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
    }

    private var stats: some View {
        let m = ImpactMetrics(db: store.db)
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            KStatTile(title: "Учеников", value: "\(m.students)", icon: "graduationcap.fill")
            KStatTile(title: "Проектов", value: "\(m.projects)", icon: "lightbulb.fill", color: KKSUTheme.accent)
            KStatTile(title: "Партнёров", value: "\(m.partners)", icon: "handshake.fill", color: KKSUTheme.success)
            KStatTile(title: "Стран", value: "\(m.countries)", icon: "globe", color: .purple)
        }
    }
}

// MARK: - Вкладки после входа

struct KKSUMainView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                KKSURoute.cabinet(for: store.role).destination
                    .kksuRoutes()
            }
            .tabItem { Label("Кабинет", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                ModulesHubView()
                    .kksuRoutes()
            }
            .tabItem { Label("Модули", systemImage: "square.grid.2x2.fill") }
            .tag(1)

            NavigationStack {
                ChatListView()
                    .kksuRoutes()
            }
            .tabItem { Label("Чат", systemImage: "bubble.left.and.bubble.right.fill") }
            .tag(2)

            NavigationStack {
                NotificationsView()
                    .kksuRoutes()
            }
            .tabItem { Label("Уведомления", systemImage: "bell.fill") }
            .badge(store.unreadCount)
            .tag(3)

            NavigationStack {
                AccountView()
                    .kksuRoutes()
            }
            .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            .tag(4)
        }
    }
}

// MARK: - Хаб модулей

struct ModulesHubView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.kksuAccessibility) private var a11y
    @State private var query = ""

    private var sections: [KKSUModuleSection] {
        KKSUModuleSection.all.compactMap { section in
            let routes = section.routes.filter { route in
                route.isAvailable(for: store.role) &&
                (query.isEmpty || route.title.localizedCaseInsensitiveContains(query))
            }
            return routes.isEmpty ? nil : KKSUModuleSection(title: section.title, routes: routes)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title).font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: a11y.simplifiedInterface ? 220 : 150), spacing: 10)], spacing: 10) {
                            ForEach(section.routes) { route in
                                RouteTile(route: route)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .searchable(text: $query, prompt: "Найти модуль")
        .navigationTitle("Модули KKSU")
    }
}

// MARK: - Аккаунт

struct AccountView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var confirmReset = false

    var body: some View {
        List {
            if let user = store.currentUser {
                Section {
                    HStack(spacing: 14) {
                        KAvatar(name: user.fullName, size: 56)
                        VStack(alignment: .leading) {
                            Text(user.fullName).font(.headline)
                            Text(user.email).font(.caption).foregroundStyle(.secondary)
                            KBadge(text: user.role.title)
                        }
                    }
                }
                Section("Оплата") {
                    RouteRow(route: .paymentHistory, subtitle: "Счета, чеки, статусы, возвраты")
                    RouteRow(route: .marketplace, subtitle: "Курсы, программы, подписки")
                    RouteRow(route: .subscriptions)
                }
                Section("Мои данные") {
                    if user.role == .student { RouteRow(route: .studentProfile) }
                    RouteRow(route: .certificates)
                    RouteRow(route: .history)
                }
                Section("Персонализация") {
                    RouteRow(route: .accessibility, subtitle: "Размер текста, контраст, субтитры")
                    RouteRow(route: .learningSettings, subtitle: "Темп, форматы, цели")
                    RouteRow(route: .aiAssistant)
                }
                Section("Платформа") {
                    RouteRow(route: .featureMap, subtitle: "Все 125 модулей KKSU Online")
                    RouteRow(route: .impactPublic)
                    Button("Сбросить демо-данные", role: .destructive) { confirmReset = true }
                    Button("Выйти", role: .destructive) { store.logout() }
                }
            }
        }
        .navigationTitle("Профиль")
        .confirmationDialog("Вернуть демо-данные к исходному состоянию?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Сбросить", role: .destructive) { store.resetDemoData() }
        }
    }
}

// MARK: - Карта 100 задач

struct FeatureMapView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var query = ""

    private var features: [KKSUFeature] {
        query.isEmpty ? KKSUFeature.all : KKSUFeature.all.filter {
            $0.title.localizedCaseInsensitiveContains(query) || "\($0.id)" == query
        }
    }

    var body: some View {
        List {
            Section {
                Text("Все 100 технических задач KKSU Online и 25 задач монетизации (101–125) реализованы в приложении. Нажмите на задачу, чтобы открыть соответствующий модуль.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(features) { feature in
                NavigationLink(value: feature.route) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(feature.id)")
                            .font(.caption.bold().monospacedDigit())
                            .frame(width: 30, height: 30)
                            .background(KKSUTheme.softBlue, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title).font(.callout)
                            Text(feature.note.isEmpty ? feature.route.title : feature.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: feature.route.isAvailable(for: store.role) ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundStyle(feature.route.isAvailable(for: store.role) ? KKSUTheme.success : .secondary)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Номер или название")
        .navigationTitle("Карта 100 задач")
    }
}

// MARK: - Исходные прототипы экранов

struct LegacyScreensView: View {
    var body: some View {
        List {
            Section("Первые прототипы Comfort School-University") {
                NavigationLink("Моё обучение") { LearningView() }
                NavigationLink("Моя траектория и прогресс") { StudentProgressView() }
                NavigationLink("Курс «Математика»") { MathCourseView() }
                NavigationLink("Задание с автопроверкой") { StudentTaskView() }
            }
        }
        .navigationTitle("Прототипы экранов")
    }
}
