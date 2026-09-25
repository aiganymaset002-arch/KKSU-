//
//  KKSULibraryAndTests.swift
//  KKSU Online
//
//  Библиотеки: видеоуроки (26), методические материалы (27, 40),
//  PDF/презентации/инструкции/учебники (28), субтитры (75), текстовые альтернативы (76).
//  Тестирование: онлайн-тесты (29), автопроверка (30), конструктор тестов (31, 41).
//

import SwiftUI
import AVKit

// MARK: - Библиотека

struct LibraryListView: View {
    @EnvironmentObject private var store: KKSUStore
    let kinds: [LibraryKind]
    let title: String
    var teacherAcademyOnly = false
    @State private var query = ""
    @State private var subject: String?
    @State private var showEditor = false

    private var items: [LibraryItem] {
        store.db.library.filter { item in
            kinds.contains(item.kind) &&
            (!teacherAcademyOnly || item.isTeacherAcademy || item.forTeachers) &&
            (subject == nil || item.subject == subject) &&
            (query.isEmpty || item.title.localizedCaseInsensitiveContains(query) || item.summary.localizedCaseInsensitiveContains(query) || item.textAlternative.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        let subjects = Array(Set(store.db.library.filter { kinds.contains($0.kind) }.map(\.subject))).sorted()
        KPage(title) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все", selected: subject == nil) { subject = nil }
                    ForEach(subjects, id: \.self) { item in
                        FilterChip(title: item, selected: subject == item) { subject = item }
                    }
                }
            }
            if items.isEmpty { KEmptyState(text: "Материалы не найдены", icon: "magnifyingglass") }
            ForEach(items) { item in
                NavigationLink { LibraryItemDetailView(itemID: item.id) } label: { LibraryItemRow(item: item) }
                    .buttonStyle(.plain)
            }
            if store.role.canTeach || store.role == .psychologist || store.role == .expert {
                PrimaryButton(title: "Добавить материал", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .searchable(text: $query, prompt: "Поиск, в том числе по тексту материалов")
        .sheet(isPresented: $showEditor) {
            NavigationStack { LibraryItemEditorView(defaultKind: kinds.first ?? .methodical, teacherAcademy: teacherAcademyOnly) }
        }
    }
}

struct LibraryItemRow: View {
    let item: LibraryItem

    var body: some View {
        KCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.kind.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(KKSUTheme.softBlue, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.headline)
                    Text("\(item.kind.title) · \(item.subject) · \(item.author)").font(.caption).foregroundStyle(.secondary)
                    Text(item.summary).font(.callout).lineLimit(2)
                    HStack(spacing: 6) {
                        if !item.captions.isEmpty { KBadge(text: "CC субтитры", color: KKSUTheme.success) }
                        if !item.textAlternative.isEmpty { KBadge(text: "Текстовая версия", color: .purple) }
                        if item.durationMinutes > 0 { KBadge(text: "\(item.durationMinutes) мин") }
                        LibraryPriceBadge(itemID: item.id)
                    }
                }
            }
        }
    }
}

