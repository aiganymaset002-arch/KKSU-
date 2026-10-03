//
//  AMTarih.swift
//  ATA MURA
//
//  TARIH / ТАРИХ: публикации об истории Казахстана, категории достоверности,
//  источники, «Связать с историей», Easy Language, комментарии и жалобы.
//

import SwiftUI

struct AMTarihView: View {
    @EnvironmentObject private var store: AMStore
    @State private var type: AMPostType?
    @State private var region: AMRegion?
    @State private var showEditor = false

    private var posts: [AMPost] {
        store.visiblePosts.filter { post in
            (type == nil || post.type == type) && (region == nil || post.region == region)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterChip(L("common.all"), selected: type == nil) { type = nil }
                        ForEach(AMPostType.allCases) { option in
                            filterChip(option.title, icon: option.icon, selected: type == option) { type = option }
                        }
                    }
                }
                Picker(L("common.region"), selection: $region) {
                    Text(L("common.allRegions")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
                .pickerStyle(.menu)
                AMSectionHeader(title: L("tarih.topics"), icon: "books.vertical.fill")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.db.topics) { topic in
                            NavigationLink { AMTopicView(topic: topic) } label: {
                                AMTag(text: topic.title, icon: "link")
                            }
                        }
                    }
                }
                if posts.isEmpty { AMEmptyState(icon: "book.closed", text: L("tarih.empty")) }
                ForEach(posts) { post in
                    NavigationLink { AMPostDetailView(postId: post.id) } label: { AMPostRow(post: post) }
                        .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("TARIH")
        .toolbar {
            Button { showEditor = true } label: { Image(systemName: "square.and.pencil") }
                .accessibilityLabel(L("create.history"))
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { AMPostEditorView(type: type ?? .history) }
        }
    }

    private func filterChip(_ title: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AMTag(text: title, icon: icon, color: selected ? .white : AMTheme.skyDeep)
                .background(selected ? AMTheme.skyDeep : .clear, in: Capsule())
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct AMPostRow: View {
    @EnvironmentObject private var store: AMStore
    let post: AMPost

    var body: some View {
        AMCard {
            HStack {
                AMTag(text: post.type.title, icon: post.type.icon)
                AMTag(text: post.evidence.title, color: .secondary)
                Spacer()
                AMStatusBadge(status: post.status)
            }
            if let first = post.images.first { AMImageView(data: first, height: 150) }
            Text(post.title).font(.headline).multilineTextAlignment(.leading)
            Text(post.body).font(.callout).foregroundStyle(.secondary).lineLimit(3).multilineTextAlignment(.leading)
            HStack(spacing: 12) {
                Text(post.authorName).font(.caption)
                if let region = post.region { Label(region.title, systemImage: "mappin").font(.caption) }
                Spacer()
                Label("\(store.likes(post.id))", systemImage: "heart").font(.caption)
                Label("\(store.comments(post.id).count)", systemImage: "bubble.left").font(.caption)
            }
            .foregroundStyle(.secondary)
            AMVerificationBadge(verification: post.verification)
        }
    }
}

// MARK: - Публикация

struct AMPostDetailView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.amMode) private var mode
    @Environment(\.dismiss) private var dismiss
    let postId: UUID
    @State private var simplified: String?
    @State private var simplifying = false
    @State private var comment = ""
    @State private var showReport = false
    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var transcriptOpen = false

    private var post: AMPost? { store.db.posts.first { $0.id == postId } }

    var body: some View {
        if let post {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    AMFlowLayout {
                        AMTag(text: post.type.title, icon: post.type.icon)
                        AMTag(text: post.evidence.title, color: .secondary)
                        if let region = post.region { AMTag(text: region.title, icon: "mappin", color: .green) }
                        AMStatusBadge(status: post.status)
                        AMVerificationBadge(verification: post.verification)
                    }
                    Text(post.title).font(.title.bold())
                    if !post.heroName.isEmpty {
                        Label("\(post.heroName) \(post.heroYears)", systemImage: "person.fill").font(.headline)
                    }
                    NavigationLink { AMProfileView(userId: post.authorId) } label: {
                        HStack {
                            AMAvatar(user: store.user(post.authorId), size: 32)
                            Text(post.authorName).font(.subheadline)
                            Text("· \(post.createdAt.amDate)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    if !post.moderatorNote.isEmpty && (post.authorId == store.currentUser?.id || store.isStaff) {
                        AMCard {
                            Label(L("moderation.note"), systemImage: "exclamationmark.bubble").font(.headline)
                            Text(post.moderatorNote)
                        }
                    }
                    AMImageStrip(images: post.images)
                    HStack {
                        AMSpeakButton(text: post.title + ". " + post.body, id: post.id)
                        Button {
                            Task {
                                simplifying = true
                                simplified = await AMAI.shared.explainSimply(post.body)
                                simplifying = false
                            }
                        } label: {
                            if simplifying { ProgressView() } else { Label(L("tarih.explain"), systemImage: "text.bubble") }
                        }
                        .buttonStyle(mode == .easyLanguage ? AnyPrimitiveButtonStyle(.borderedProminent) : AnyPrimitiveButtonStyle(.bordered))
                    }
                    if let simplified {
                        AMCard {
                            Label(L("tarih.simple"), systemImage: "face.smiling").font(.headline)
                            AMBodyText(text: simplified)
                        }
                    }
                    AMBodyText(text: post.body)
                    if !post.videoURL.isEmpty {
                        AMLinkButton(title: L("common.watchVideo"), url: post.videoURL, icon: "play.rectangle.fill")
                    }
                    if !post.transcript.isEmpty {
                        DisclosureGroup(isExpanded: $transcriptOpen) {
                            AMBodyText(text: post.transcript)
                        } label: {
                            Label(L("tarih.transcript"), systemImage: "captions.bubble")
                        }
                    }
                    if !post.sources.isEmpty {
                        AMSectionHeader(title: L("tarih.sources"), icon: "books.vertical")
                        ForEach(post.sources) { source in
                            AMSourceRow(source: source)
                        }
                    } else if post.evidence.needsSources {
                        Label(L("tarih.noSources"), systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                    }
                    let topics = store.db.topics.filter { post.topicIds.contains($0.id) }
                    if !topics.isEmpty {
                        AMSectionHeader(title: L("tarih.linked"), icon: "link")
                        AMFlowLayout {
                            ForEach(topics) { topic in
                                NavigationLink { AMTopicView(topic: topic) } label: { AMTag(text: topic.title, icon: "books.vertical") }
                            }
                        }
                    }
                    actions(post)
                    AMCommentsSection(targetId: post.id)
                }
                .padding()
            }
            .navigationTitle(post.type.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { transcriptOpen = mode == .hearing }
            .toolbar { menu(post) }
            .sheet(isPresented: $showReport) {
                AMReportSheet(targetId: post.id, title: post.title, authorId: post.authorId)
            }
            .sheet(isPresented: $showEdit) {
                NavigationStack { AMPostEditorView(type: post.type, existing: post) }
            }
            .confirmationDialog(L("common.deleteConfirm"), isPresented: $confirmDelete) {
                Button(L("common.delete"), role: .destructive) {
                    store.deletePost(post.id)
                    dismiss()
                }
            }
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }

    private func actions(_ post: AMPost) -> some View {
        HStack {
            Button {
                store.toggleLike(post.id)
            } label: {
                Label("\(store.likes(post.id))", systemImage: store.isLiked(post.id) ? "heart.fill" : "heart")
            }
            .buttonStyle(.bordered)
            .tint(.pink)
            ShareLink(item: "\(post.title)\n\n\(post.body)\n\n— ATA MURA") {
                Label(L("common.share"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    @ToolbarContentBuilder
    private func menu(_ post: AMPost) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if post.authorId == store.currentUser?.id || store.isStaff {
                    Button { showEdit = true } label: { Label(L("common.edit"), systemImage: "pencil") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label(L("common.delete"), systemImage: "trash") }
                }
                if post.authorId != store.currentUser?.id {
                    Button { showReport = true } label: { Label(L("report.title"), systemImage: "flag") }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

/// Обёртка, чтобы выбирать стиль кнопки условием.
struct AnyPrimitiveButtonStyle: PrimitiveButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: PrimitiveButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

struct AMSourceRow: View {
    let source: AMSource

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: source.kind.icon).foregroundStyle(AMTheme.skyDeep).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title).font(.callout.weight(.semibold))
                if !source.detail.isEmpty {
                    if let url = URL(string: source.detail), url.scheme?.hasPrefix("http") == true {
                        Link(source.detail, destination: url).font(.caption)
                    } else {
                        Text(source.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(source.kind.title).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            if let data = source.attachment, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Комментарии и жалобы

struct AMCommentsSection: View {
    @EnvironmentObject private var store: AMStore
    let targetId: UUID
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AMSectionHeader(title: L("comments.title"), icon: "bubble.left.and.bubble.right")
            ForEach(store.comments(targetId)) { comment in
                HStack(alignment: .top) {
                    AMAvatar(user: store.user(comment.authorId), size: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.authorName).font(.caption.bold())
                        Text(comment.text).font(.callout)
                        Text(comment.date.amRelative).font(.caption2).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    if comment.authorId == store.currentUser?.id || store.isStaff {
                        Button {
                            store.db.comments.removeAll { $0.id == comment.id }
                        } label: {
                            Image(systemName: "trash").font(.caption)
                        }
                        .accessibilityLabel(L("common.delete"))
                    }
                }
            }
            HStack {
                TextField(L("comments.placeholder"), text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    store.addComment(text, to: targetId)
                    text = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(L("common.send"))
            }
        }
    }
}

struct AMReportSheet: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    let targetId: UUID
    let title: String
    let authorId: UUID
    @State private var reason = ""
    @State private var blockAuthor = false

    private let reasons = ["report.reason.false", "report.reason.offensive", "report.reason.spam", "report.reason.copyright"]

    var body: some View {
        NavigationStack {
            Form {
                Section(L("report.reason")) {
                    ForEach(reasons, id: \.self) { key in
                        Button {
                            reason = L(key)
                        } label: {
                            HStack {
                                Text(L(key)).foregroundStyle(.primary)
                                Spacer()
                                if reason == L(key) { Image(systemName: "checkmark") }
                            }
                        }
                    }
                    TextField(L("report.other"), text: $reason)
                }
                Section {
                    Toggle(L("report.block"), isOn: $blockAuthor)
                }
                Section {
                    Button(L("report.send")) {
                        store.report(targetId, title: title, reason: reason)
                        if blockAuthor { store.block(authorId) }
                        dismiss()
                    }
                    .disabled(reason.isEmpty)
                }
            }
            .navigationTitle(L("report.title"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } } }
        }
    }
}

// MARK: - Редактор публикации

struct AMPostEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var post: AMPost
    @State private var newSource = AMSource()
    @State private var published = false
    private let isNew: Bool

    init(type: AMPostType, evidence: AMEvidence = .fact, existing: AMPost? = nil) {
        isNew = existing == nil
        _post = State(initialValue: existing ?? AMPost(authorId: UUID(), authorName: "", type: type,
                                                        evidence: type == .familyStory ? .oralHistory : evidence,
                                                        title: "", body: ""))
    }

    private var suggested: [AMTopic] { store.suggestedTopics(for: post.title + " " + post.body) }
    private var canPublish: Bool {
        !post.title.trimmingCharacters(in: .whitespaces).isEmpty && post.body.count >= 20
            && (!post.evidence.needsSources || !post.sources.isEmpty || post.evidence == .oralHistory)
    }

    var body: some View {
        Form {
            Section(L("editor.type")) {
                Picker(L("editor.type"), selection: $post.type) {
                    ForEach(AMPostType.allCases.filter { $0 != .news || store.isStaff }) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                Picker(L("editor.evidence"), selection: $post.evidence) {
                    ForEach(AMEvidence.allCases) { Text($0.title).tag($0) }
                }
                Picker(L("common.region"), selection: $post.region) {
                    Text(L("common.notSelected")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
            }
            if post.type == .familyStory || post.type == .person {
                Section(L("editor.hero")) {
                    TextField(L("editor.heroName"), text: $post.heroName)
                    TextField(L("editor.heroYears"), text: $post.heroYears)
                }
            }
            Section(L("editor.content")) {
                TextField(L("editor.title"), text: $post.title, axis: .vertical)
                AMTextArea(title: L("editor.body"), text: $post.body, minHeight: 200)
                AMPhotoPicker(images: $post.images)
                TextField(L("editor.video"), text: $post.videoURL).keyboardType(.URL).textInputAutocapitalization(.never)
                AMTextArea(title: L("editor.transcript"), text: $post.transcript, minHeight: 60)
            }
            Section {
                ForEach(post.sources) { source in AMSourceRow(source: source) }
                    .onDelete { post.sources.remove(atOffsets: $0) }
                Picker(L("source.kind"), selection: $newSource.kind) {
                    ForEach(AMSourceKind.allCases, id: \.self) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                TextField(L("source.titleField"), text: $newSource.title)
                TextField(L("source.detail"), text: $newSource.detail)
                AMSinglePhotoPicker(title: L("source.attach"), image: $newSource.attachment)
                Button {
                    post.sources.append(newSource)
                    newSource = AMSource()
                } label: {
                    Label(L("source.add"), systemImage: "plus")
                }
                .disabled(newSource.title.isEmpty)
            } header: {
                Text(L("source.question"))
            } footer: {
                Text(post.evidence.needsSources ? L("source.required") : L("source.optional"))
            }
            if !suggested.isEmpty {
                Section {
                    ForEach(suggested) { topic in
                        Label(topic.title, systemImage: "link")
                    }
                } header: {
                    Text(L("editor.linkHistory"))
                } footer: {
                    Text(L("editor.linkHistory.hint"))
                }
            }
            Section {
                Button {
                    guard let user = store.currentUser else { return }
                    if isNew {
                        post.authorId = user.id
                        post.authorName = user.fullName
                    }
                    store.publish(post)
                    published = true
                } label: {
                    Label(isNew ? L("editor.publish") : L("common.save"), systemImage: "paperplane.fill").bold()
                }
                .disabled(!canPublish)
            } footer: {
                Text(store.isStaff ? L("editor.staffNote") : L("editor.moderationNote"))
            }
        }
        .navigationTitle(isNew ? L("editor.new") : L("common.edit"))
        .alert(store.isStaff ? L("editor.published") : L("editor.sent"), isPresented: $published) {
            Button("OK") { dismiss() }
        }
    }
}

// MARK: - Тема энциклопедии

struct AMTopicView: View {
    @EnvironmentObject private var store: AMStore
    let topic: AMTopic

    var body: some View {
        let content = store.topicContent(topic)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let region = topic.region { AMTag(text: region.title, icon: "mappin", color: .green) }
                    if !topic.period.isEmpty { AMTag(text: topic.period, icon: "clock") }
                }
                AMBodyText(text: topic.summary)
                AMSpeakButton(text: topic.title + ". " + topic.summary, id: topic.id)
                if !content.places.isEmpty {
                    AMSectionHeader(title: L("search.places"), icon: "mappin.and.ellipse")
                    ForEach(content.places) { place in
                        NavigationLink { AMPlaceDetailView(place: place) } label: {
                            AMCard { Label(place.title, systemImage: place.kind.icon).font(.headline) }
                        }
                        .buttonStyle(.plain)
                    }
                }
                AMSectionHeader(title: L("topic.posts"), icon: "text.book.closed")
                if content.posts.isEmpty { AMEmptyState(icon: "square.and.pencil", text: L("topic.empty")) }
                ForEach(content.posts) { post in
                    NavigationLink { AMPostDetailView(postId: post.id) } label: { AMPostRow(post: post) }
                        .buttonStyle(.plain)
                }
                if !content.museum.isEmpty {
                    AMSectionHeader(title: "Digital Museum", icon: "building.columns")
                    ForEach(content.museum) { item in
                        NavigationLink { AMMuseumDetailView(itemId: item.id) } label: {
                            AMCard { Label(item.title, systemImage: "building.columns").font(.headline) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(topic.title)
    }
}

// MARK: - Inclusive Engineering

struct AMInclusiveHubView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            Section {
                AMInclusiveModePicker(mode: $store.inclusiveMode)
            } header: {
                Text(L("inclusive.title"))
            } footer: {
                Text(L("inclusive.footer"))
            }
            Section("Inclusive Engineering") {
                let projects = store.visibleProjects.filter { $0.direction == .inclusiveEngineering }
                if projects.isEmpty { Text(L("inventors.empty")).foregroundStyle(.secondary) }
                ForEach(projects) { project in
                    NavigationLink { AMProjectDetailView(projectId: project.id) } label: {
                        Label(project.title, systemImage: "figure.roll")
                    }
                }
            }
            Section("Inclusive Kazakhstan") {
                let posts = store.approvedPosts.filter { $0.type == .inclusive }
                if posts.isEmpty { Text(L("tarih.empty")).foregroundStyle(.secondary) }
                ForEach(posts) { post in
                    NavigationLink { AMPostDetailView(postId: post.id) } label: { Text(post.title) }
                }
                NavigationLink { AMPostEditorView(type: .inclusive) } label: {
                    Label(L("create.post"), systemImage: "plus")
                }
            }
        }
        .navigationTitle("INCLUSIVE")
    }
}
