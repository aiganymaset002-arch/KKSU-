//
//  AMMuseumKids.swift
//  ATA MURA
//
//  DIGITAL MUSEUM («Музей вещей моей семьи»), «История глазами ребёнка» (KIDS LAB)
//  и ATA MURA QUEST (баллы и уровни).
//

import SwiftUI

// MARK: - Digital Museum

struct AMMuseumView: View {
    @EnvironmentObject private var store: AMStore
    @State private var onlyFamily = false
    @State private var showEditor = false

    private var items: [AMMuseumItem] { store.visibleMuseum.filter { !onlyFamily || $0.isFamily } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                AMCard {
                    Text(L("museum.about")).font(.callout)
                    Button { showEditor = true } label: { Label(L("create.museum"), systemImage: "camera.fill") }
                        .buttonStyle(.borderedProminent)
                }
                Toggle(L("museum.onlyFamily"), isOn: $onlyFamily)
                if items.isEmpty { AMEmptyState(icon: "building.columns", text: L("museum.empty")) }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                    ForEach(items) { item in
                        NavigationLink { AMMuseumDetailView(itemId: item.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let photo = item.photos.first {
                                    AMImageView(data: photo, height: 140)
                                } else {
                                    RoundedRectangle(cornerRadius: 14).fill(Color.brown.opacity(0.15)).frame(height: 140)
                                        .overlay(Image(systemName: "building.columns").font(.largeTitle).foregroundStyle(.brown))
                                }
                                Text(item.title).font(.headline).lineLimit(2)
                                Text(item.period).font(.caption).foregroundStyle(.secondary)
                                AMStatusBadge(status: item.status)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Digital Museum")
        .sheet(isPresented: $showEditor) { NavigationStack { AMMuseumEditorView() } }
    }
}

struct AMMuseumDetailView: View {
    @EnvironmentObject private var store: AMStore
    let itemId: UUID

    var body: some View {
        if let item = store.db.museum.first(where: { $0.id == itemId }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AMImageStrip(images: item.photos, height: 260)
                    Text(item.title).font(.title.bold())
                    AMFlowLayout {
                        if item.isFamily { AMTag(text: L("museum.family"), icon: "house.fill", color: .brown) }
                        if !item.period.isEmpty { AMTag(text: item.period, icon: "clock") }
                        if let region = item.region { AMTag(text: region.title, icon: "mappin", color: .green) }
                        AMStatusBadge(status: item.status)
                    }
                    // История → автор → место → период → фото → 3D → видео → связанные статьи.
                    field(L("museum.what"), item.whatIsIt)
                    field(L("museum.owner"), item.belongedTo)
                    field(L("museum.place"), item.place)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("museum.story")).font(.headline)
                        AMBodyText(text: item.story)
                    }
                    AMSpeakButton(text: item.title + ". " + item.story, id: item.id)
                    HStack {
                        AMLinkButton(title: "3D", url: item.model3DURL, icon: "rotate.3d")
                        AMLinkButton(title: L("common.watchVideo"), url: item.videoURL, icon: "play.rectangle")
                    }
                    Text(L("museum.addedBy", item.ownerName)).font(.caption).foregroundStyle(.secondary)
                    let topics = store.db.topics.filter { item.topicIds.contains($0.id) }
                    if !topics.isEmpty {
                        AMSectionHeader(title: L("tarih.linked"), icon: "link")
                        ForEach(topics) { topic in
                            NavigationLink { AMTopicView(topic: topic) } label: { AMTag(text: topic.title, icon: "books.vertical") }
                        }
                    }
                    AMCommentsSection(targetId: item.id)
                }
                .padding()
            }
            .navigationTitle("Digital Museum")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }

    @ViewBuilder
    private func field(_ title: String, _ value: String) -> some View {
        if !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value)
            }
        }
    }
}

