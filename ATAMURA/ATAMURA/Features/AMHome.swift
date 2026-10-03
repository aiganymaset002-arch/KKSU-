//
//  AMHome.swift
//  ATA MURA
//
//  Главный экран «Explore Kazakhstan»: поиск, разделы, лента «Сегодня в ATA MURA»,
//  кнопка + CREATE и уведомления.
//

import SwiftUI

struct AMHomeView: View {
    var body: some View {
        NavigationStack { AMHomeScreen() }
    }
}

struct AMHomeSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct AMHomeScreen: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.amMode) private var mode
    @State private var query = ""
    @State private var showCreate = false
    @State private var showNotifications = false

    private var sections: [AMHomeSection] {
        [
            AMHomeSection(id: "tarih", title: "TARIH", subtitle: L("home.tarih"), icon: "book.closed.fill", color: AMTheme.skyDeep),
            AMHomeSection(id: "stories", title: "STORIES", subtitle: L("home.stories"), icon: "person.2.fill", color: .orange),
            AMHomeSection(id: "invent", title: "INVENT", subtitle: L("home.invent"), icon: "lightbulb.max.fill", color: AMTheme.gold),
            AMHomeSection(id: "map", title: "MAP", subtitle: L("home.map"), icon: "map.fill", color: .green),
            AMHomeSection(id: "museum", title: "MUSEUM", subtitle: "Digital Museum", icon: "building.columns.fill", color: .brown),
            AMHomeSection(id: "research", title: "RESEARCH", subtitle: L("home.research"), icon: "doc.text.magnifyingglass", color: .indigo),
            AMHomeSection(id: "kids", title: "KIDS LAB", subtitle: "Young Inventors", icon: "paintpalette.fill", color: .pink),
            AMHomeSection(id: "inclusive", title: "INCLUSIVE", subtitle: "Inclusive Engineering", icon: "figure.roll", color: .teal),
            AMHomeSection(id: "academy", title: "ACADEMY", subtitle: L("home.academy"), icon: "graduationcap.fill", color: .purple),
            AMHomeSection(id: "magazine", title: "MAGAZINE", subtitle: "ATA MURA Magazine", icon: "magazine.fill", color: .red),
            AMHomeSection(id: "news", title: "NEWS", subtitle: L("home.news"), icon: "newspaper.fill", color: .gray),
            AMHomeSection(id: "quest", title: "QUEST", subtitle: L("home.quest"), icon: "flag.checkered", color: .mint),
            AMHomeSection(id: "forgotten", title: "FORGOTTEN IDEAS", subtitle: L("home.forgotten"), icon: "arrow.triangle.branch", color: .cyan),
            AMHomeSection(id: "people", title: "PEOPLE", subtitle: L("home.people"), icon: "person.3.fill", color: .blue),
            AMHomeSection(id: "market", title: "MARKETPLACE", subtitle: L("home.market"), icon: "cart.fill", color: .orange)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if query.count >= 2 {
                    AMSearchResultsView(results: store.search(query)).buttonStyle(.plain)
                } else {
                    hero
                    if !store.myInvites.isEmpty { invites }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: mode == .lowVision ? 220 : 150), spacing: 10)], spacing: 10) {
                        ForEach(sections) { section in
                            NavigationLink {
                                destination(section.id)
                            } label: {
                                sectionTile(section)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        showCreate = true
                    } label: {
                        Label("CREATE", systemImage: "plus.circle.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AMTheme.gold)
                    .foregroundStyle(AMTheme.night)
                    AMSectionHeader(title: L("home.today"), icon: "sun.max.fill")
                    AMFeedList(items: Array(store.feed.prefix(25)))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ATA MURA")
        .searchable(text: $query, prompt: L("home.search"))
        .toolbar {
            if store.isStaff {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        AMAdminHome()
                    } label: {
                        Label(L("admin.title"), systemImage: "shield.lefthalf.filled")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: store.unreadCount > 0 ? "bell.badge.fill" : "bell")
                }
                .accessibilityLabel(L("notifications.title"))
            }
        }
        .sheet(isPresented: $showCreate) { AMCreateMenu() }
        .sheet(isPresented: $showNotifications) { AMNotificationsView() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explore Kazakhstan").font(.title2.bold())
                    Text(L("home.hello", store.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? ""))
                        .font(.subheadline)
                }
                Spacer()
                if mode != .asd { AMLogo(size: 54) }
            }
            if let user = store.currentUser {
                HStack {
                    Image(systemName: user.level.icon)
                    Text("\(user.level.title) · \(user.points) pts")
                }
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.white.opacity(0.2), in: Capsule())
            }
            Text("Preserve the past. Research the present. Invent the future.").font(.caption).opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mode == .asd ? AnyShapeStyle(AMTheme.calm) : AnyShapeStyle(AMTheme.heroGradient), in: RoundedRectangle(cornerRadius: 20))
    }

    private var invites: some View {
        AMCard {
            Label(L("invite.title"), systemImage: "envelope.badge.fill").font(.headline)
            ForEach(store.myInvites) { invite in
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("notify.invite.body", invite.fromName, invite.projectTitle)).font(.callout)
                    if !invite.message.isEmpty { Text(invite.message).font(.caption).foregroundStyle(.secondary) }
                    HStack {
                        Button(L("invite.accept")) { store.answer(invite: invite.id, accept: true) }.buttonStyle(.borderedProminent)
                        Button(L("invite.decline")) { store.answer(invite: invite.id, accept: false) }.buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func sectionTile(_ section: AMHomeSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: section.icon).font(.title2).foregroundStyle(mode == .asd ? AMTheme.calm : section.color)
            Text(section.title).font(.headline)
            Text(section.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func destination(_ id: String) -> some View {
        switch id {
        case "tarih": AMTarihView()
        case "stories": AMStoriesView()
        case "invent": AMInventorsLabView()
        case "map": AMMapScreen()
        case "museum": AMMuseumView()
        case "research": AMResearchListView()
        case "kids": AMKidsLabView()
        case "inclusive": AMInclusiveHubView()
        case "academy": AMAcademyView()
        case "magazine": AMMagazineListView()
        case "news": AMNewsListView()
        case "quest": AMQuestView()
        case "forgotten": AMForgottenIdeasView()
        case "people": AMPeopleView()
        default: AMMarketplaceView()
        }
    }
}

// MARK: - Лента

struct AMFeedList: View {
    @EnvironmentObject private var store: AMStore
    let items: [AMFeedItem]

    var body: some View {
        if items.isEmpty {
            AMEmptyState(icon: "sun.horizon", text: L("feed.empty"))
        }
        ForEach(items) { item in
            NavigationLink {
                AMFeedDestination(item: item)
            } label: {
                AMCard {
                    HStack {
                        AMTag(text: item.label)
                        if item.pinned { Image(systemName: "pin.fill").foregroundStyle(AMTheme.gold) }
                        Spacer()
                        Text(item.date.amRelative).font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(item.title).font(.headline).multilineTextAlignment(.leading)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle).font(.callout).foregroundStyle(.secondary).lineLimit(3).multilineTextAlignment(.leading)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct AMFeedDestination: View {
    @EnvironmentObject private var store: AMStore
    let item: AMFeedItem

    var body: some View {
        switch item.kind {
        case .news:
            if let news = store.db.news.first(where: { $0.id == item.id }) { AMNewsDetailView(news: news) }
        case .magazine:
            if let issue = store.db.magazines.first(where: { $0.id == item.id }) { AMMagazineDetailView(issue: issue) }
        case .post:
            AMPostDetailView(postId: item.id)
        case .project:
            AMProjectDetailView(projectId: item.id)
        case .course:
            if let course = store.db.courses.first(where: { $0.id == item.id }) { AMCourseDetailView(courseId: course.id) }
        case .research:
            AMResearchDetailView(articleId: item.id)
        case .museum:
            AMMuseumDetailView(itemId: item.id)
        case .kids:
            AMKidsLabView()
        }
    }
}

// MARK: - Поиск

struct AMSearchResultsView: View {
    let results: AMStore.SearchResults

    var body: some View {
        if results.isEmpty {
            AMEmptyState(icon: "magnifyingglass", text: L("search.empty"))
        }
        if !results.topics.isEmpty {
            AMSectionHeader(title: L("search.topics"), icon: "books.vertical")
            ForEach(results.topics) { topic in
                NavigationLink { AMTopicView(topic: topic) } label: { row(topic.title, topic.summary, "books.vertical") }
            }
        }
        if !results.posts.isEmpty {
            AMSectionHeader(title: "TARIH", icon: "book.closed")
            ForEach(results.posts) { post in
                NavigationLink { AMPostDetailView(postId: post.id) } label: { row(post.title, post.type.title, post.type.icon) }
            }
        }
        if !results.places.isEmpty {
            AMSectionHeader(title: L("search.places"), icon: "mappin")
            ForEach(results.places) { place in
                NavigationLink { AMPlaceDetailView(place: place) } label: { row(place.title, place.region.title, place.kind.icon) }
            }
        }
        if !results.projects.isEmpty {
            AMSectionHeader(title: "Inventors Lab", icon: "lightbulb")
            ForEach(results.projects) { project in
                NavigationLink { AMProjectDetailView(projectId: project.id) } label: { row(project.title, project.stage.title, "lightbulb") }
            }
        }
        if !results.museum.isEmpty {
            AMSectionHeader(title: "Digital Museum", icon: "building.columns")
            ForEach(results.museum) { item in
                NavigationLink { AMMuseumDetailView(itemId: item.id) } label: { row(item.title, item.period, "building.columns") }
            }
        }
        if !results.research.isEmpty {
            AMSectionHeader(title: "Research", icon: "doc.text")
            ForEach(results.research) { article in
                NavigationLink { AMResearchDetailView(articleId: article.id) } label: { row(article.title, article.authors, "doc.text") }
            }
        }
        if !results.people.isEmpty {
            AMSectionHeader(title: "People", icon: "person.3")
            ForEach(results.people) { user in
                NavigationLink { AMProfileView(userId: user.id) } label: { row(user.fullName, user.titles.joined(separator: " · "), "person") }
            }
        }
    }

    private func row(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        AMCard {
            Label {
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                }
            } icon: {
                Image(systemName: icon)
            }
        }
    }
}

// MARK: - + CREATE

struct AMCreateMenu: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AMStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { AMPostEditorView(type: .history) } label: { Label(L("create.history"), systemImage: "book.closed") }
                    NavigationLink { AMPostEditorView(type: .familyStory) } label: { Label(L("create.story"), systemImage: "person.2") }
                    NavigationLink { AMResearchEditorView() } label: { Label(L("create.article"), systemImage: "doc.text") }
                    NavigationLink { AMPostEditorView(type: .hypothesis, evidence: .hypothesis) } label: { Label(L("create.theory"), systemImage: "questionmark.bubble") }
                    NavigationLink { AMPostEditorView(type: .archive, evidence: .archive) } label: { Label(L("create.archive"), systemImage: "archivebox") }
                }
                Section {
                    NavigationLink { AMProjectEditorView() } label: { Label(L("create.invention"), systemImage: "lightbulb") }
                    NavigationLink { AMKidsWorkEditorView(theme: nil) } label: { Label(L("create.kids"), systemImage: "paintpalette") }
                    NavigationLink { AMMuseumEditorView() } label: { Label(L("create.museum"), systemImage: "building.columns") }
                }
                Section {
                    NavigationLink { AMPostEditorView(type: .person) } label: { Label(L("create.person"), systemImage: "person.badge.plus") }
                    NavigationLink { AMPlaceEditorView() } label: { Label(L("create.place"), systemImage: "mappin.and.ellipse") }
                    NavigationLink { AMPostEditorView(type: .culture) } label: { Label(L("create.post"), systemImage: "text.bubble") }
                }
                if store.isStaff {
                    Section(L("admin.title")) {
                        NavigationLink { AMNewsEditorView(news: AMNews()) } label: { Label(L("create.news"), systemImage: "newspaper") }
                    }
                }
            }
            .navigationTitle("+ CREATE")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("common.close")) { dismiss() } }
            }
        }
    }
}

// MARK: - Уведомления

struct AMNotificationsView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.myNotifications.isEmpty {
                    AMEmptyState(icon: "bell.slash", text: L("notifications.empty"))
                }
                ForEach(store.myNotifications) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if !item.read { Circle().fill(AMTheme.sky).frame(width: 8, height: 8) }
                            Text(item.title).font(.headline)
                        }
                        Text(item.body).font(.callout).foregroundStyle(.secondary)
                        Text(item.date.amRelative).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle(L("notifications.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("common.close")) { dismiss() } }
            }
            .onDisappear { store.markNotificationsRead() }
        }
    }
}
