//
//  KKSUInventions.swift
//  KKSU Online
//
//  KKSU Inventions (47), карточка проекта (48), медиа проекта (49),
//  команды (50), наставник (51), стадии Idea → Result (52), журнал экспериментов (53),
//  лабораторная тетрадь (54), каталог прототипов (55), Young Inventors 30 (56–58),
//  виртуальная выставка (59).
//

import SwiftUI

// MARK: - Список проектов (задача 47)

struct InventionsView: View {
    @EnvironmentObject private var store: KKSUStore
    let track: ProjectTrack?
    @State private var stage: ProjectStage?
    @State private var onlyMine = false
    @State private var showEditor = false

    var body: some View {
        let me = store.currentUser?.id
        let projects = store.db.projects.filter { project in
            (track == nil || project.track == track) &&
            (stage == nil || project.stage == stage) &&
            (!onlyMine || me.map { project.authorIDs.contains($0) || project.mentorID == $0 } ?? false)
        }
        .sorted { $0.createdAt > $1.createdAt }
        KPage(track?.title ?? "KKSU Inventions") {
            if track == nil {
                KCard {
                    Label("Изобретения учеников KKSU", systemImage: "lightbulb.max.fill").font(.headline).foregroundStyle(.tint)
                    Text("Каждый проект проходит путь Idea → Research → Prototype → Testing → Result с наставником, журналом экспериментов и лабораторной тетрадью.")
                        .font(.callout)
                }
            }
            StageFunnel(projects: projects)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все стадии", selected: stage == nil) { stage = nil }
                    ForEach(ProjectStage.allCases) { item in
                        FilterChip(title: item.title, selected: stage == item) { stage = item }
                    }
                }
            }
            Toggle("Только мои проекты", isOn: $onlyMine)
            if projects.isEmpty { KEmptyState(text: "Проектов не найдено", icon: "lightbulb") }
            ForEach(projects) { project in
                NavigationLink { ProjectDetailView(projectID: project.id) } label: { ProjectCard(project: project) }
                    .buttonStyle(.plain)
            }
            if store.role == .student || store.role.canTeach || store.role == .mentor {
                PrimaryButton(title: "Новый проект", icon: "plus") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { ProjectEditorView(track: track ?? .inventions) }
        }
    }
}

