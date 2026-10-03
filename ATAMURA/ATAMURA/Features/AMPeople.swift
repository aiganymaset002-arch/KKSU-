//
//  AMPeople.swift
//  ATA MURA
//
//  ATA MURA PEOPLE: профиль-портфолио (Inventor, Researcher…), счётчики проектов,
//  статей, историй и изобретений, «Invite to project», каталог участников и настройки.
//

import SwiftUI

struct AMMyProfileView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        NavigationStack {
            if let user = store.currentUser {
                AMProfileView(userId: user.id)
            }
        }
    }
}

struct AMProfileView: View {
    @EnvironmentObject private var store: AMStore
    let userId: UUID
    @State private var showEdit = false
    @State private var showInvite = false
    @State private var showReport = false

    var body: some View {
        if let user = store.user(userId) {
            let isMe = user.id == store.currentUser?.id
            let stats = store.stats(for: user.id)
            List {
                Section {
                    VStack(spacing: 10) {
                        AMAvatar(user: user, size: 96)
                        Text(user.fullName.uppercased()).font(.title2.bold()).multilineTextAlignment(.center)
                        if !user.titles.isEmpty {
                            AMFlowLayout {
                                ForEach(user.titles, id: \.self) { AMTag(text: $0) }
                            }
                        }
                        HStack {
                            Label(user.level.title, systemImage: user.level.icon)
                            Text("· \(user.points) pts")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(AMTheme.skyDeep)
                        if !user.city.isEmpty || user.region != nil {
                            Label([user.city, user.region?.title ?? ""].filter { !$0.isEmpty }.joined(separator: ", "), systemImage: "mappin")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if !user.bio.isEmpty { Text(user.bio).font(.callout).multilineTextAlignment(.center) }
                        if user.role.isStaff { AMTag(text: user.role.title, icon: "shield.fill", color: AMTheme.gold) }
                    }
                    .frame(maxWidth: .infinity)
                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            AMStatTile(value: "\(stats.projects)", title: "Projects")
                            AMStatTile(value: "\(stats.articles)", title: "Articles")
                        }
                        GridRow {
                            AMStatTile(value: "\(stats.stories)", title: "Historical stories")
                            AMStatTile(value: "\(stats.inventions)", title: "Inventions")
                        }
                    }
                    if !user.skills.isEmpty {
                        Text(L("profile.skills") + ": " + user.skills.joined(separator: ", ")).font(.caption)
                    }
                    if user.isMentor {
                        Label(L("profile.mentor") + ": " + user.expertise.joined(separator: ", "), systemImage: "graduationcap").font(.caption)
                    }
                    if !user.orcid.isEmpty {
                        AMLinkButton(title: "ORCID \(user.orcid)", url: "https://orcid.org/\(user.orcid)", icon: "person.text.rectangle")
                    }
                    if !isMe {
                        Button { showInvite = true } label: { Label("Invite to project", systemImage: "person.badge.plus") }
                            .buttonStyle(.borderedProminent)
                            .disabled(store.db.projects.filter { $0.ownerId == store.currentUser?.id }.isEmpty)
                    }
                }
                portfolio(user)
                if isMe { mySections(user) }
            }
            .navigationTitle(isMe ? L("tab.profile") : user.fullName)
            .toolbar {
                if isMe {
                    Button(L("common.edit")) { showEdit = true }
                } else {
                    Menu {
                        Button { showReport = true } label: { Label(L("report.title"), systemImage: "flag") }
                        Button(role: .destructive) { store.block(user.id) } label: { Label(L("profile.block"), systemImage: "hand.raised") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showEdit) { NavigationStack { AMProfileEditorView() } }
            .sheet(isPresented: $showInvite) { NavigationStack { AMInviteView(user: user) } }
            .sheet(isPresented: $showReport) { AMReportSheet(targetId: user.id, title: user.fullName, authorId: user.id) }
        } else {
            AMEmptyState(icon: "person.slash", text: L("common.notFound"))
        }
    }

    @ViewBuilder
    private func portfolio(_ user: AMUser) -> some View {
        let projects = store.visibleProjects.filter { $0.ownerId == user.id }
        let posts = store.visiblePosts.filter { $0.authorId == user.id }
        let research = store.visibleResearch.filter { $0.ownerId == user.id }
        if !projects.isEmpty {
            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink { AMProjectDetailView(projectId: project.id) } label: {
                        Label(project.title, systemImage: "lightbulb")
                    }
                }
            }
        }
        if !research.isEmpty {
            Section("Research") {
                ForEach(research) { article in
                    NavigationLink { AMResearchDetailView(articleId: article.id) } label: { Label(article.title, systemImage: "doc.text") }
                }
            }
        }
        if !posts.isEmpty {
            Section(L("profile.posts")) {
                ForEach(posts) { post in
                    NavigationLink { AMPostDetailView(postId: post.id) } label: {
                        HStack {
                            Label(post.title, systemImage: post.type.icon)
                            Spacer()
                            AMStatusBadge(status: post.status)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func mySections(_ user: AMUser) -> some View {
        Section(L("profile.my")) {
            NavigationLink { AMMyCoursesView() } label: { Label("My Courses", systemImage: "graduationcap") }
            NavigationLink { AMQuestView() } label: { Label("ATA MURA QUEST", systemImage: "flag.checkered") }
            NavigationLink { AMOrdersView() } label: { Label(L("orders.title"), systemImage: "creditcard") }
            NavigationLink { AMNotificationsList() } label: {
                Label(L("notifications.title"), systemImage: "bell").badge(store.unreadCount)
            }
        }
        if store.isStaff {
            Section {
                NavigationLink { AMAdminHome() } label: {
                    Label(L("admin.title"), systemImage: "shield.lefthalf.filled").bold()
                }
                .badge(store.pendingModerationCount)
            }
        }
        Section {
            NavigationLink { AMSettingsView() } label: { Label(L("settings.title"), systemImage: "gearshape") }
        }
    }
}

/// Уведомления внутри навигации профиля.
struct AMNotificationsList: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            if store.myNotifications.isEmpty { AMEmptyState(icon: "bell.slash", text: L("notifications.empty")) }
            ForEach(store.myNotifications) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.headline)
                    Text(item.body).font(.callout).foregroundStyle(.secondary)
                    Text(item.date.amRelative).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle(L("notifications.title"))
        .onDisappear { store.markNotificationsRead() }
    }
}

struct AMProfileEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var user = AMUser(fullName: "", email: "")

    var body: some View {
        Form {
            Section {
                AMSinglePhotoPicker(title: L("profile.photo"), image: $user.avatar)
                TextField(L("auth.name"), text: $user.fullName)
                TextField(L("profile.city"), text: $user.city)
                Picker(L("common.region"), selection: $user.region) {
                    Text(L("common.notSelected")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
                AMTextArea(title: L("profile.bio"), text: $user.bio, minHeight: 80)
            }
            Section(L("profile.portfolio")) {
                AMListField(title: L("profile.titlesHint"), items: $user.titles)
                AMListField(title: L("profile.skills"), items: $user.skills)
                TextField("ORCID", text: $user.orcid)
            }
            Section {
                Toggle(L("profile.mentorToggle"), isOn: $user.isMentor)
                if user.isMentor {
                    AMListField(title: L("profile.expertise"), items: $user.expertise)
                }
            } footer: {
                Text(L("profile.mentorHint"))
            }
        }
        .navigationTitle(L("common.edit"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    let edited = user
                    store.updateCurrentUser { current in
                        current.fullName = edited.fullName
                        current.city = edited.city
                        current.region = edited.region
                        current.bio = edited.bio
                        current.titles = edited.titles
                        current.skills = edited.skills
                        current.orcid = edited.orcid
                        current.isMentor = edited.isMentor
                        current.expertise = edited.expertise
                        current.avatar = edited.avatar
                    }
                    dismiss()
                }
                .disabled(user.fullName.isEmpty)
            }
        }
        .onAppear { if let current = store.currentUser { user = current } }
    }
}

struct AMInviteView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    let user: AMUser
    @State private var projectId: UUID?
    @State private var message = ""

    var body: some View {
        let myProjects = store.db.projects.filter { $0.ownerId == store.currentUser?.id }
        Form {
            Section(L("invite.project")) {
                Picker(L("invite.project"), selection: $projectId) {
                    Text(L("common.notSelected")).tag(UUID?.none)
                    ForEach(myProjects) { Text($0.title).tag(UUID?.some($0.id)) }
                }
            }
            Section(L("invite.message")) {
                AMTextArea(title: L("invite.message"), text: $message, minHeight: 80)
            }
            Section {
                Button(L("invite.send")) {
                    if let project = myProjects.first(where: { $0.id == projectId }) {
                        store.invite(user.id, to: project, message: message)
                    }
                    dismiss()
                }
                .disabled(projectId == nil)
            }
        }
        .navigationTitle("Invite to project")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } } }
    }
}

