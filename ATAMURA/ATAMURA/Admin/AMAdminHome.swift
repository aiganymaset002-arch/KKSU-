//
//  AMAdminHome.swift
//  ATA MURA
//
//  Закрытая админ-панель (только редакторы и администраторы): Morning Dashboard,
//  Creator Studio, публикации, модерация, журнал, курсы, заказы, аналитика.
//  Обычные пользователи этот раздел не видят.
//

import SwiftUI

struct AMAdminHome: View {
    @EnvironmentObject private var store: AMStore

    private let groups: [(String, [AMAdminSection])] = [
        ("admin.group.studio", [.calendar, .vlog, .ideas, .series, .guests, .media, .tasks, .analytics]),
        ("admin.group.publishing", [.news, .magazine, .moderation, .posts, .research, .map]),
        ("admin.group.platform", [.projects, .museum, .courses, .orders, .marketplace, .events, .partners, .users])
    ]

    var body: some View {
        if store.isStaff {
            List {
                Section {
                    AMMorningDashboard()
                } header: {
                    Text("Morning Dashboard")
                }
                ForEach(groups, id: \.0) { group in
                    Section(L(group.0)) {
                        ForEach(group.1) { section in
                            NavigationLink { AMAdminDestination(section: section) } label: {
                                HStack {
                                    Label(section.title, systemImage: section.icon)
                                    Spacer()
                                    if let badge = badge(section), badge > 0 {
                                        Text("\(badge)").font(.caption.bold()).padding(.horizontal, 7).padding(.vertical, 2)
                                            .background(AMTheme.gold, in: Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("admin.title"))
        } else {
            AMEmptyState(icon: "lock.fill", text: L("admin.noAccess"))
        }
    }

    private func badge(_ section: AMAdminSection) -> Int? {
        switch section {
        case .moderation: return store.pendingModerationCount
        case .orders: return store.db.orders.filter { $0.status == .pending }.count
        case .research: return store.db.research.filter { $0.reviewStatus == .submitted }.count
        case .tasks: return store.db.tasks.filter { !$0.done }.count
        default: return nil
        }
    }
}

struct AMAdminDestination: View {
    let section: AMAdminSection

    var body: some View {
        switch section {
        case .dashboard: List { AMMorningDashboard() }.navigationTitle("Morning Dashboard")
        case .calendar: AMContentCalendarView()
        case .vlog: AMVlogDiaryView()
        case .ideas: AMIdeaBankView()
        case .series: AMSeriesAdminView()
        case .guests: AMGuestsView()
        case .news: AMNewsAdminView()
        case .magazine: AMMagazineAdminView()
        case .courses: AMCoursesAdminView()
        case .orders: AMOrdersAdminView()
        case .moderation: AMModerationView()
        case .posts: AMPostsAdminView()
        case .projects: AMProjectsAdminView()
        case .museum: AMMuseumAdminView()
        case .research: AMResearchAdminView()
        case .users: AMUsersAdminView()
        case .events: AMEventsAdminView()
        case .partners: AMPartnersAdminView()
        case .marketplace: AMProductsAdminView()
        case .media: AMMediaLibraryView()
        case .analytics: AMAnalyticsView()
        case .tasks: AMTasksView()
        case .map: AMMapAdminView()
        }
    }
}

/// «Сегодня: дописать сценарий, подтвердить интервью, проверить статьи…»
struct AMMorningDashboard: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        let items = store.morningItems
        VStack(alignment: .leading, spacing: 4) {
            Text(L("morning.greeting", store.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? ""))
                .font(.headline)
            Text(Date().amDate).font(.caption).foregroundStyle(.secondary)
        }
        if items.isEmpty {
            Label(L("morning.clear"), systemImage: "sun.max").foregroundStyle(.secondary)
        }
        ForEach(items) { item in
            NavigationLink { AMAdminDestination(section: item.section) } label: {
                Label(item.text, systemImage: item.icon)
            }
        }
        HStack {
            AMStatTile(value: "\(store.db.users.count)", title: L("admin.stat.users"), icon: "person.3")
            AMStatTile(value: "\(store.db.posts.count)", title: L("admin.stat.posts"), icon: "text.bubble")
            AMStatTile(value: "\(store.db.projects.count)", title: L("admin.stat.projects"), icon: "lightbulb")
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
}
