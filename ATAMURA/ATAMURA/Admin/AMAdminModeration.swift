//
//  AMAdminModeration.swift
//  ATA MURA
//
//  MODERATION: одобрить, отклонить, отправить на доработку, отметить как «проверенный факт»,
//  «мнение автора», «гипотеза», «источник подтверждён». Жалобы, публикации и книга
//  «100 Stories», проекты (проект недели), музей, исследования, пользователи,
//  справочники карты и энциклопедии.
//

import SwiftUI

struct AMModerationView: View {
    @EnvironmentObject private var store: AMStore
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("TARIH").tag(0)
                Text(L("moderation.other")).tag(1)
                Text(L("moderation.reports")).tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            switch tab {
            case 0: postsQueue
            case 1: otherQueue
            default: reportsQueue
            }
        }
        .navigationTitle(L("admin.moderation"))
    }

    private var postsQueue: some View {
        let pending = store.db.posts.filter { $0.status == .pending || $0.status == .needsRevision }.sorted { $0.createdAt < $1.createdAt }
        return List {
            if pending.isEmpty { AMEmptyState(icon: "checkmark.shield", text: L("moderation.empty")) }
            ForEach(pending) { post in
                NavigationLink { AMModeratePostView(postId: post.id) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            AMTag(text: post.type.title, icon: post.type.icon)
                            AMTag(text: post.evidence.title, color: .secondary)
                            AMStatusBadge(status: post.status)
                        }
                        Text(post.title).font(.headline)
                        Text("\(post.authorName) · \(post.createdAt.amRelative) · \(L("moderation.sources", post.sources.count))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var otherQueue: some View {
        List {
            let projects = store.db.projects.filter { $0.status == .pending }
            if !projects.isEmpty {
                Section("Inventors Lab") {
                    ForEach(projects) { project in
                        moderationRow(title: project.title, subtitle: project.ownerName, detail: project.problem) { status in
                            if let index = store.db.projects.firstIndex(where: { $0.id == project.id }) {
                                store.db.projects[index].status = status
                                store.notify(project.ownerId, title: L("notify.moderation.title"), body: "«\(project.title)» — \(status.title)")
                            }
                        }
                    }
                }
            }
            let museum = store.db.museum.filter { $0.status == .pending }
            if !museum.isEmpty {
                Section("Digital Museum") {
                    ForEach(museum) { item in
                        moderationRow(title: item.title, subtitle: item.ownerName, detail: item.story, image: item.photos.first) { status in
                            if let index = store.db.museum.firstIndex(where: { $0.id == item.id }) {
                                store.db.museum[index].status = status
                                store.notify(item.ownerId, title: L("notify.moderation.title"), body: "«\(item.title)» — \(status.title)")
                            }
                        }
                    }
                }
            }
            let kids = store.db.kidsWorks.filter { $0.status == .pending }
            if !kids.isEmpty {
                Section("KIDS LAB") {
                    ForEach(kids) { work in
                        moderationRow(title: work.title, subtitle: "\(work.ownerName) · \(work.format.title)", detail: work.summary, image: work.images.first) { status in
                            if let index = store.db.kidsWorks.firstIndex(where: { $0.id == work.id }) {
                                store.db.kidsWorks[index].status = status
                                store.notify(work.ownerId, title: L("notify.moderation.title"), body: "«\(work.title)» — \(status.title)")
                            }
                        }
                    }
                }
            }
            let places = store.db.places.filter { $0.status == .pending }
            if !places.isEmpty {
                Section("MAP") {
                    ForEach(places) { place in
                        moderationRow(title: place.title, subtitle: "\(place.kind.title) · \(place.region.title)", detail: place.summary, image: place.image) { status in
                            if let index = store.db.places.firstIndex(where: { $0.id == place.id }) {
                                store.db.places[index].status = status
                                if let author = place.authorId {
                                    store.notify(author, title: L("notify.moderation.title"), body: "«\(place.title)» — \(status.title)")
                                }
                            }
                        }
                    }
                }
            }
            if projects.isEmpty && museum.isEmpty && kids.isEmpty && places.isEmpty {
                AMEmptyState(icon: "checkmark.shield", text: L("moderation.empty"))
            }
        }
    }

    private func moderationRow(title: String, subtitle: String, detail: String, image: Data? = nil,
                               action: @escaping (AMModerationStatus) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let image { AMImageView(data: image, height: 120) }
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            if !detail.isEmpty { Text(detail).font(.callout).lineLimit(4) }
            HStack {
                Button(L("moderation.approve")) { action(.approved) }.buttonStyle(.borderedProminent).tint(AMTheme.success)
                Button(L("moderation.revise")) { action(.needsRevision) }.buttonStyle(.bordered)
                Button(L("moderation.reject")) { action(.rejected) }.buttonStyle(.bordered).tint(AMTheme.danger)
            }
            .font(.caption)
        }
    }

    private var reportsQueue: some View {
        let reports = store.db.reports.filter { !$0.resolved }.sorted { $0.date > $1.date }
        return List {
            if reports.isEmpty { AMEmptyState(icon: "flag", text: L("moderation.noReports")) }
            ForEach(reports) { report in
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.targetTitle).font(.headline)
                    Text(report.reason).font(.callout)
                    Text(report.date.amRelative).font(.caption2).foregroundStyle(.secondary)
                    HStack {
                        if store.db.posts.contains(where: { $0.id == report.targetId }) {
                            NavigationLink(L("moderation.open")) { AMModeratePostView(postId: report.targetId) }
                        }
                        Button(L("moderation.hide")) {
                            hide(report.targetId)
                            resolve(report.id)
                        }
                        .buttonStyle(.bordered).tint(AMTheme.danger)
                        Button(L("moderation.dismiss")) { resolve(report.id) }.buttonStyle(.bordered)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func resolve(_ id: UUID) {
        if let index = store.db.reports.firstIndex(where: { $0.id == id }) { store.db.reports[index].resolved = true }
    }

    /// Скрывает материал или блокирует пользователя, на которого пожаловались.
    private func hide(_ targetId: UUID) {
        if let index = store.db.posts.firstIndex(where: { $0.id == targetId }) { store.db.posts[index].status = .rejected }
        if let index = store.db.projects.firstIndex(where: { $0.id == targetId }) { store.db.projects[index].status = .rejected }
        if let index = store.db.museum.firstIndex(where: { $0.id == targetId }) { store.db.museum[index].status = .rejected }
        if let index = store.db.users.firstIndex(where: { $0.id == targetId }) { store.db.users[index].blocked = true }
        store.db.comments.removeAll { $0.id == targetId }
    }
}

/// Проверка публикации: метка достоверности, комментарий автору, решение.
struct AMModeratePostView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    let postId: UUID
    @State private var verification: AMVerification = .none
    @State private var note = ""

    var body: some View {
        if let post = store.db.posts.first(where: { $0.id == postId }) {
            Form {
                Section {
                    Text(post.title).font(.headline)
                    Text("\(post.type.title) · \(post.evidence.title) · \(post.authorName)").font(.caption)
                    AMImageStrip(images: post.images, height: 120)
                    Text(post.body).font(.callout)
                    if !post.videoURL.isEmpty { AMLinkButton(title: L("common.watchVideo"), url: post.videoURL) }
                }
                Section(L("tarih.sources")) {
                    if post.sources.isEmpty { Text(L("tarih.noSources")).foregroundStyle(.orange) }
                    ForEach(post.sources) { AMSourceRow(source: $0) }
                }
                Section(L("moderation.label")) {
                    Picker(L("moderation.label"), selection: $verification) {
                        ForEach(AMVerification.allCases, id: \.self) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section(L("moderation.note")) {
                    AMTextArea(title: L("moderation.noteHint"), text: $note, minHeight: 70)
                }
                Section {
                    Button { decide(.approved) } label: { Label(L("moderation.approve"), systemImage: "checkmark.seal.fill") }
                        .tint(AMTheme.success)
                    Button { decide(.needsRevision) } label: { Label(L("moderation.revise"), systemImage: "pencil.circle") }
                    Button(role: .destructive) { decide(.rejected) } label: { Label(L("moderation.reject"), systemImage: "xmark.octagon") }
                }
            }
            .navigationTitle(L("admin.moderation"))
            .onAppear {
                verification = post.verification == .none ? suggested(post.evidence) : post.verification
                note = post.moderatorNote
            }
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }

    private func suggested(_ evidence: AMEvidence) -> AMVerification {
        switch evidence {
        case .hypothesis: return .hypothesis
        case .interpretation, .oralHistory: return .authorOpinion
        default: return .none
        }
    }

    private func decide(_ status: AMModerationStatus) {
        store.moderate(postId: postId, status: status, verification: verification, note: note)
        dismiss()
    }
}

// MARK: - Публикации и книга

struct AMPostsAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var query = ""

    var body: some View {
        let posts = store.db.posts
            .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.authorName.localizedCaseInsensitiveContains(query) }
            .sorted { $0.createdAt > $1.createdAt }
        List {
            Section {
                Label(L("admin.bookCount", store.db.posts.filter(\.selectedForBook).count), systemImage: "book.fill")
            }
            ForEach(posts) { post in
                NavigationLink { AMModeratePostView(postId: post.id) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title).font(.headline)
                        HStack {
                            AMTag(text: post.type.title)
                            AMStatusBadge(status: post.status)
                            AMVerificationBadge(verification: post.verification)
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    if post.type == .familyStory || post.type == .person {
                        Button {
                            if let index = store.db.posts.firstIndex(where: { $0.id == post.id }) {
                                store.db.posts[index].selectedForBook.toggle()
                            }
                        } label: {
                            Label(L("admin.toBook"), systemImage: "book")
                        }
                        .tint(AMTheme.gold)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { store.deletePost(post.id) } label: { Label(L("common.delete"), systemImage: "trash") }
                }
            }
        }
        .searchable(text: $query)
        .navigationTitle(L("admin.posts"))
    }
}

// MARK: - Проекты, музей, исследования

struct AMProjectsAdminView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            if let week = store.projectOfWeek {
                Section("Young Inventor of the Week") {
                    Label(week.title, systemImage: "star.fill")
                }
            }
            ForEach(store.db.projects.sorted { $0.createdAt > $1.createdAt }) { project in
                HStack {
                    NavigationLink { AMProjectDetailView(projectId: project.id) } label: {
                        VStack(alignment: .leading) {
                            Text(project.title).font(.headline)
                            Text("\(project.ownerName) · \(project.stage.title)").font(.caption).foregroundStyle(.secondary)
                            AMStatusBadge(status: project.status)
                        }
                    }
                }
                .swipeActions {
                    Button { store.setProjectOfWeek(project.id) } label: { Label(L("project.makeWeek"), systemImage: "star") }
                        .tint(AMTheme.gold)
                    Button(role: .destructive) {
                        store.db.projects.removeAll { $0.id == project.id }
                    } label: { Label(L("common.delete"), systemImage: "trash") }
                }
            }
        }
        .navigationTitle(L("admin.projects"))
    }
}

struct AMMuseumAdminView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            ForEach(store.db.museum.sorted { $0.createdAt > $1.createdAt }) { item in
                NavigationLink { AMMuseumDetailView(itemId: item.id) } label: {
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text("\(item.ownerName) · \(item.period)").font(.caption).foregroundStyle(.secondary)
                        AMStatusBadge(status: item.status)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) { store.db.museum.removeAll { $0.id == item.id } } label: { Label(L("common.delete"), systemImage: "trash") }
                }
            }
            if store.db.museum.isEmpty { AMEmptyState(icon: "building.columns", text: L("museum.empty")) }
        }
        .navigationTitle("Digital Museum")
    }
}

