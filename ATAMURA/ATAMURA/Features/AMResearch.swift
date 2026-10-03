//
//  AMResearch.swift
//  ATA MURA
//
//  ATA MURA RESEARCH: статьи школьников, студентов и учёных. Автор, ORCID, источники,
//  DOI, рецензирование, версии статьи и «Найти научного руководителя».
//

import SwiftUI
import UniformTypeIdentifiers

struct AMResearchListView: View {
    @EnvironmentObject private var store: AMStore
    @State private var showEditor = false

    var body: some View {
        List {
            Section {
                Text(L("research.about")).font(.callout).foregroundStyle(.secondary)
                Button { showEditor = true } label: { Label(L("create.article"), systemImage: "doc.badge.plus") }
            }
            let mine = store.visibleResearch.filter { $0.ownerId == store.currentUser?.id && $0.reviewStatus != .published }
            if !mine.isEmpty {
                Section(L("research.mine")) {
                    ForEach(mine) { article in
                        NavigationLink { AMResearchDetailView(articleId: article.id) } label: { row(article) }
                    }
                }
            }
            Section(L("research.published")) {
                let published = store.visibleResearch.filter { $0.reviewStatus == .published }
                if published.isEmpty { Text(L("research.empty")).foregroundStyle(.secondary) }
                ForEach(published) { article in
                    NavigationLink { AMResearchDetailView(articleId: article.id) } label: { row(article) }
                }
            }
        }
        .navigationTitle("ATA MURA Research")
        .sheet(isPresented: $showEditor) { NavigationStack { AMResearchEditorView() } }
    }

    private func row(_ article: AMResearchArticle) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title).font(.headline)
            Text(article.authors).font(.caption)
            HStack {
                AMTag(text: article.reviewStatus.title, icon: "checkmark.seal")
                if !article.field.isEmpty { AMTag(text: article.field, color: .indigo) }
                if article.needsSupervisor { AMTag(text: L("research.needsSupervisor"), icon: "person.fill.questionmark", color: .orange) }
            }
        }
    }
}

struct AMResearchDetailView: View {
    @EnvironmentObject private var store: AMStore
    let articleId: UUID
    @State private var showEdit = false
    @State private var showMentors = false
    @State private var reviewText = ""
    @State private var verdict = "minor"
    @State private var showPDF = false