struct StageFunnel: View {
    let projects: [InventionProject]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProjectStage.allCases) { stage in
                let count = projects.filter { $0.stage == stage }.count
                VStack(spacing: 4) {
                    Image(systemName: stage.icon)
                    Text("\(count)").font(.headline)
                    Text(stage.title).font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(KKSUTheme.primary.opacity(0.08 + 0.12 * Double(stage.index)), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct ProjectCard: View {
    @EnvironmentObject private var store: KKSUStore
    let project: InventionProject

    var body: some View {
        KCard {
            HStack(alignment: .top) {
                Image(systemName: project.track.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(KKSUTheme.softBlue, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title).font(.headline)
                    Text(project.track.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                KBadge(text: project.stage.title, color: project.stage == .result ? KKSUTheme.success : KKSUTheme.primary)
            }
            Text(project.summary).font(.callout).lineLimit(2)
            StageProgress(stage: project.stage)
            HStack(spacing: 12) {
                Label(project.authorIDs.map { store.userName($0).components(separatedBy: " ").first ?? "" }.joined(separator: ", "), systemImage: "person.2")
                if project.mentorID != nil { Label("наставник", systemImage: "figure.2.and.child.holdinghands") }
                if !project.media.isEmpty { Label("\(project.media.count)", systemImage: "paperclip") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

/// Стадии проекта Idea → Research → Prototype → Testing → Result (задача 52).
struct StageProgress: View {
    let stage: ProjectStage

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProjectStage.allCases) { item in
                Capsule()
                    .fill(item.index <= stage.index ? KKSUTheme.primary : Color.gray.opacity(0.2))
                    .frame(height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Стадия проекта: \(stage.title), \(stage.index + 1) из \(ProjectStage.allCases.count)")
    }
}

// MARK: - Карточка проекта (задачи 48–54)

struct ProjectDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let projectID: UUID
    @State private var tab = 0
    @State private var stageNote = ""
    @State private var newMedia: [Attachment] = []

    var body: some View {
        if let index = store.db.projects.firstIndex(where: { $0.id == projectID }) {
            let project = store.db.projects[index]
            let me = store.currentUser?.id
            let canEdit = me.map { project.authorIDs.contains($0) || project.mentorID == $0 } ?? false || store.role.canTeach
            KPage(project.title) {
                KCard {
                    HStack {
                        Label(project.track.title, systemImage: project.track.icon).font(.caption).foregroundStyle(.tint)
                        Spacer()
                        Label("\(project.likes)", systemImage: "heart.fill").font(.caption).foregroundStyle(KKSUTheme.danger)
                    }
                    Text(project.title).font(.title2.bold())
                    Text(project.summary)
                    StageProgress(stage: project.stage)
                    Text("Стадия: \(project.stage.title) — \(project.stage.subtitle)").font(.caption)
                }
                Picker("Раздел", selection: $tab) {
                    Text("Обзор").tag(0)
                    Text("Материалы").tag(1)
                    Text("Эксперименты").tag(2)
                    Text("Тетрадь").tag(3)
                    Text("Экспертиза").tag(4)
                }
                .pickerStyle(.segmented)

                switch tab {
                case 0: overview(index: index, canEdit: canEdit)
                case 1: media(index: index, canEdit: canEdit)
                case 2: ExperimentJournalView(projectID: projectID, canEdit: canEdit)
                case 3: LabNotebookView(projectID: projectID, canEdit: canEdit)
                default: projectReviews(project: project)
                }
            }
        }
    }

    @ViewBuilder
    private func overview(index: Int, canEdit: Bool) -> some View {
        let project = store.db.projects[index]
        KCard {
            Text("Проблема").font(.headline)
            TextField("Какую проблему решает проект?", text: $store.db.projects[index].problem, axis: .vertical)
                .disabled(!canEdit)
            Text("Решение").font(.headline)
            TextField("Как работает решение?", text: $store.db.projects[index].solution, axis: .vertical)
                .disabled(!canEdit)
            if project.track == .inclusiveEngineering || !project.inclusiveTarget.isEmpty {
                Text("Для кого (инклюзия)").font(.headline)
                TextField("Целевая группа", text: $store.db.projects[index].inclusiveTarget).disabled(!canEdit)
            }
        }
        // Команда (50) и наставник (51)
        KCard {
            Text("Команда и наставник").font(.headline)
            if let team = store.db.teams.first(where: { $0.id == project.teamID }) {
                KInfoRow(label: "Команда", value: team.name)
            }
            KInfoRow(label: "Авторы", value: project.authorIDs.map { store.userName($0) }.joined(separator: ", "))
            if store.role.canTeach || store.role == .mentor {
                Picker("Наставник", selection: $store.db.projects[index].mentorID) {
                    Text("Не назначен").tag(UUID?.none)
                    ForEach(store.db.users.filter { $0.role == .mentor || $0.role == .teacher || $0.role == .expert }) {
                        Text("\($0.fullName) (\($0.role.title))").tag(UUID?.some($0.id))
                    }
                }
                .onChange(of: store.db.projects[index].mentorID) { _, mentor in
                    if let mentor { store.notify(mentor, "Вы назначены наставником", project.title, kind: .info) }
                }
                Picker("Команда", selection: $store.db.projects[index].teamID) {
                    Text("Без команды").tag(UUID?.none)
                    ForEach(store.db.teams) { Text($0.name).tag(UUID?.some($0.id)) }
                }
            } else {
                KInfoRow(label: "Наставник", value: store.userName(project.mentorID))
            }
        }
        // Стадии (52)
        KCard {
            Text("Путь проекта").font(.headline)
            ForEach(project.stageHistory, id: \.self) { change in
                HStack(alignment: .top) {
                    Image(systemName: change.stage.icon).foregroundStyle(.tint).frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("\(change.stage.title) · \(change.date.kksuShort)").font(.callout.weight(.semibold))
                        if !change.note.isEmpty { Text(change.note).font(.caption) }
                    }
                }
            }
            if let next = project.stage.next, canEdit {
                TextField("Что сделано на этой стадии?", text: $stageNote).textFieldStyle(.roundedBorder)
                Button {
                    store.advance(projectID: project.id, note: stageNote)
                    stageNote = ""
                } label: {
                    Label("Перейти на стадию \(next.title)", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        if project.isPrototype || project.stage >= .prototype {
            KCard {
                Text("Прототип").font(.headline)
                TextField("Характеристики, компоненты", text: $store.db.projects[index].prototypeSpecs, axis: .vertical).disabled(!canEdit)
                Toggle("Показывать на виртуальной выставке", isOn: $store.db.projects[index].showInExhibition).disabled(!canEdit)
            }
        }
        if canEdit && store.role == .student {
            RouteRow(route: .yiApply, subtitle: "Подать проект на Young Inventors 30")
        }
    }

    @ViewBuilder
    private func media(index: Int, canEdit: Bool) -> some View {
        let project = store.db.projects[index]
        KCard {
            Text("Фото, видео, чертежи и документы").font(.headline)
            if project.media.isEmpty { KEmptyState(text: "Материалов пока нет", icon: "photo.on.rectangle") }
            ForEach(AttachmentKind.allCases) { kind in
                let files = project.media.filter { $0.kind == kind }
                if !files.isEmpty {
                    Text(kind.title).font(.subheadline.weight(.semibold)).padding(.top, 4)
                    ForEach(files) { AttachmentRow(attachment: $0) }
                }
            }
        }
        if canEdit {
            KCard {
                Text("Загрузить материалы").font(.headline)
                AttachmentPicker(attachments: $newMedia)
                if !newMedia.isEmpty {
                    Button("Добавить в проект (\(newMedia.count))") {
                        store.db.projects[index].media += newMedia
                        newMedia = []
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder
    private func projectReviews(project: InventionProject) -> some View {
        let apps = store.db.yiApplications.filter { $0.projectID == project.id }
        let reviews = store.reviews(for: project.id) + apps.flatMap { store.reviews(for: $0.id) }
        if reviews.isEmpty { KEmptyState(text: "Экспертных оценок пока нет", icon: "star") }
        ForEach(reviews) { ReviewCard(review: $0) }
        if store.role.canReview {
            NavigationLink { ExpertReviewFormView(targetID: project.id, target: .project, criteria: ExpertReview.projectCriteria) } label: {
                Label("Оценить проект", systemImage: "checkmark.seal")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ProjectEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let track: ProjectTrack
    @State private var project = InventionProject(title: "", summary: "")
    @State private var coauthors: Set<UUID> = []

    var body: some View {
        Form {
            Section("Идея") {
                TextField("Название проекта", text: $project.title)
                TextField("Кратко о проекте", text: $project.summary, axis: .vertical)
                TextField("Проблема", text: $project.problem, axis: .vertical)
                Picker("Направление", selection: $project.track) {
                    ForEach(ProjectTrack.allCases) { Text($0.title).tag($0) }
                }
                if project.track == .inclusiveEngineering {
                    TextField("Для кого разработка (целевая группа)", text: $project.inclusiveTarget)
                }
            }
            Section("Соавторы") {
                ForEach(store.students.filter { $0.id != store.currentUser?.id }) { student in
                    Toggle(student.fullName, isOn: Binding(
                        get: { coauthors.contains(student.id) },
                        set: { on in if on { coauthors.insert(student.id) } else { coauthors.remove(student.id) } }))
                }
            }
        }
        .navigationTitle("Новый проект")
        .onAppear { project.track = track }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Создать") {
                    var authors = Array(coauthors)
                    if let me = store.currentUser, me.role == .student { authors.insert(me.id, at: 0) }
                    if store.currentUser?.role == .mentor { project.mentorID = store.currentUser?.id }
                    project.authorIDs = authors
                    project.stageHistory = [StageChange(stage: .idea, date: Date(), note: "Проект создан")]
                    store.db.projects.append(project)
                    authors.forEach { store.log($0, "Создан проект", details: project.title, icon: "lightbulb") }
                    dismiss()
                }
                .disabled(project.title.isEmpty)
            }
        }
    }
}

// MARK: - Журнал экспериментов (задача 53)

struct ExperimentJournalView: View {
    @EnvironmentObject private var store: KKSUStore
    let projectID: UUID
    let canEdit: Bool
    @State private var hypothesis = ""
    @State private var method = ""
    @State private var result = ""
    @State private var conclusion = ""
    @State private var success = true

    var body: some View {
        let entries = store.db.experiments.filter { $0.projectID == projectID }.sorted { $0.date > $1.date }
        let rate = entries.isEmpty ? 0 : Double(entries.filter(\.success).count) / Double(entries.count)
        KCard {
            HStack {
                Text("Экспериментов: \(entries.count)").font(.headline)
                Spacer()
                KBadge(text: "Подтверждено гипотез: \(Int(rate * 100))%", color: KKSUTheme.success)
            }
        }
        ForEach(entries) { entry in
            KCard {
                HStack {
                    Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(entry.success ? KKSUTheme.success : KKSUTheme.danger)
                    Text(entry.date.kksuDateTime).font(.caption)
                    Spacer()
                    Text(store.userName(entry.authorID)).font(.caption).foregroundStyle(.secondary)
                }
                KInfoRow(label: "Гипотеза", value: entry.hypothesis)
                KInfoRow(label: "Метод", value: entry.method)
                KInfoRow(label: "Результат", value: entry.result)
                KInfoRow(label: "Вывод", value: entry.conclusion)
            }
        }
        if canEdit {
            KCard {
                Text("Новая запись").font(.headline)
                TextField("Гипотеза", text: $hypothesis, axis: .vertical).textFieldStyle(.roundedBorder)
                TextField("Метод / условия эксперимента", text: $method, axis: .vertical).textFieldStyle(.roundedBorder)
                TextField("Результат", text: $result, axis: .vertical).textFieldStyle(.roundedBorder)
                TextField("Вывод", text: $conclusion, axis: .vertical).textFieldStyle(.roundedBorder)
                Toggle("Гипотеза подтвердилась", isOn: $success)
                Button("Записать эксперимент") {
                    guard let me = store.currentUser?.id else { return }
                    store.db.experiments.append(ExperimentEntry(projectID: projectID, authorID: me, hypothesis: hypothesis, method: method, result: result, conclusion: conclusion, success: success))
                    store.log(me, "Эксперимент в журнале", details: hypothesis, icon: "testtube.2")
                    hypothesis = ""; method = ""; result = ""; conclusion = ""
                }
                .disabled(hypothesis.isEmpty || result.isEmpty)
            }
        }
    }
}

// MARK: - Электронная лабораторная тетрадь (задача 54)

struct LabNotebookView: View {
    @EnvironmentObject private var store: KKSUStore
    let projectID: UUID
    let canEdit: Bool
    @State private var title = ""
    @State private var content = ""
    @State private var measurements: [LabMeasurement] = []
    @State private var mName = ""
    @State private var mValue = ""
    @State private var mUnit = ""

    var body: some View {
        let pages = store.db.notebook.filter { $0.projectID == projectID }.sorted { $0.date > $1.date }
        if pages.isEmpty { KEmptyState(text: "Страниц пока нет", icon: "book.closed") }
        ForEach(pages) { page in
            KCard {
                HStack {
                    Text(page.title).font(.headline)
                    Spacer()
                    if page.signedByMentor {
                        Label("Подписано наставником", systemImage: "signature").font(.caption).foregroundStyle(KKSUTheme.success)
                    } else if store.role == .mentor || store.role.canTeach {
                        Button("Подписать") {
                            if let index = store.db.notebook.firstIndex(where: { $0.id == page.id }) {
                                store.db.notebook[index].signedByMentor = true
                            }
                        }
                        .font(.caption)
                    }
                }
                Text("\(page.date.kksuDateTime) · \(store.userName(page.authorID))").font(.caption).foregroundStyle(.secondary)
                Text(page.content).font(.body.monospaced())
                if !page.measurements.isEmpty {
                    Divider()
                    ForEach(page.measurements) { m in
                        KInfoRow(label: m.name, value: "\(m.value.formatted()) \(m.unit)")
                    }
                }
            }
        }
        if canEdit {
            KCard {
                Text("Новая страница").font(.headline)
                TextField("Заголовок", text: $title).textFieldStyle(.roundedBorder)
                TextField("Наблюдения, расчёты, схемы словами", text: $content, axis: .vertical)
                    .lineLimit(4...12)
                    .textFieldStyle(.roundedBorder)
                Text("Измерения").font(.subheadline.weight(.semibold))
                ForEach(measurements) { m in KInfoRow(label: m.name, value: "\(m.value.formatted()) \(m.unit)") }
                HStack {
                    TextField("Величина", text: $mName)
                    TextField("Значение", text: $mValue)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Ед.", text: $mUnit).frame(width: 60)
                    Button { addMeasurement() } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Добавить измерение")
                }
                .textFieldStyle(.roundedBorder)
                Button("Сохранить страницу") {
                    guard let me = store.currentUser?.id else { return }
                    store.db.notebook.append(LabNotebookPage(projectID: projectID, authorID: me, title: title, content: content, measurements: measurements))
                    title = ""; content = ""; measurements = []
                }
                .disabled(title.isEmpty)
            }
        }
    }

    private func addMeasurement() {
        guard !mName.isEmpty, let value = Double(mValue.replacingOccurrences(of: ",", with: ".")) else { return }
        measurements.append(LabMeasurement(name: mName, value: value, unit: mUnit))
        mName = ""; mValue = ""; mUnit = ""
    }
}

// MARK: - Проектные команды (задача 50)

struct TeamsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var name = ""
    @State private var members: Set<UUID> = []

    var body: some View {
        KPage("Проектные команды") {
            ForEach(store.db.teams) { team in
                KCard {
                    HStack {
                        Label(team.name, systemImage: "person.3.fill").font(.headline)
                        Spacer()
                        Text("\(team.memberIDs.count) уч.").font(.caption)
                    }
                    ForEach(team.memberIDs, id: \.self) { member in
                        HStack {
                            KAvatar(name: store.userName(member), size: 28)
                            Text(store.userName(member))
                            if team.captainID == member { KBadge(text: "Капитан", color: KKSUTheme.accent) }
                        }
                    }
                    let projects = store.db.projects.filter { $0.teamID == team.id }
                    if !projects.isEmpty {
                        Text("Проекты: " + projects.map(\.title).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                    }
                    if let me = store.currentUser?.id, store.role == .student, !team.memberIDs.contains(me),
                       let index = store.db.teams.firstIndex(where: { $0.id == team.id }) {
                        Button("Вступить в команду") { store.db.teams[index].memberIDs.append(me) }
                    }
                }
            }
            KCard {
                Text("Создать команду").font(.headline)
                TextField("Название команды", text: $name).textFieldStyle(.roundedBorder)
                ForEach(store.students) { student in
                    Toggle(student.fullName, isOn: Binding(
                        get: { members.contains(student.id) || student.id == store.currentUser?.id },
                        set: { on in if on { members.insert(student.id) } else { members.remove(student.id) } }))
                        .disabled(student.id == store.currentUser?.id)
                }
                Button("Создать") {
                    var ids = members
                    if let me = store.currentUser, me.role == .student { ids.insert(me.id) }
                    store.db.teams.append(ProjectTeam(name: name, memberIDs: Array(ids), captainID: store.currentUser?.role == .student ? store.currentUser?.id : ids.first))
                    name = ""; members = []
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

// MARK: - Каталог прототипов (задача 55)

struct PrototypeCatalogView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let prototypes = store.db.projects.filter { $0.isPrototype || $0.stage >= .prototype }
        KPage("Каталог прототипов KKSU") {
            Text("Все прототипы, созданные учениками KKSU: характеристики, стадия испытаний и материалы.")
                .font(.callout).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                ForEach(prototypes) { project in
                    NavigationLink { ProjectDetailView(projectID: project.id) } label: {
                        KCard {
                            Label(project.title, systemImage: "cube.transparent.fill").font(.headline)
                            Text(project.track.title).font(.caption).foregroundStyle(.secondary)
                            if !project.prototypeSpecs.isEmpty {
                                Text(project.prototypeSpecs).font(.caption.monospaced())
                            }
                            StageProgress(stage: project.stage)
                            Text("Испытаний: \(store.db.experiments.filter { $0.projectID == project.id }.count) · материалов: \(project.media.count)")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Young Inventors 30 (задачи 56–58)

struct YoungInventorsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let apps = store.db.yiApplications
        KPage("Young Inventors 30") {
            KCard {
                Label("Young Inventors 30", systemImage: "sparkles").font(.title2.bold()).foregroundStyle(KKSUTheme.accent)
                Text("Ежегодный конкурс 30 лучших молодых изобретателей KKSU и партнёров. Экспертное жюри, наставники, выставка и сертификаты.")
                Text("Сезон \(Calendar.current.component(.year, from: Date())) · номинации: Инклюзивные технологии, Инженерия, AI, Экология, Культурное наследие")
                    .font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                KStatTile(title: "Заявок", value: "\(apps.count)", icon: "doc.text.fill")
                KStatTile(title: "На экспертизе", value: "\(apps.filter { $0.status == .underReview || $0.status == .submitted }.count)", icon: "hourglass", color: KKSUTheme.warning)
                KStatTile(title: "Финалистов", value: "\(apps.filter { $0.status == .finalist }.count)", icon: "star.fill", color: KKSUTheme.accent)
                KStatTile(title: "Победителей", value: "\(apps.filter { $0.status == .winner }.count)", icon: "trophy.fill", color: KKSUTheme.success)
            }
            HStack {
                if store.role == .student { RouteTile(route: .yiApply) }
                if store.role.canReview { RouteTile(route: .yiReview) }
                RouteTile(route: .exhibition)
            }
            KSectionHeader(title: "Заявки сезона", icon: "list.bullet")
            ForEach(apps) { YIApplicationCard(application: $0) }
        }
    }
}

struct YIApplicationCard: View {
    @EnvironmentObject private var store: KKSUStore
    let application: YoungInventorsApplication

    var body: some View {
        let project = store.project(application.projectID)
        let reviews = store.reviews(for: application.id)
        let avg = reviews.isEmpty ? nil : reviews.map(\.average).reduce(0, +) / Double(reviews.count)
        KCard {
            HStack {
                Text(project?.title ?? "Проект").font(.headline)
                Spacer()
                KBadge(text: application.status.title, color: application.status == .rejected ? KKSUTheme.danger : KKSUTheme.accent)
            }
            Text("\(store.userName(application.applicantID)) · \(application.nomination) · \(application.date.kksuShort)").font(.caption).foregroundStyle(.secondary)
            Text(application.motivation).font(.callout)
            if let avg { Label(String(format: "Оценка жюри: %.1f / 10 (%d экспертиз)", avg, reviews.count), systemImage: "star.fill").font(.caption) }
            if store.role == .admin, let index = store.db.yiApplications.firstIndex(where: { $0.id == application.id }) {
                Picker("Статус", selection: $store.db.yiApplications[index].status) {
                    ForEach(YIStatus.allCases) { Text($0.title).tag($0) }
                }
                .onChange(of: store.db.yiApplications[index].status) { _, status in
                    if status == .winner || status == .finalist {
                        store.issueCertificate(to: application.applicantID, title: "\(status.title) Young Inventors 30 — «\(project?.title ?? "")»", issuer: .youngInventors)
                    }
                }
            }
        }
    }
}

struct YoungInventorsApplyView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var projectID: UUID?
    @State private var nomination = "Инклюзивные технологии"
    @State private var motivation = ""
    @State private var sent = false

    private let nominations = ["Инклюзивные технологии", "Инженерия и машиностроение", "Искусственный интеллект", "Экология и энергия", "Культурное наследие"]

    var body: some View {
        let me = store.currentUser?.id
        let myProjects = store.db.projects.filter { project in me.map { project.authorIDs.contains($0) } ?? false }
        Form {
            if sent {
                Label("Заявка подана! Эксперты рассмотрят её в течение 2 недель.", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
            }
            Section("Проект") {
                if myProjects.isEmpty {
                    Text("Сначала создайте проект в KKSU Inventions.").foregroundStyle(.secondary)
                }
                Picker("Проект", selection: $projectID) {
                    Text("Выберите").tag(UUID?.none)
                    ForEach(myProjects) { Text($0.title).tag(UUID?.some($0.id)) }
                }
                Picker("Номинация", selection: $nomination) {
                    ForEach(nominations, id: \.self) { Text($0) }
                }
            }
            Section("Мотивация") {
                TextField("Почему ваш проект важен?", text: $motivation, axis: .vertical)
            }
            Section("Требования") {
                Label("Проект на стадии Prototype или выше", systemImage: stageOK ? "checkmark.circle.fill" : "circle")
                Label("Есть материалы (фото/видео/чертежи)", systemImage: mediaOK ? "checkmark.circle.fill" : "circle")
                Label("Есть записи в журнале экспериментов", systemImage: experimentsOK ? "checkmark.circle.fill" : "circle")
            }
            Section {
                Button("Подать заявку") { submit() }
                    .disabled(projectID == nil || motivation.isEmpty || !stageOK)
            }
        }
        .navigationTitle("Заявка Young Inventors")
    }

    private var project: InventionProject? { projectID.flatMap { store.project($0) } }
    private var stageOK: Bool { (project?.stage ?? .idea) >= .prototype }
    private var mediaOK: Bool { !(project?.media.isEmpty ?? true) }
    private var experimentsOK: Bool { store.db.experiments.contains { $0.projectID == projectID } }

    private func submit() {
        guard let projectID, let me = store.currentUser?.id else { return }
        let season = "\(Calendar.current.component(.year, from: Date()))"
        store.db.yiApplications.append(YoungInventorsApplication(projectID: projectID, applicantID: me, season: season, nomination: nomination, motivation: motivation))
        for expert in store.db.users where expert.role == .expert || expert.role == .mentor {
            store.notify(expert.id, "Новая заявка Young Inventors 30", project?.title ?? "", kind: .info)
        }
        store.log(me, "Заявка на Young Inventors 30", details: project?.title ?? "", icon: "sparkles")
        sent = true
        motivation = ""
    }
}

struct YoungInventorsReviewView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        KPage("Экспертиза проектов") {
            Text("Оценка по 5 критериям: новизна, техническая проработка, социальная значимость, прототип, презентация. Средний балл 8+ выводит заявку в финал.")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(store.db.yiApplications) { app in
                let reviewed = store.db.reviews.contains { $0.targetID == app.id && $0.expertID == me }
                VStack(alignment: .leading, spacing: 8) {
                    YIApplicationCard(application: app)
                    HStack {
                        NavigationLink { ProjectDetailView(projectID: app.projectID) } label: { Label("Карточка проекта", systemImage: "doc.text") }
                        Spacer()
                        if reviewed {
                            Label("Оценено", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success)
                        } else {
                            NavigationLink { ExpertReviewFormView(targetID: app.id, target: .youngInventors, criteria: ExpertReview.projectCriteria) } label: {
                                Label("Оценить", systemImage: "star.leadinghalf.filled")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }
}

// MARK: - Виртуальная выставка (задача 59)

struct VirtualExhibitionView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var liked: Set<UUID> = []

    var body: some View {
        let exhibits = store.db.projects.filter(\.showInExhibition).sorted { $0.likes > $1.likes }
        KPage("Виртуальная выставка") {
            Text("Изобретения учеников KKSU. Голосуйте за понравившиеся проекты!")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(ProjectTrack.allCases) { track in
                let items = exhibits.filter { $0.track == track }
                if !items.isEmpty {
                    KSectionHeader(title: track.title, icon: track.icon)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items) { project in
                                ExhibitCard(project: project, liked: liked.contains(project.id)) {
                                    guard !liked.contains(project.id),
                                          let index = store.db.projects.firstIndex(where: { $0.id == project.id }) else { return }
                                    store.db.projects[index].likes += 1
                                    liked.insert(project.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ExhibitCard: View {
    @EnvironmentObject private var store: KKSUStore
    let project: InventionProject
    let liked: Bool
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(colors: [KKSUTheme.primary, KKSUTheme.accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: project.track.icon).font(.system(size: 44)).foregroundStyle(.white)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
            Text(project.title).font(.headline).lineLimit(2)
            Text(project.summary).font(.caption).lineLimit(3).foregroundStyle(.secondary)
            if let alt = project.media.first(where: { !$0.altText.isEmpty })?.altText {
                Label(alt, systemImage: "text.below.photo").font(.caption2).lineLimit(2)
            }
            HStack {
                Button(action: onLike) {
                    Label("\(project.likes)", systemImage: liked ? "heart.fill" : "heart")
                }
                .foregroundStyle(KKSUTheme.danger)
                Spacer()
                NavigationLink("Подробнее") { ProjectDetailView(projectID: project.id) }
                    .font(.caption)
            }
        }
        .padding(12)
        .frame(width: 240)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.18)))
    }
}