struct AMResearchAdminView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            ForEach(AMReviewStatus.allCases, id: \.self) { status in
                let articles = store.db.research.filter { $0.reviewStatus == status }
                if !articles.isEmpty {
                    Section(status.title) {
                        ForEach(articles) { article in
                            NavigationLink { AMResearchDetailView(articleId: article.id) } label: {
                                VStack(alignment: .leading) {
                                    Text(article.title).font(.headline)
                                    Text(article.authors).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if store.db.research.isEmpty { AMEmptyState(icon: "doc.text", text: L("research.empty")) }
        }
        .navigationTitle("Research")
    }
}

// MARK: - Пользователи

struct AMUsersAdminView: View {
    @EnvironmentObject private var store: AMStore
    @ObservedObject private var cloud = AMCloud.shared
    @State private var query = ""
    @State private var error: String?

    var body: some View {
        let users = store.db.users
            .filter { query.isEmpty || $0.fullName.localizedCaseInsensitiveContains(query) || $0.email.localizedCaseInsensitiveContains(query) }
            .sorted { $0.createdAt > $1.createdAt }
        List {
            if let error { Text(error).foregroundStyle(AMTheme.danger) }
            ForEach(users) { user in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        AMAvatar(user: user, size: 36)
                        VStack(alignment: .leading) {
                            Text(user.fullName).font(.headline)
                            Text(user.email.isEmpty ? user.city : user.email).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(user.points) pts").font(.caption).monospacedDigit()
                    }
                    if store.isAdmin && user.id != store.currentUser?.id {
                        HStack {
                            Picker(L("users.role"), selection: Binding(get: { user.role }, set: { setRole(user.id, $0) })) {
                                ForEach(AMRole.allCases, id: \.self) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                            Toggle(L("users.blocked"), isOn: Binding(get: { user.blocked }, set: { setBlocked(user.id, $0) }))
                                .fixedSize()
                        }
                        .font(.caption)
                    } else {
                        AMTag(text: user.role.title)
                    }
                }
            }
        }
        .searchable(text: $query)
        .navigationTitle(L("admin.users"))
        .task { await cloud.loadMembers() }
    }

    private func setRole(_ id: UUID, _ role: AMRole) {
        if let index = store.db.users.firstIndex(where: { $0.id == id }) { store.db.users[index].role = role }
        guard cloud.isSignedIn else { return }
        Task {
            do { try await cloud.updateMember(id, role: role) } catch { self.error = error.localizedDescription }
        }
    }

    private func setBlocked(_ id: UUID, _ blocked: Bool) {
        if let index = store.db.users.firstIndex(where: { $0.id == id }) { store.db.users[index].blocked = blocked }
        guard cloud.isSignedIn else { return }
        Task {
            do { try await cloud.updateMember(id, blocked: blocked) } catch { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Карта и энциклопедия

struct AMMapAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var topic = AMTopic(title: "", summary: "")
    @State private var idea = AMForgottenIdea(title: "", year: "", author: "", summary: "")
    @State private var theme = AMKidsTheme(title: "", prompt: "")

    var body: some View {
        List {
            Section(L("mapadmin.topics")) {
                ForEach(store.db.topics) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text(item.keywords.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { store.db.topics.remove(atOffsets: $0) }
                TextField(L("editor.title"), text: $topic.title)
                TextField(L("place.summary"), text: $topic.summary, axis: .vertical)
                TextField(L("place.period"), text: $topic.period)
                AMListField(title: L("mapadmin.keywords"), items: $topic.keywords)
                Button(L("common.add")) {
                    store.db.topics.append(topic)
                    topic = AMTopic(title: "", summary: "")
                }
                .disabled(topic.title.isEmpty)
            }
            Section(L("mapadmin.places")) {
                NavigationLink { AMPlaceEditorView() } label: { Label(L("create.place"), systemImage: "plus") }
                ForEach(store.db.places) { place in
                    Label(place.title, systemImage: place.kind.icon)
                }
                .onDelete { store.db.places.remove(atOffsets: $0) }
            }
            Section("Forgotten Ideas") {
                ForEach(store.db.forgottenIdeas) { Text($0.title) }
                    .onDelete { store.db.forgottenIdeas.remove(atOffsets: $0) }
                TextField(L("editor.title"), text: $idea.title)
                TextField(L("mapadmin.year"), text: $idea.year)
                TextField(L("mapadmin.author"), text: $idea.author)
                TextField(L("place.summary"), text: $idea.summary, axis: .vertical)
                TextField(L("forgotten.why"), text: $idea.whyNotRealized, axis: .vertical)
                TextField(L("tarih.sources"), text: $idea.source)
                Button(L("common.add")) {
                    store.db.forgottenIdeas.append(idea)
                    idea = AMForgottenIdea(title: "", year: "", author: "", summary: "")
                }
                .disabled(idea.title.isEmpty)
            }
            Section(L("kids.themes")) {
                ForEach(store.db.kidsThemes) { Text($0.title) }
                    .onDelete { store.db.kidsThemes.remove(atOffsets: $0) }
                TextField(L("editor.title"), text: $theme.title)
                TextField(L("mapadmin.prompt"), text: $theme.prompt, axis: .vertical)
                Button(L("common.add")) {
                    store.db.kidsThemes.append(theme)
                    theme = AMKidsTheme(title: "", prompt: "")
                }
                .disabled(theme.title.isEmpty)
            }
        }
        .navigationTitle(L("admin.map"))
    }
}
