//
//  AMInventors.swift
//  ATA MURA
//
//  INVENTORS LAB: «У меня есть идея» → проблема → идея → эскиз → расчёт → прототип →
//  испытание → результат. Карточки проектов, поиск команды, приглашения,
//  Forgotten Ideas of Kazakhstan и «Продолжить эту идею».
//

import SwiftUI

struct AMInventorsLabView: View {
    @EnvironmentObject private var store: AMStore
    @State private var direction: AMDirection?
    @State private var onlyTeam = false
    @State private var showEditor = false

    private var projects: [AMProject] {
        store.visibleProjects.filter { (direction == nil || $0.direction == direction) && (!onlyTeam || $0.lookingForTeam) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    showEditor = true
                } label: {
                    HStack {
                        Image(systemName: "lightbulb.max.fill").font(.title)
                        VStack(alignment: .leading) {
                            Text(L("inventors.haveIdea")).font(.title3.bold())
                            Text(L("inventors.steps")).font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(AMTheme.night)
                    .padding()
                    .background(AMTheme.gold, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                if let week = store.projectOfWeek {
                    NavigationLink { AMProjectDetailView(projectId: week.id) } label: {
                        AMCard {
                            Label("Young Inventor of the Week", systemImage: "star.fill").font(.caption.bold()).foregroundStyle(AMTheme.gold)
                            Text(week.title).font(.headline)
                            Text(week.ownerName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    NavigationLink { AMAssistantScreen() } label: { Label("AI ATA MURA", systemImage: "sparkles") }
                        .buttonStyle(.bordered)
                    NavigationLink { AMForgottenIdeasView() } label: { Label("Forgotten Ideas", systemImage: "arrow.triangle.branch") }
                        .buttonStyle(.bordered)
                }
                Picker(L("project.direction"), selection: $direction) {
                    Text(L("common.all")).tag(AMDirection?.none)
                    ForEach(AMDirection.allCases) { Text($0.title).tag(AMDirection?.some($0)) }
                }
                .pickerStyle(.menu)
                Toggle(L("inventors.lookingTeam"), isOn: $onlyTeam)
                if projects.isEmpty { AMEmptyState(icon: "lightbulb", text: L("inventors.empty")) }
                ForEach(projects) { project in
                    NavigationLink { AMProjectDetailView(projectId: project.id) } label: { AMProjectCard(project: project) }
                        .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inventors Lab")
        .sheet(isPresented: $showEditor) {
            NavigationStack { AMProjectEditorView() }
        }
    }
}

/// Карточка проекта: название, автор, город, направление, стадия, нужна помощь, команда.
struct AMProjectCard: View {
    let project: AMProject

    var body: some View {
        AMCard {
            HStack {
                Text(project.title).font(.headline)
                Spacer()
                AMStatusBadge(status: project.status)
            }
            if let image = project.images.first { AMImageView(data: image, height: 130) }
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                row(L("project.author"), project.ownerName + (project.authorAge.map { ", \(L("project.age", $0))" } ?? ""))
                if !project.city.isEmpty || project.region != nil {
                    row(L("profile.city"), project.city.isEmpty ? (project.region?.title ?? "") : project.city)
                }
                row(L("project.direction"), project.direction.title)
                row(L("project.stage"), project.stage.title)
                if !project.helpNeeded.isEmpty { row(L("project.help"), project.helpNeeded.joined(separator: " / ")) }
                if project.lookingForTeam { row(L("project.team"), project.teamNeeds.isEmpty ? L("project.lookingTeam") : project.teamNeeds) }
            }
            .font(.caption)
            ProgressView(value: project.stage.progress)
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value)
        }
    }
}

struct AMProjectDetailView: View {
    @EnvironmentObject private var store: AMStore
    let projectId: UUID
    @State private var showEdit = false
    @State private var showReport = false

    private var project: AMProject? { store.db.projects.first { $0.id == projectId } }

    var body: some View {
        if let project {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    AMProjectCard(project: project)
                    if let ideaId = project.continuesIdeaId, let idea = store.db.forgottenIdeas.first(where: { $0.id == ideaId }) {
                        AMCard {
                            Label(L("forgotten.continues"), systemImage: "arrow.triangle.branch").font(.caption.bold())
                            Text("\(idea.title) (\(idea.year))").font(.callout)
                        }
                    }
                    AMImageStrip(images: Array(project.images.dropFirst()))
                    ForEach(AMStage.allCases) { stage in
                        let text = project.text(for: stage)
                        if !text.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(stage.title, systemImage: stage.icon).font(.headline)
                                AMBodyText(text: text)
                            }
                        }
                    }
                    if !project.whatToLearn.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(L("ai.field.learn"), systemImage: "book").font(.headline)
                            AMBodyText(text: project.whatToLearn)
                        }
                    }
                    let team = store.team(of: project)
                    if !team.isEmpty {
                        AMSectionHeader(title: L("project.team"), icon: "person.3")
                        ForEach(team) { member in
                            NavigationLink { AMProfileView(userId: member.id) } label: {
                                HStack { AMAvatar(user: member, size: 30); Text(member.fullName) }
                            }
                        }
                    }
                    HStack {
                        Button {
                            store.toggleLike(project.id)
                        } label: {
                            Label("\(store.likes(project.id))", systemImage: store.isLiked(project.id) ? "heart.fill" : "heart")
                        }
                        .buttonStyle(.bordered).tint(.pink)
                        if project.ownerId != store.currentUser?.id {
                            NavigationLink { AMProfileView(userId: project.ownerId) } label: {
                                Label(L("project.join"), systemImage: "hand.raised")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    AMCommentsSection(targetId: project.id)
                }
                .padding()
            }
            .navigationTitle(project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Menu {
                    if project.ownerId == store.currentUser?.id || store.isStaff {
                        Button { showEdit = true } label: { Label(L("common.edit"), systemImage: "pencil") }
                    }
                    if store.isStaff {
                        Button { store.setProjectOfWeek(project.id) } label: { Label(L("project.makeWeek"), systemImage: "star") }
                    }
                    if project.ownerId != store.currentUser?.id {
                        Button { showReport = true } label: { Label(L("report.title"), systemImage: "flag") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .sheet(isPresented: $showEdit) { NavigationStack { AMProjectEditorView(existing: project) } }
            .sheet(isPresented: $showReport) { AMReportSheet(targetId: project.id, title: project.title, authorId: project.ownerId) }
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }
}

// MARK: - Мастер проекта

struct AMProjectEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var project: AMProject
    @State private var step: AMStage = .problem
    @State private var saved = false
    private let isNew: Bool

    init(existing: AMProject? = nil, draft: AMProjectDraft? = nil, continuing idea: AMForgottenIdea? = nil) {
        isNew = existing == nil
        var project = existing ?? AMProject(ownerId: UUID(), ownerName: "", title: "")
        if let draft {
            project.title = draft.title
            project.problem = draft.problem
            project.idea = draft.solution
            project.prototype = draft.firstPrototype
            project.whatToLearn = draft.whatToLearn
            project.direction = draft.direction
            project.helpNeeded = draft.helpNeeded
            project.stage = .idea
        }
        if let idea {
            project.continuesIdeaId = idea.id
            project.title = L("forgotten.modernTitle", idea.title)
            project.problem = idea.summary
            project.region = idea.region
        }
        _project = State(initialValue: project)
    }

    var body: some View {
        Form {
            Section {
                TextField(L("project.title"), text: $project.title)
                Picker(L("project.direction"), selection: $project.direction) {
                    ForEach(AMDirection.allCases) { Text($0.title).tag($0) }
                }
                Picker(L("common.region"), selection: $project.region) {
                    Text(L("common.notSelected")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
                TextField(L("profile.city"), text: $project.city)
            }
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(AMStage.allCases) { stage in
                            Button {
                                step = stage
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: stage.icon)
                                    Text(stage.title).font(.caption2)
                                }
                                .padding(8)
                                .foregroundStyle(step == stage ? .white : (project.text(for: stage).isEmpty ? .secondary : AMTheme.skyDeep))
                                .background(step == stage ? AMTheme.skyDeep : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(step == stage ? .isSelected : [])
                        }
                    }
                }
                Text(L("stage.\(step.rawValue).question")).font(.callout).foregroundStyle(.secondary)
                AMTextArea(title: step.title, text: Binding(get: { project.text(for: step) },
                                                            set: { project.setText($0, for: step) }), minHeight: 140)
                HStack {
                    if let previous = AMStage.allCases.firstIndex(of: step).flatMap({ $0 > 0 ? AMStage.allCases[$0 - 1] : nil }) {
                        Button(L("common.back")) { step = previous }
                    }
                    Spacer()
                    if let next = AMStage.allCases.firstIndex(of: step).flatMap({ $0 + 1 < AMStage.allCases.count ? AMStage.allCases[$0 + 1] : nil }) {
                        Button(L("common.next")) { step = next }.bold()
                    }
                }
                .buttonStyle(.borderless)
            } header: {
                Text(L("inventors.steps"))
            }
            Section(L("project.stage")) {
                Picker(L("project.stage"), selection: $project.stage) {
                    ForEach(AMStage.allCases) { Text($0.title).tag($0) }
                }
                AMTextArea(title: L("ai.field.learn"), text: $project.whatToLearn, minHeight: 60)
                AMPhotoPicker(images: $project.images)
            }
            Section(L("project.team")) {
                AMListField(title: L("project.helpHint"), items: $project.helpNeeded)
                Toggle(L("project.lookingTeam"), isOn: $project.lookingForTeam)
                if project.lookingForTeam {
                    TextField(L("project.teamNeeds"), text: $project.teamNeeds)
                }
            }
            Section {
                Button {
                    guard let user = store.currentUser else { return }
                    if isNew {
                        project.ownerId = user.id
                        project.ownerName = user.fullName
                        project.authorAge = user.age
                        if project.region == nil { project.region = user.region }
                        if project.city.isEmpty { project.city = user.city }
                    }
                    store.saveProject(project)
                    saved = true
                } label: {
                    Label(isNew ? L("project.create") : L("common.save"), systemImage: "checkmark.circle.fill").bold()
                }
                .disabled(project.title.isEmpty || project.problem.isEmpty)
            } footer: {
                Text(store.isStaff ? L("editor.staffNote") : L("editor.moderationNote"))
            }
        }
        .navigationTitle(isNew ? "Inventors Lab" : L("common.edit"))
        .alert(L("project.saved"), isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }
}

// MARK: - Forgotten Ideas of Kazakhstan

struct AMForgottenIdeasView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                AMCard {
                    Text("Forgotten Ideas of Kazakhstan").font(.headline)
                    Text(L("forgotten.about")).font(.callout).foregroundStyle(.secondary)
                }
                ForEach(store.db.forgottenIdeas) { idea in
                    AMCard {
                        HStack {
                            AMTag(text: idea.year, icon: "clock")
                            if let region = idea.region { AMTag(text: region.title, icon: "mappin", color: .green) }
                        }
                        Text(idea.title).font(.headline)
                        Text(idea.author).font(.caption).foregroundStyle(.secondary)
                        AMBodyText(text: idea.summary)
                        if !idea.whyNotRealized.isEmpty {
                            Text(L("forgotten.why") + ": " + idea.whyNotRealized).font(.callout).foregroundStyle(.secondary)
                        }
                        if !idea.source.isEmpty {
                            Label(idea.source, systemImage: "books.vertical").font(.caption)
                        }
                        let continuations = store.continuations(of: idea)
                        if !continuations.isEmpty {
                            Text(L("forgotten.continued", continuations.count)).font(.caption.bold())
                            ForEach(continuations) { project in
                                NavigationLink { AMProjectDetailView(projectId: project.id) } label: {
                                    Label(project.title, systemImage: "arrow.turn.down.right").font(.callout)
                                }
                            }
                        }
                        NavigationLink { AMProjectEditorView(continuing: idea) } label: {
                            Label(L("forgotten.continue"), systemImage: "arrow.triangle.branch")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Forgotten Ideas")
    }
}