struct LibraryItemDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.kksuAccessibility) private var a11y
    let itemID: UUID
    @State private var showText = false

    var body: some View {
        if let item = store.db.library.first(where: { $0.id == itemID }) {
            KPage(item.title) {
                PaywallGate(product: store.product(forRef: item.id), message: "Платный курс. Видео, субтитры и материалы откроются после подтверждения оплаты или по подписке KKSU.") {
                if item.kind == .video, let url = URL(string: item.url), !item.url.isEmpty {
                    CaptionedVideoPlayer(url: url, captions: item.captions, captionsOn: a11y.captionsEnabled)
                } else if item.kind == .video {
                    CaptionedVideoPlayer(url: nil, captions: item.captions, captionsOn: true)
                }
                KCard {
                    Text(item.title).font(.title3.bold())
                    Text("\(item.kind.title) · \(item.subject) · автор: \(item.author)").font(.caption).foregroundStyle(.secondary)
                    Text(item.summary)
                    FlowTags(tags: item.tags)
                    if item.kind != .video, let url = URL(string: item.url), !item.url.isEmpty {
                        HStack {
                            Link(destination: url) { Label("Открыть \(item.kind.title.lowercased())", systemImage: "arrow.up.right.square") }
                            Spacer()
                            ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                        }
                    }
                }
                if !item.textAlternative.isEmpty {
                    KCard {
                        DisclosureGroup(isExpanded: Binding(get: { showText || a11y.showTextAlternatives }, set: { showText = $0 })) {
                            Text(item.textAlternative)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding(.top, 6)
                        } label: {
                            Label("Текстовая альтернатива", systemImage: "text.alignleft").font(.headline)
                        }
                    }
                }
                if !item.captions.isEmpty {
                    KCard {
                        Text("Расшифровка видео").font(.headline)
                        ForEach(item.captions, id: \.self) { caption in
                            HStack(alignment: .top) {
                                Text(timeString(caption.start)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                Text(caption.text).font(.callout)
                            }
                        }
                    }
                }
                }
            }
            .onAppear { markViewed(item) }
        }
    }

    private func timeString(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    private func markViewed(_ item: LibraryItem) {
        guard let me = store.currentUser?.id else { return }
        if let index = store.db.library.firstIndex(where: { $0.id == item.id }) { store.db.library[index].views += 1 }
        var viewed = store.db.viewedLibraryIDs[me] ?? []
        if !viewed.contains(item.id) {
            viewed.append(item.id)
            store.db.viewedLibraryIDs[me] = viewed
            store.log(me, "Изучен материал", details: item.title, icon: item.kind.icon)
        }
    }
}

// MARK: - Видео с субтитрами (задача 75)

@MainActor
final class CaptionPlayerModel: ObservableObject {
    @Published var currentTime: Double = 0
    let player: AVPlayer?
    private var observer: Any?
    private var timer: Timer?

    init(url: URL?) {
        player = url.map { AVPlayer(url: $0) }
        if let player {
            observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
                let seconds = time.seconds
                Task { @MainActor in self?.currentTime = seconds }
            }
        }
    }

    /// Для материалов без видеофайла — воспроизведение расшифровки по таймеру.
    func startTranscriptPlayback() {
        timer?.invalidate()
        currentTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.currentTime += 0.25 }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.pause()
        if let observer { player?.removeTimeObserver(observer) }
        observer = nil
    }
}

struct CaptionedVideoPlayer: View {
    let captions: [CaptionSegment]
    let captionsOn: Bool
    @StateObject private var model: CaptionPlayerModel
    @State private var showCaptions: Bool

    init(url: URL?, captions: [CaptionSegment], captionsOn: Bool) {
        self.captions = captions
        self.captionsOn = captionsOn
        _model = StateObject(wrappedValue: CaptionPlayerModel(url: url))
        _showCaptions = State(initialValue: captionsOn)
    }

    private var currentCaption: String? {
        captions.first { model.currentTime >= $0.start && model.currentTime < $0.end }?.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottom) {
                if let player = model.player {
                    VideoPlayer(player: player)
                } else {
                    Rectangle().fill(Color.black)
                        .overlay {
                            Button { model.startTranscriptPlayback() } label: {
                                Label("Воспроизвести с субтитрами", systemImage: "play.circle.fill").font(.title3)
                            }
                            .foregroundStyle(.white)
                        }
                }
                if showCaptions, let caption = currentCaption {
                    Text(caption)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 44)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                        .accessibilityLabel("Субтитры: \(caption)")
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Toggle(isOn: $showCaptions) {
                Label("Субтитры", systemImage: "captions.bubble.fill")
            }
            .disabled(captions.isEmpty)
        }
        .onDisappear { model.stop() }
    }
}

struct LibraryItemEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let defaultKind: LibraryKind
    let teacherAcademy: Bool
    @State private var item = LibraryItem(title: "", kind: .methodical, subject: "", author: "", summary: "")
    @State private var captionsText = ""

    var body: some View {
        Form {
            Section("Материал") {
                TextField("Название", text: $item.title)
                Picker("Тип", selection: $item.kind) {
                    ForEach(LibraryKind.allCases) { Text($0.title).tag($0) }
                }
                TextField("Предмет", text: $item.subject)
                TextField("Автор", text: $item.author)
                TextField("Краткое описание", text: $item.summary, axis: .vertical)
                TextField("Ссылка на файл / видео", text: $item.url)
                    .autocorrectionDisabled()
                if item.kind == .video {
                    Stepper("Длительность: \(item.durationMinutes) мин", value: $item.durationMinutes, in: 0...180)
                }
            }
            Section("Доступность") {
                TextField("Текстовая альтернатива (обязательно для инклюзии)", text: $item.textAlternative, axis: .vertical)
                if item.kind == .video {
                    TextField("Субтитры: каждая строка «секунды | текст»", text: $captionsText, axis: .vertical)
                        .font(.callout.monospaced())
                }
            }
            Section("Аудитория") {
                Toggle("Для педагогов", isOn: $item.forTeachers)
                Toggle("Методическая библиотека Teacher Academy", isOn: $item.isTeacherAcademy)
            }
        }
        .navigationTitle("Новый материал")
        .onAppear {
            item.kind = defaultKind
            item.isTeacherAcademy = teacherAcademy
            item.forTeachers = teacherAcademy
            item.author = store.currentUser?.fullName ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    item.captions = Self.parseCaptions(captionsText)
                    store.db.library.append(item)
                    dismiss()
                }
                .disabled(item.title.isEmpty || item.textAlternative.isEmpty)
            }
        }
    }

    static func parseCaptions(_ text: String) -> [CaptionSegment] {
        let lines = text.split(separator: "\n").compactMap { line -> (Double, String)? in
            let parts = line.split(separator: "|", maxSplits: 1)
            guard parts.count == 2, let start = Double(parts[0].trimmingCharacters(in: .whitespaces)) else { return nil }
            return (start, parts[1].trimmingCharacters(in: .whitespaces))
        }
        return lines.enumerated().map { index, entry in
            let end = index + 1 < lines.count ? lines[index + 1].0 : entry.0 + 5
            return CaptionSegment(start: entry.0, end: end, text: entry.1)
        }
    }
}