/// Каталог: изобретатели, исследователи, наставники.
struct AMPeopleView: View {
    @EnvironmentObject private var store: AMStore
    @State private var onlyMentors = false
    @State private var query = ""

    private var people: [AMUser] {
        store.db.users
            .filter { !$0.blocked && store.currentUser?.blockedUsers.contains($0.id) != true }
            .filter { !onlyMentors || $0.isMentor }
            .filter { query.isEmpty || $0.fullName.localizedCaseInsensitiveContains(query) || $0.skills.joined(separator: " ").localizedCaseInsensitiveContains(query) }
            .sorted { $0.points > $1.points }
    }

    var body: some View {
        List {
            Toggle(L("people.onlyMentors"), isOn: $onlyMentors)
            ForEach(people) { user in
                NavigationLink { AMProfileView(userId: user.id) } label: {
                    HStack {
                        AMAvatar(user: user, size: 42)
                        VStack(alignment: .leading) {
                            Text(user.fullName).font(.headline)
                            Text(([user.level.title] + user.titles).joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(user.points)").font(.caption.bold()).monospacedDigit()
                    }
                }
            }
        }
        .searchable(text: $query)
        .navigationTitle("ATA MURA PEOPLE")
    }
}

// MARK: - Настройки

struct AMSettingsView: View {
    @EnvironmentObject private var store: AMStore
    @ObservedObject private var cloud = AMCloud.shared
    @ObservedObject private var ai = AMAI.shared
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section(L("settings.language")) {
                AMLanguagePicker()
            }
            Section {
                AMInclusiveModePicker(mode: $store.inclusiveMode)
            } header: {
                Text(L("inclusive.title"))
            }
            Section {
                Toggle(L("cloud.enable"), isOn: $cloud.enabled)
                if cloud.enabled {
                    TextField("Project URL", text: $cloud.projectURL).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("Publishable key", text: $cloud.anonKey).textInputAutocapitalization(.never)
                    Label(cloud.status.title, systemImage: "icloud").font(.caption)
                    if cloud.isSignedIn {
                        Button(L("cloud.syncNow")) { Task { await cloud.sync() } }
                        if store.isStaff {
                            Button(L("cloud.uploadStarter")) { Task { await cloud.uploadStarterContent() } }
                        }
                    } else {
                        Text(L("cloud.signInHint")).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(L("cloud.title"))
            } footer: {
                Text(L("cloud.footer"))
            }
            Section {
                SecureField("Claude API key", text: $ai.apiKey)
                TextField(L("ai.endpoint"), text: $ai.endpoint).textInputAutocapitalization(.never).keyboardType(.URL)
                Text(ai.isConfigured ? L("ai.connected") : L("ai.localMode")).font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("AI ATA MURA")
            } footer: {
                Text(L("ai.footer"))
            }
            Section {
                Button(L("auth.logout")) { store.logout() }
                Button(L("settings.deleteAccount"), role: .destructive) { confirmDelete = true }
            } footer: {
                Text(L("settings.deleteHint"))
            }
            Section {
                Text("ATA MURA v1.0 — Heritage creates innovation.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L("settings.title"))
        .confirmationDialog(L("settings.deleteConfirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L("settings.deleteAccount"), role: .destructive) { store.deleteMyAccount() }
        }
    }
}