    var body: some View {
        if let article = store.db.research.first(where: { $0.id == articleId }) {
            let isOwner = article.ownerId == store.currentUser?.id
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AMFlowLayout {
                        AMTag(text: article.reviewStatus.title, icon: "checkmark.seal")
                        if !article.field.isEmpty { AMTag(text: article.field, color: .indigo) }
                        if let region = article.region { AMTag(text: region.title, icon: "mappin", color: .green) }
                        AMTag(text: "v\(article.versions.last?.number ?? 1)", icon: "clock.arrow.circlepath", color: .secondary)
                    }
                    Text(article.title).font(.title2.bold())
                    Text(article.authors).font(.subheadline)
                    if !article.orcid.isEmpty {
                        AMLinkButton(title: "ORCID \(article.orcid)", url: "https://orcid.org/\(article.orcid)", icon: "person.text.rectangle")
                    }
                    if !article.doi.isEmpty {
                        AMLinkButton(title: "DOI \(article.doi)", url: "https://doi.org/\(article.doi)", icon: "link")
                    }
                    if !article.keywords.isEmpty {
                        Text(article.keywords.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("research.abstract")).font(.headline)
                        AMBodyText(text: article.abstract)
                    }
                    AMSpeakButton(text: article.title + ". " + article.abstract, id: article.id)
                    if !article.body.isEmpty { AMBodyText(text: article.body) }
                    if article.pdf != nil {
                        Button { showPDF = true } label: { Label(L("research.openPDF"), systemImage: "doc.richtext") }
                            .buttonStyle(.bordered)
                    }
                    if !article.sources.isEmpty {
                        AMSectionHeader(title: L("tarih.sources"), icon: "books.vertical")
                        ForEach(article.sources) { AMSourceRow(source: $0) }
                    }
                    AMSectionHeader(title: L("research.versions"), icon: "clock.arrow.circlepath")
                    ForEach(article.versions) { version in
                        Text("v\(version.number) · \(version.date.amDate) — \(version.note)").font(.caption)
                    }
                    if article.needsSupervisor {
                        AMCard {
                            Label(L("research.supervisorNeeded", article.supervisorExpertise), systemImage: "person.fill.questionmark")
                            if let id = article.supervisorId, let mentor = store.user(id) {
                                Text(L("research.supervisor", mentor.fullName)).bold()
                            }
                            Button { showMentors = true } label: { Label(L("research.findSupervisor"), systemImage: "magnifyingglass") }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    if !article.reviews.isEmpty || store.isStaff || store.currentUser?.isMentor == true {
                        AMSectionHeader(title: L("research.reviews"), icon: "text.badge.checkmark")
                        ForEach(article.reviews) { review in
                            AMCard {
                                Text("\(review.reviewerName) · \(L("verdict.\(review.verdict)"))").font(.caption.bold())
                                Text(review.text).font(.callout)
                            }
                        }
                    }
                    if (store.isStaff || store.currentUser?.isMentor == true) && !isOwner {
                        reviewForm(article)
                    }
                    if isOwner && (article.reviewStatus == .draft || article.reviewStatus == .reviewed) {
                        Button { store.submitResearch(article.id) } label: { Label(L("research.submit"), systemImage: "paperplane") }
                            .buttonStyle(.borderedProminent)
                    }
                    if store.isStaff {
                        Picker(L("research.status"), selection: Binding(get: { article.reviewStatus },
                                                                        set: { store.setReviewStatus(article.id, $0) })) {
                            ForEach(AMReviewStatus.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
            }
            .navigationTitle("Research")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isOwner || store.isStaff {
                    Button(L("common.edit")) { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) { NavigationStack { AMResearchEditorView(existing: article) } }
            .sheet(isPresented: $showMentors) { NavigationStack { AMMentorPicker(article: article) } }
            .sheet(isPresented: $showPDF) {
                if let pdf = article.pdf { NavigationStack { AMPDFView(data: pdf).navigationTitle(article.title) } }
            }
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }

    private func reviewForm(_ article: AMResearchArticle) -> some View {
        AMCard {
            Text(L("research.writeReview")).font(.headline)
            Picker(L("research.verdict"), selection: $verdict) {
                ForEach(["accept", "minor", "major", "reject"], id: \.self) { Text(L("verdict.\($0)")).tag($0) }
            }
            .pickerStyle(.segmented)
            AMTextArea(title: L("research.reviewText"), text: $reviewText)
            Button(L("common.send")) {
                guard let index = store.db.research.firstIndex(where: { $0.id == article.id }) else { return }
                store.db.research[index].reviews.append(AMPeerReview(reviewerName: store.currentUser?.fullName ?? "", verdict: verdict, text: reviewText))
                if store.db.research[index].reviewStatus == .submitted || store.db.research[index].reviewStatus == .inReview {
                    store.setReviewStatus(article.id, .reviewed)
                }
                reviewText = ""
            }
            .disabled(reviewText.isEmpty)
        }
    }
}

struct AMMentorPicker: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    let article: AMResearchArticle

    var body: some View {
        List {
            Section {
                Text(L("research.mentorHint", article.supervisorExpertise.isEmpty ? article.field : article.supervisorExpertise))
                    .font(.callout).foregroundStyle(.secondary)
            }
            let mentors = store.mentors(for: article)
            if mentors.isEmpty { Text(L("research.noMentors")).foregroundStyle(.secondary) }
            ForEach(mentors) { mentor in
                HStack {
                    AMAvatar(user: mentor, size: 40)
                    VStack(alignment: .leading) {
                        Text(mentor.fullName).font(.headline)
                        Text(mentor.expertise.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(L("research.ask")) {
                        guard let index = store.db.research.firstIndex(where: { $0.id == article.id }) else { return }
                        store.db.research[index].supervisorId = mentor.id
                        store.notify(mentor.id, title: L("notify.supervisor.title"),
                                     body: "\(store.currentUser?.fullName ?? ""): «\(article.title)»")
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(L("research.findSupervisor"))
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("common.close")) { dismiss() } } }
    }
}

struct AMResearchEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var article: AMResearchArticle
    @State private var newSource = AMSource()
    @State private var versionNote = ""
    @State private var importPDF = false
    @State private var saved = false
    private let isNew: Bool

    init(existing: AMResearchArticle? = nil) {
        isNew = existing == nil
        _article = State(initialValue: existing ?? AMResearchArticle(ownerId: UUID(), authors: "", title: "", abstract: ""))
    }

    var body: some View {
        Form {
            Section(L("research.section.main")) {
                TextField(L("editor.title"), text: $article.title, axis: .vertical)
                TextField(L("research.authors"), text: $article.authors)
                TextField("ORCID (0000-0000-0000-0000)", text: $article.orcid).keyboardType(.numbersAndPunctuation)
                TextField(L("research.field"), text: $article.field)
                AMListField(title: L("research.keywords"), items: $article.keywords)
                Picker(L("common.region"), selection: $article.region) {
                    Text(L("common.notSelected")).tag(AMRegion?.none)
                    ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                }
            }
            Section(L("research.abstract")) {
                AMTextArea(title: L("research.abstract"), text: $article.abstract)
                AMTextArea(title: L("research.body"), text: $article.body, minHeight: 200)
                Button { importPDF = true } label: {
                    Label(article.pdf == nil ? L("research.attachPDF") : L("research.replacePDF"), systemImage: "doc.badge.plus")
                }
                TextField(L("research.doi"), text: $article.doi).textInputAutocapitalization(.never)
            }
            Section(L("tarih.sources")) {
                ForEach(article.sources) { AMSourceRow(source: $0) }
                    .onDelete { article.sources.remove(atOffsets: $0) }
                Picker(L("source.kind"), selection: $newSource.kind) {
                    ForEach(AMSourceKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                TextField(L("source.titleField"), text: $newSource.title)
                TextField(L("source.detail"), text: $newSource.detail)
                Button(L("source.add")) {
                    article.sources.append(newSource)
                    newSource = AMSource()
                }
                .disabled(newSource.title.isEmpty)
            }
            Section(L("research.supervisorSection")) {
                Toggle(L("research.needsSupervisor"), isOn: $article.needsSupervisor)
                if article.needsSupervisor {
                    TextField(L("research.expertise"), text: $article.supervisorExpertise)
                }
            }
            if !isNew {
                Section(L("research.newVersion")) {
                    TextField(L("research.versionNote"), text: $versionNote)
                }
            }
            Section {
                Button(isNew ? L("common.save") : L("research.saveVersion")) {
                    guard let user = store.currentUser else { return }
                    if isNew {
                        article.ownerId = user.id
                        if article.authors.isEmpty { article.authors = user.fullName }
                        if article.orcid.isEmpty { article.orcid = user.orcid }
                    } else if !versionNote.isEmpty {
                        article.versions.append(AMArticleVersion(number: (article.versions.last?.number ?? 1) + 1, note: versionNote))
                    }
                    store.saveResearch(article)
                    saved = true
                }
                .disabled(article.title.isEmpty || article.abstract.isEmpty)
            } footer: {
                Text(L("research.draftNote"))
            }
        }
        .navigationTitle(isNew ? L("create.article") : L("common.edit"))
        .fileImporter(isPresented: $importPDF, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), data.count < 15_000_000 { article.pdf = data }
            }
        }
        .alert(L("project.saved"), isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }
}