// MARK: - Онлайн-тестирование (задачи 29, 30)

struct TestListView: View {
    @EnvironmentObject private var store: KKSUStore
    let audience: AssignmentAudience

    var body: some View {
        let tests = store.db.tests.filter { $0.audience == audience && ($0.isPublished || store.role.canTeach) }
        KPage(audience == .students ? "Онлайн-тестирование" : "Тесты педагогов") {
            if store.role.canTeach {
                NavigationLink(value: KKSURoute.testBuilder) {
                    Label("Создать тест в конструкторе", systemImage: "hammer.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            if audience == .students {
                EnrollmentGate {
                    ForEach(tests) { test in
                        TestCard(test: test)
                    }
                }
            } else {
                ForEach(tests) { test in
                    TestCard(test: test)
                }
            }
        }
    }
}

struct TestCard: View {
    @EnvironmentObject private var store: KKSUStore
    let test: KKSUTest

    var body: some View {
        let attempts = store.db.attempts.filter { $0.testID == test.id && $0.userID == store.currentUser?.id }
        let best = attempts.max { $0.percent < $1.percent }
        KCard {
            HStack {
                Text(test.title).font(.headline)
                Spacer()
                if !test.isPublished { KBadge(text: "Черновик", color: .secondary) }
            }
            Text("\(test.subject) · \(test.questions.count) вопросов · \(test.timeLimitMinutes) мин · проходной \(test.passingPercent)%")
                .font(.caption).foregroundStyle(.secondary)
            if let best {
                HStack {
                    KBadge(text: "Лучший результат: \(best.percent)%", color: best.passed ? KKSUTheme.success : KKSUTheme.danger)
                    Text("Попыток: \(attempts.count)").font(.caption)
                }
            }
            HStack {
                NavigationLink { TestTakingView(testID: test.id) } label: {
                    Label(attempts.isEmpty ? "Начать тест" : "Пройти ещё раз", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                if store.role.canTeach {
                    NavigationLink { TestResultsView(testID: test.id) } label: { Label("Результаты", systemImage: "chart.bar") }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct TestTakingView: View {
    @EnvironmentObject private var store: KKSUStore
    let testID: UUID
    @State private var answers: [UUID: TestAnswer] = [:]
    @State private var index = 0
    @State private var result: TestAttempt?
    @State private var startedAt = Date()
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let test = store.db.tests.first(where: { $0.id == testID }) {
            let remaining = max(0, Int(Double(test.timeLimitMinutes * 60) - now.timeIntervalSince(startedAt)))
            KPage(test.title) {
                if let result {
                    TestResultCard(test: test, attempt: result)
                    Button("Пройти заново") {
                        self.result = nil
                        answers = [:]
                        index = 0
                        startedAt = Date()
                    }
                } else if !test.questions.isEmpty {
                    let question = test.questions[min(index, test.questions.count - 1)]
                    HStack {
                        Text("Вопрос \(index + 1) из \(test.questions.count)").font(.headline)
                        Spacer()
                        Label(String(format: "%d:%02d", remaining / 60, remaining % 60), systemImage: "timer")
                            .foregroundStyle(remaining < 60 ? KKSUTheme.danger : .secondary)
                            .monospacedDigit()
                    }
                    KProgressBar(value: Double(index + 1) / Double(test.questions.count))
                    QuestionView(question: question, answer: binding(for: question))
                    HStack {
                        Button("Назад") { index -= 1 }.disabled(index == 0)
                        Spacer()
                        if index < test.questions.count - 1 {
                            Button("Далее") { index += 1 }.buttonStyle(.borderedProminent)
                        } else {
                            Button("Завершить тест") { finish(test) }.buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .onReceive(ticker) { value in
                guard result == nil else { return }
                now = value
                if remaining == 0 { finish(test) }
            }
        }
    }

    private func binding(for question: TestQuestion) -> Binding<TestAnswer> {
        Binding(
            get: { answers[question.id] ?? TestAnswer(questionID: question.id) },
            set: { answers[question.id] = $0 }
        )
    }

    private func finish(_ test: KKSUTest) {
        guard result == nil, let me = store.currentUser?.id else { return }
        result = store.submitTest(test, answers: Array(answers.values), userID: me)
    }
}

struct QuestionView: View {
    let question: TestQuestion
    @Binding var answer: TestAnswer

    var body: some View {
        KCard {
            Text(question.text).font(.title3.weight(.semibold))
            Text("\(question.kind.title) · \(question.points) балл(а)").font(.caption).foregroundStyle(.secondary)
            switch question.kind {
            case .single, .multiple:
                ForEach(Array(question.options.enumerated()), id: \.offset) { offset, option in
                    let selected = answer.selected.contains(offset)
                    Button {
                        if question.kind == .single {
                            answer.selected = [offset]
                        } else if selected {
                            answer.selected.removeAll { $0 == offset }
                        } else {
                            answer.selected.append(offset)
                        }
                    } label: {
                        HStack {
                            Image(systemName: question.kind == .single ? (selected ? "largecircle.fill.circle" : "circle") : (selected ? "checkmark.square.fill" : "square"))
                                .foregroundStyle(.tint)
                            Text(option)
                            Spacer()
                        }
                        .padding(12)
                        .background(selected ? KKSUTheme.softBlue : Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            case .number:
                TextField("Введите число", text: $answer.text)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            case .text:
                TextField("Ваш ответ", text: $answer.text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct TestResultCard: View {
    let test: KKSUTest
    let attempt: TestAttempt

    var body: some View {
        KCard {
            HStack {
                Image(systemName: attempt.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(attempt.passed ? KKSUTheme.success : KKSUTheme.danger)
                VStack(alignment: .leading) {
                    Text(attempt.passed ? "Тест сдан!" : "Тест не сдан").font(.title2.bold())
                    Text("\(attempt.score) из \(attempt.maxScore) баллов · \(attempt.percent)%")
                }
            }
            Text("Проверено автоматически").font(.caption).foregroundStyle(.secondary)
        }
        ForEach(test.questions) { question in
            let answer = attempt.answers.first { $0.questionID == question.id }
            let correct = KKSUStore.evaluate(question, answer: answer)
            KCard {
                Label(question.text, systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? KKSUTheme.success : KKSUTheme.danger)
                if !correct {
                    Text("Правильный ответ: \(correctAnswer(question))").font(.callout)
                }
                if !question.explanation.isEmpty {
                    Text(question.explanation).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func correctAnswer(_ question: TestQuestion) -> String {
        switch question.kind {
        case .single, .multiple:
            return question.correctIndices.compactMap { question.options.indices.contains($0) ? question.options[$0] : nil }.joined(separator: ", ")
        case .number, .text:
            return question.correctText.replacingOccurrences(of: "|", with: " / ")
        }
    }
}

struct TestResultsView: View {
    @EnvironmentObject private var store: KKSUStore
    let testID: UUID

    var body: some View {
        let attempts = store.db.attempts.filter { $0.testID == testID }.sorted { $0.date > $1.date }
        let average = attempts.isEmpty ? 0 : attempts.reduce(0) { $0 + $1.percent } / attempts.count
        List {
            Section {
                KInfoRow(label: "Попыток", value: "\(attempts.count)")
                KInfoRow(label: "Средний результат", value: "\(average)%")
                KInfoRow(label: "Сдали", value: "\(attempts.filter(\.passed).count)")
            }
            Section("Попытки") {
                ForEach(attempts) { attempt in
                    HStack {
                        Text(store.userName(attempt.userID))
                        Spacer()
                        Text("\(attempt.percent)%").bold().foregroundStyle(attempt.passed ? KKSUTheme.success : KKSUTheme.danger)
                        Text(attempt.date.kksuShort).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Результаты теста")
    }
}

// MARK: - Конструктор тестов (задача 31)

struct TestBuilderView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var test = KKSUTest(title: "", subject: "", questions: [])
    @State private var saved = false

    var body: some View {
        Form {
            Section("Параметры теста") {
                TextField("Название", text: $test.title)
                TextField("Предмет", text: $test.subject)
                Stepper("Время: \(test.timeLimitMinutes) мин", value: $test.timeLimitMinutes, in: 1...180)
                Stepper("Проходной балл: \(test.passingPercent)%", value: $test.passingPercent, in: 10...100, step: 5)
                Picker("Для кого", selection: $test.audience) {
                    Text("Ученики").tag(AssignmentAudience.students)
                    Text("Педагоги (Teacher Academy)").tag(AssignmentAudience.teachers)
                }
                if test.audience == .teachers {
                    Picker("Курс Academy", selection: $test.courseID) {
                        Text("Без курса").tag(UUID?.none)
                        ForEach(store.db.teacherCourses) { Text($0.title).tag(UUID?.some($0.id)) }
                    }
                }
                Toggle("Опубликовать", isOn: $test.isPublished)
            }
            ForEach($test.questions) { $question in
                Section {
                    QuestionEditor(question: $question)
                    Button("Удалить вопрос", role: .destructive) {
                        test.questions.removeAll { $0.id == question.id }
                    }
                } header: {
                    Text("Вопрос \((test.questions.firstIndex { $0.id == question.id } ?? 0) + 1)")
                }
            }
            Section {
                Menu {
                    ForEach(QuestionKind.allCases) { kind in
                        Button(kind.title) {
                            test.questions.append(TestQuestion(text: "", kind: kind, options: kind == .single || kind == .multiple ? ["", ""] : []))
                        }
                    }
                } label: {
                    Label("Добавить вопрос", systemImage: "plus.circle.fill")
                }
                Text("Максимальный балл: \(test.maxScore)").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("Сохранить тест") { save() }
                    .disabled(!isValid)
                if saved { Label("Тест сохранён", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success) }
                if !isValid {
                    Text("Заполните название, предмет и хотя бы один вопрос с правильным ответом.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Конструктор тестов")
    }

    private var isValid: Bool {
        !test.title.isEmpty && !test.subject.isEmpty && !test.questions.isEmpty &&
        test.questions.allSatisfy { q in
            !q.text.isEmpty && (q.kind == .number || q.kind == .text ? !q.correctText.isEmpty : !q.correctIndices.isEmpty)
        }
    }

    private func save() {
        test.authorID = store.currentUser?.id
        for index in test.questions.indices where test.questions[index].kind == .single || test.questions[index].kind == .multiple {
            test.questions[index].options = test.questions[index].options.filter { !$0.isEmpty }
        }
        store.db.tests.append(test)
        if test.isPublished {
            let targets = test.audience == .students ? store.students : store.users(with: .teacher)
            for user in targets { store.notify(user.id, "Новый тест: \(test.title)", test.subject, kind: .info) }
        }
        test = KKSUTest(title: "", subject: "", questions: [])
        saved = true
    }
}

struct QuestionEditor: View {
    @Binding var question: TestQuestion

    var body: some View {
        TextField("Текст вопроса", text: $question.text, axis: .vertical)
        Picker("Тип", selection: $question.kind) {
            ForEach(QuestionKind.allCases) { Text($0.title).tag($0) }
        }
        Stepper("Баллов: \(question.points)", value: $question.points, in: 1...10)
        switch question.kind {
        case .single, .multiple:
            ForEach(question.options.indices, id: \.self) { index in
                HStack {
                    Button {
                        if question.kind == .single {
                            question.correctIndices = [index]
                        } else if question.correctIndices.contains(index) {
                            question.correctIndices.removeAll { $0 == index }
                        } else {
                            question.correctIndices.append(index)
                        }
                    } label: {
                        Image(systemName: question.correctIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(question.correctIndices.contains(index) ? KKSUTheme.success : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Отметить как правильный")
                    TextField("Вариант \(index + 1)", text: Binding(
                        get: { question.options.indices.contains(index) ? question.options[index] : "" },
                        set: { if question.options.indices.contains(index) { question.options[index] = $0 } }))
                }
            }
            Button("Добавить вариант") { question.options.append("") }
        case .number:
            TextField("Правильный ответ (число)", text: $question.correctText)
        case .text:
            TextField("Правильный ответ (варианты через |)", text: $question.correctText)
        }
        TextField("Пояснение после проверки", text: $question.explanation, axis: .vertical)
    }
}

struct LibraryPriceBadge: View {
    @EnvironmentObject private var store: KKSUStore
    let itemID: UUID

    var body: some View {
        if let product = store.product(forRef: itemID) {
            PriceBadge(product: product)
        }
    }
}