/// Добавление экспоната: человек фотографирует предмет, приложение задаёт вопросы.
struct AMMuseumEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var item = AMMuseumItem(ownerId: UUID(), ownerName: "", title: "")
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                AMPhotoPicker(images: $item.photos)
            } header: {
                Text(L("museum.step.photo"))
            }
            Section(L("museum.step.questions")) {
                TextField(L("museum.q.title"), text: $item.title)
                TextField(L("museum.q.what"), text: $item.whatIsIt, axis: .vertical)
                TextField(L("museum.q.owner"), text: $item.belongedTo, axis: .vertical)
                TextField(L("museum.q.period"), text: $item.period)
                TextField(L("museum.q.place"), text: $item.place)
                Picker(L("common.region"), selection: $item.region) {
                    Text(L("common.notSelected")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
                AMTextArea(title: L("museum.q.story"), text: $item.story)
            }
            Section {
                Toggle(L("museum.family"), isOn: $item.isFamily)
                TextField(L("museum.video"), text: $item.videoURL).keyboardType(.URL).textInputAutocapitalization(.never)
                TextField(L("museum.model3d"), text: $item.model3DURL).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section {
                Button(L("editor.publish")) {
                    guard let user = store.currentUser else { return }
                    item.ownerId = user.id
                    item.ownerName = user.fullName
                    store.saveMuseumItem(item)
                    saved = true
                }
                .disabled(item.title.isEmpty || item.photos.isEmpty)
            } footer: {
                Text(L("museum.needPhoto"))
            }
        }
        .navigationTitle(L("create.museum"))
        .alert(store.isStaff ? L("editor.published") : L("editor.sent"), isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }
}

// MARK: - История глазами ребёнка

struct AMKidsLabView: View {
    @EnvironmentObject private var store: AMStore
    @State private var themeForWork: AMKidsTheme?
    @State private var showFree = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AMCard {
                    Text(L("kids.title")).font(.title3.bold())
                    Text("CULTURE × TECHNOLOGY × YOUNG INVENTORS").font(.caption.bold()).foregroundStyle(AMTheme.skyDeep)
                    Text(L("kids.about")).font(.callout).foregroundStyle(.secondary)
                    AMFlowLayout {
                        ForEach(AMKidsFormat.allCases) { AMTag(text: $0.title, icon: $0.icon, color: .pink) }
                    }
                }
                AMSectionHeader(title: L("kids.themes"), icon: "sparkles")
                ForEach(store.db.kidsThemes) { theme in
                    AMCard {
                        Text(theme.title).font(.headline)
                        Text(theme.prompt).font(.callout).foregroundStyle(.secondary)
                        Button { themeForWork = theme } label: { Label(L("kids.make"), systemImage: "paintbrush.pointed.fill") }
                            .buttonStyle(.borderedProminent).tint(.pink)
                    }
                }
                Button { showFree = true } label: { Label(L("kids.free"), systemImage: "plus") }.buttonStyle(.bordered)
                AMSectionHeader(title: L("kids.gallery"), icon: "photo.on.rectangle")
                if store.visibleKidsWorks.isEmpty { AMEmptyState(icon: "paintpalette", text: L("kids.empty")) }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                    ForEach(store.visibleKidsWorks) { work in
                        VStack(alignment: .leading, spacing: 4) {
                            if let image = work.images.first { AMImageView(data: image, height: 130) }
                            AMTag(text: work.format.title, icon: work.format.icon, color: .pink)
                            Text(work.title).font(.headline).lineLimit(2)
                            Text(work.ownerName + (work.age.map { ", \(L("project.age", $0))" } ?? "")).font(.caption).foregroundStyle(.secondary)
                            if !work.summary.isEmpty { Text(work.summary).font(.caption).lineLimit(3) }
                            AMLinkButton(title: L("common.watchVideo"), url: work.videoURL, icon: "play.rectangle")
                            AMStatusBadge(status: work.status)
                            Button {
                                store.toggleLike(work.id)
                            } label: {
                                Label("\(store.likes(work.id))", systemImage: store.isLiked(work.id) ? "heart.fill" : "heart").font(.caption)
                            }
                            .tint(.pink)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("KIDS LAB")
        .sheet(item: $themeForWork) { theme in NavigationStack { AMKidsWorkEditorView(theme: theme) } }
        .sheet(isPresented: $showFree) { NavigationStack { AMKidsWorkEditorView(theme: nil) } }
    }
}

struct AMKidsWorkEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    let theme: AMKidsTheme?
    @State private var work = AMKidsWork(ownerId: UUID(), ownerName: "", format: .drawing, title: "", summary: "")
    @State private var saved = false

    var body: some View {
        Form {
            if let theme {
                Section(L("kids.theme")) {
                    Text(theme.title).font(.headline)
                    Text(theme.prompt).foregroundStyle(.secondary)
                }
            }
            Section {
                Picker(L("kids.format"), selection: $work.format) {
                    ForEach(AMKidsFormat.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                TextField(L("editor.title"), text: $work.title)
                AMTextArea(title: L("kids.describe"), text: $work.summary)
                AMPhotoPicker(images: $work.images)
                TextField(L("editor.video"), text: $work.videoURL).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section {
                Button(L("editor.publish")) {
                    guard let user = store.currentUser else { return }
                    work.ownerId = user.id
                    work.ownerName = user.fullName
                    work.age = user.age
                    work.themeId = theme?.id
                    store.saveKidsWork(work)
                    saved = true
                }
                .disabled(work.title.isEmpty || (work.images.isEmpty && work.videoURL.isEmpty))
            } footer: {
                Text(L("kids.parentNote"))
            }
        }
        .navigationTitle(L("create.kids"))
        .alert(store.isStaff ? L("editor.published") : L("editor.sent"), isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }
}

// MARK: - ATA MURA QUEST

struct AMQuestView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        let user = store.currentUser
        List {
            if let user {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: user.level.icon).font(.largeTitle).foregroundStyle(AMTheme.gold)
                        VStack(alignment: .leading) {
                            Text(user.level.title).font(.title3.bold())
                            Text("\(user.points) pts").font(.headline).monospacedDigit()
                            if let next = user.level.next {
                                ProgressView(value: Double(user.points - user.level.minPoints),
                                             total: Double(next.minPoints - user.level.minPoints))
                                Text(L("quest.toNext", next.minPoints - user.points, next.title)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section(L("quest.levels")) {
                ForEach(AMLevel.allCases, id: \.self) { level in
                    HStack {
                        Image(systemName: level.icon).frame(width: 26)
                        Text(level.title)
                        Spacer()
                        Text("\(level.minPoints)+").foregroundStyle(.secondary).monospacedDigit()
                        if let user, user.points >= level.minPoints { Image(systemName: "checkmark.circle.fill").foregroundStyle(AMTheme.success) }
                    }
                }
            }
            Section(L("quest.tasks")) {
                ForEach(AMQuest.all) { quest in
                    let done = user?.completedQuests.contains(quest.id) == true
                    HStack(alignment: .top) {
                        Image(systemName: quest.icon).frame(width: 26).foregroundStyle(done ? AMTheme.success : AMTheme.skyDeep)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quest.title).strikethrough(done)
                            Text(quest.hint).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("+\(quest.points)").font(.headline).foregroundStyle(done ? .secondary : AMTheme.gold)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(done ? L("quest.done") : "")
                }
            }
        }
        .navigationTitle("ATA MURA QUEST")
    }
}
