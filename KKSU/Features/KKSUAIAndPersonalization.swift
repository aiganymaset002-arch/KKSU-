//
//  KKSUAIAndPersonalization.swift
//  KKSU Online
//
//  Адаптивный интерфейс и доступность (73, 74), субтитры/текстовые альтернативы — настройки (75, 76),
//  индивидуальные настройки обучения (77), рекомендации (78), AI-помощник KKSU (79),
//  AI-помощник педагога (80), генерация заданий с проверкой педагогом (81),
//  анализ прогресса (82), рекомендации педагогу (83).
//

import SwiftUI
import Charts

// MARK: - Доступность интерфейса (задачи 73, 74)

struct AccessibilitySettingsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var local = AccessibilitySettings()

    /// До входа настройки хранятся локально на экране, после входа — в профиле пользователя.
    private var settings: Binding<AccessibilitySettings> {
        if store.currentUser != nil {
            return Binding(get: { store.accessibility }, set: { store.accessibility = $0 })
        }
        return $local
    }

    var body: some View {
        Form {
            Section {
                Text("Пример текста: «Образование без барьеров — каждый учится в своём темпе».")
                    .padding(.vertical, 6)
            } header: { Text("Предпросмотр") }

            Section("Текст") {
                VStack(alignment: .leading) {
                    Text("Размер текста: \(Int(settings.wrappedValue.textScale * 100))%")
                    Slider(value: settings.textScale, in: 0.8...2.0, step: 0.1) {
                        Text("Размер текста")
                    } minimumValueLabel: {
                        Image(systemName: "textformat.size.smaller")
                    } maximumValueLabel: {
                        Image(systemName: "textformat.size.larger")
                    }
                }
                Toggle("Жирный шрифт", isOn: settings.boldText)
                Toggle("Шрифт, удобный при дислексии (скруглённый)", isOn: settings.dyslexiaFriendlyFont)
            }
            Section("Цвет и контраст") {
                Toggle("Высокий контраст", isOn: settings.highContrast)
                Picker("Тема", selection: settings.darkMode) {
                    ForEach(DarkModePreference.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("Интерфейс") {
                Toggle("Упрощённый интерфейс", isOn: settings.simplifiedInterface)
                Toggle("Крупные кнопки", isOn: settings.largeButtons)
                Toggle("Уменьшить анимацию", isOn: settings.reduceMotion)
            }
            Section("Материалы") {
                Toggle("Субтитры к видео по умолчанию", isOn: settings.captionsEnabled)
                Toggle("Всегда показывать текстовые альтернативы", isOn: settings.showTextAlternatives)
            }
            Section {
                Button("Сбросить настройки") { settings.wrappedValue = AccessibilitySettings() }
            } footer: {
                Text("Платформа также поддерживает системные VoiceOver, Dynamic Type и «Увеличенный контраст» iOS. Интерфейс адаптируется под iPhone и iPad.")
            }
        }
        .kksuAdaptive(settings.wrappedValue)
        .navigationTitle("Доступность")
    }
}

// MARK: - Настройки обучения (задача 77)

struct LearningSettingsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var interest = ""

    var body: some View {
        let prefs = Binding(get: { store.currentPreferences }, set: { store.currentPreferences = $0 })
        Form {
            Section("Темп") {
                Picker("Темп обучения", selection: prefs.pace) {
                    ForEach(LearningPace.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Stepper("Длительность занятия: \(prefs.wrappedValue.sessionMinutes) мин", value: prefs.sessionMinutes, in: 5...90, step: 5)
                Stepper("Цель в день: \(prefs.wrappedValue.dailyGoalMinutes) мин", value: prefs.dailyGoalMinutes, in: 10...240, step: 10)
                Toggle("Напоминать о перерывах", isOn: prefs.breakReminders)
            }
            Section("Предпочитаемые форматы") {
                ForEach(ContentFormat.allCases) { format in
                    Toggle(format.title, isOn: Binding(
                        get: { prefs.wrappedValue.formats.contains(format) },
                        set: { on in
                            if on { prefs.wrappedValue.formats.append(format) } else { prefs.wrappedValue.formats.removeAll { $0 == format } }
                        }))
                }
            }
            Section("Интересы (для рекомендаций)") {
                ForEach(prefs.wrappedValue.interests, id: \.self) { item in
                    Text(item)
                }
                .onDelete { prefs.wrappedValue.interests.remove(atOffsets: $0) }
                HStack {
                    TextField("Добавить интерес", text: $interest)
                    Button("Добавить") {
                        prefs.wrappedValue.interests.append(interest)
                        interest = ""
                    }
                    .disabled(interest.isEmpty)
                }
            }
            Section("AI") {
                Toggle("Подсказки AI-помощника", isOn: prefs.aiHintsEnabled)
            }
            Section { RouteRow(route: .accessibility, subtitle: "Размер текста, контраст, субтитры") }
        }
        .navigationTitle("Настройки обучения")
    }
}

// MARK: - Рекомендации контента (задача 78)

struct RecommendationsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Рекомендации") {
            Text("Подбор учитывает успеваемость, интересы, удобные форматы и темп обучения.")
                .font(.callout).foregroundStyle(.secondary)
            StudentScoped { studentID in
                let recs = RecommendationEngine.recommendations(for: studentID, store: store)
                if recs.isEmpty { KEmptyState(text: "Пока нечего рекомендовать", icon: "hand.thumbsup") }
                ForEach(recs) { RecommendationRow(recommendation: $0) }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: ContentRecommendation

    var body: some View {
        Group {
            if let item = recommendation.libraryItem {
                NavigationLink { LibraryItemDetailView(itemID: item.id) } label: { content }
            } else if let route = recommendation.route {
                NavigationLink(value: route) { content }
            } else {
                content
            }
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        KCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: recommendation.icon).font(.title3).foregroundStyle(.tint).frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.title).font(.headline)
                    Text(recommendation.reason).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - AI-помощник KKSU и педагога (задачи 79, 80)

struct AIAssistantView: View {
    @EnvironmentObject private var store: KKSUStore
    @ObservedObject private var ai = KKSUAIService.shared
    let mode: AIAssistantMode
    @State private var text = ""
    @State private var isThinking = false
    @State private var showSettings = false

    private var chatKey: UUID? { store.currentUser?.id }

    var body: some View {
        let messages = chatKey.flatMap { store.db.aiChats[$0] } ?? []
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        KCard {
                            Label(mode.title, systemImage: mode == .student ? "sparkles" : "wand.and.stars").font(.headline).foregroundStyle(.tint)
                            Text(mode == .student
                                 ? "Я помогу разобраться в теме, спланировать задания и подскажу ход решения. Решать будем вместе!"
                                 : "Помогу с планами уроков, адаптацией материалов, заданиями и обратной связью. Проверяйте результаты перед использованием.")
                                .font(.callout)
                            Label(ai.isConfigured ? "Режим: Claude (\(KKSUAIService.model))" : "Режим: локальный помощник", systemImage: ai.isConfigured ? "cloud.fill" : "iphone")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser { Spacer(minLength: 40) }
                                Text(message.text)
                                    .textSelection(.enabled)
                                    .padding(12)
                                    .foregroundStyle(message.isUser ? Color.white : Color.primary)
                                    .background(message.isUser ? KKSUTheme.primary : KKSUTheme.softBlue.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                                if !message.isUser { Spacer(minLength: 40) }
                            }
                            .id(message.id)
                        }
                        if isThinking {
                            HStack { SwiftUI.ProgressView(); Text("Думаю…").foregroundStyle(.secondary) }
                                .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(mode.suggestions, id: \.self) { suggestion in
                        Button(suggestion) { send(suggestion) }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 6)
            HStack(spacing: 10) {
                TextField(mode == .student ? "Спроси что-нибудь…" : "Запрос помощнику…", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                Button { send(text) } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
                    .accessibilityLabel("Отправить")
            }
            .padding(12)
        }
        .navigationTitle(mode.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Очистить диалог", role: .destructive) {
                        if let chatKey { store.db.aiChats[chatKey] = [] }
                    }
                    if store.role == .admin || store.role == .teacher {
                        Button("Настройки AI-шлюза") { showSettings = true }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showSettings) { NavigationStack { AIGatewaySettingsView() } }
    }

    private func send(_ raw: String) {
        let question = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, let chatKey else { return }
        text = ""
        var history = store.db.aiChats[chatKey] ?? []
        history.append(AIChatMessage(isUser: true, text: question))
        store.db.aiChats[chatKey] = history
        isThinking = true
        let system = AIContextBuilder.systemPrompt(mode: mode, store: store)
        let recent = Array(history.suffix(20))
        Task {
            var answer: String
            do {
                answer = try await KKSUAIService.shared.complete(system: system, messages: recent)
            } catch KKSUAIError.notConfigured {
                answer = LocalAssistant.reply(to: question, mode: mode, store: store)
            } catch {
                answer = LocalAssistant.reply(to: question, mode: mode, store: store) + "\n\n(\(error.localizedDescription) Ответ сформирован локально.)"
            }
            store.db.aiChats[chatKey, default: []].append(AIChatMessage(isUser: false, text: answer))
            store.log(chatKey, mode == .student ? "Вопрос AI-помощнику" : "Запрос AI-помощнику педагога", details: question, icon: "sparkles")
            isThinking = false
        }
    }
}

struct AIGatewaySettingsView: View {
    @ObservedObject private var ai = KKSUAIService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                SecureField("Ключ Claude API", text: $ai.apiKey)
                TextField("Адрес AI-шлюза", text: $ai.endpoint)
                    .autocorrectionDisabled()
                Button("Адрес по умолчанию") { ai.resetEndpoint() }
            } header: {
                Text("Подключение")
            } footer: {
                Text("Модель: \(KKSUAIService.model). Ключ хранится в Keychain устройства. Для продакшена рекомендуется серверный прокси KKSU: укажите его адрес и оставьте ключ пустым.")
            }
        }
        .navigationTitle("AI-шлюз")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
    }
}

// MARK: - Генерация индивидуальных заданий (задача 81)

struct AITaskGeneratorView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var studentID: UUID?
    @State private var subject = ""
    @State private var topic = ""
    @State private var difficulty = 2
    @State private var draftTitle = ""
    @State private var draftDetails = ""
    @State private var draftAlt = ""
    @State private var isGenerating = false
    @State private var status: String?

    var body: some View {
        Form {
            Section {
                Text("AI создаёт черновик задания с учётом прогресса, интересов и особых потребностей ученика. Ученик увидит задание только после проверки и утверждения педагогом.")
                    .font(.callout)
            }
            Section("Для кого") {
                Picker("Ученик", selection: $studentID) {
                    Text("Выберите").tag(UUID?.none)
                    ForEach(store.students) { Text($0.fullName).tag(UUID?.some($0.id)) }
                }
                .onChange(of: studentID) { _, id in
                    guard let id, subject.isEmpty else { return }
                    subject = ProgressAnalyzer.analyze(id, db: store.db, store: store).weakest?.subject ?? ""
                }
                TextField("Предмет", text: $subject)
                TextField("Тема", text: $topic)
                Picker("Сложность", selection: $difficulty) {
                    Text("Базовая").tag(1)
                    Text("Средняя").tag(2)
                    Text("Повышенная").tag(3)
                }
                .pickerStyle(.segmented)
                Button {
                    Task { await generate() }
                } label: {
                    HStack {
                        if isGenerating { SwiftUI.ProgressView() }
                        Label("Сгенерировать черновик", systemImage: "sparkles")
                    }
                }
                .disabled(studentID == nil || subject.isEmpty || topic.isEmpty || isGenerating)
            }
            if !draftTitle.isEmpty {
                Section("Черновик — отредактируйте перед отправкой") {
                    TextField("Название", text: $draftTitle)
                    TextField("Задание", text: $draftDetails, axis: .vertical)
                    TextField("Текстовая альтернатива", text: $draftAlt, axis: .vertical)
                }
                Section {
                    Button("Сохранить на проверку педагогу") { saveDraft(approve: false) }
                    if store.role.canTeach {
                        Button("Я проверил(а) — утвердить и отправить ученику") { saveDraft(approve: true) }
                            .fontWeight(.semibold)
                    }
                }
            }
            if let status {
                Section { Text(status).foregroundStyle(.secondary) }
            }
            Section("Ожидают проверки") {
                let pending = store.db.assignments.filter { $0.isAIGenerated && !$0.approvedByTeacher }
                if pending.isEmpty { Text("Нет черновиков").foregroundStyle(.secondary) }
                ForEach(pending) { assignment in
                    NavigationLink { AIAssignmentReviewView(assignmentID: assignment.id) } label: {
                        VStack(alignment: .leading) {
                            Text(assignment.title)
                            Text(assignment.assignedIDs.map { store.userName($0) }.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Генерация заданий AI")
    }

    private func generate() async {
        guard let studentID else { return }
        isGenerating = true
        defer { isGenerating = false }
        let profile = store.profile(for: studentID)
        let prefs = store.preferences(for: studentID)
        let prompt = """
        Составь индивидуальное задание для ученика \(profile?.grade ?? "")-го класса.
        Предмет: \(subject). Тема: \(topic). Сложность: \(difficulty) из 3.
        Интересы ученика: \((profile?.interests ?? []).joined(separator: ", ")).
        Особые образовательные потребности: \(profile?.specialNeeds ?? "нет"). \(profile?.supportNotes ?? "")
        Темп: \(prefs.pace.title.lowercased()), комфортная длительность работы: \(prefs.sessionMinutes) минут.
        Задание должно быть выполнимо за одно занятие, с пошаговыми инструкциями. textAlternative — краткое текстовое описание задания для экранного диктора.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "title": ["type": "string"],
                "details": ["type": "string"],
                "textAlternative": ["type": "string"]
            ],
            "required": ["title", "details", "textAlternative"],
            "additionalProperties": false
        ]
        do {
            let system = "Ты — методист инклюзивной школы KKSU. Составляешь индивидуальные задания; педагог обязательно проверит их перед отправкой ученику."
            let json = try await KKSUAIService.shared.complete(system: system, messages: [AIChatMessage(isUser: true, text: prompt)], jsonSchema: schema)
            if let data = json.data(using: .utf8),
               let object = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                draftTitle = object["title"] ?? ""
                draftDetails = object["details"] ?? ""
                draftAlt = object["textAlternative"] ?? ""
                status = "Черновик создан Claude. Проверьте его перед отправкой."
                return
            }
        } catch KKSUAIError.notConfigured {
            // Переходим к локальной генерации ниже.
        } catch {
            status = "\(error.localizedDescription) Использована локальная генерация."
        }
        let local = LocalAssistant.generateTask(studentID: studentID, subject: subject, topic: topic, difficulty: difficulty, store: store)
        draftTitle = local.title
        draftDetails = local.details
        draftAlt = local.textAlternative
        if status == nil { status = "Черновик создан локальным генератором. Проверьте его перед отправкой." }
    }

    private func saveDraft(approve: Bool) {
        guard let studentID else { return }
        let assignment = Assignment(title: draftTitle, subject: subject, details: draftDetails, teacherID: store.currentUser?.id,
                                    dueDate: Date().addingTimeInterval(3 * 86400), assignedIDs: [studentID],
                                    isAIGenerated: true, approvedByTeacher: false, textAlternative: draftAlt)
        store.db.assignments.append(assignment)
        if approve {
            store.approveAIAssignment(assignment.id)
            status = "Задание утверждено и отправлено ученику."
        } else {
            for teacher in store.users(with: .teacher) {
                store.notify(teacher.id, "AI подготовил задание — нужна проверка", assignment.title, kind: .ai)
            }
            status = "Черновик сохранён. Он не виден ученику до утверждения педагогом."
        }
        draftTitle = ""; draftDetails = ""; draftAlt = ""
    }
}

struct AIAssignmentReviewView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let assignmentID: UUID

    var body: some View {
        if let index = store.db.assignments.firstIndex(where: { $0.id == assignmentID }) {
            Form {
                Section {
                    Label("Сгенерировано AI. Проверьте корректность, уровень сложности и адаптацию.", systemImage: "sparkles")
                        .foregroundStyle(.purple)
                }
                Section("Задание") {
                    TextField("Название", text: $store.db.assignments[index].title)
                    TextField("Текст задания", text: $store.db.assignments[index].details, axis: .vertical)
                    TextField("Текстовая альтернатива", text: $store.db.assignments[index].textAlternative, axis: .vertical)
                    DatePicker("Срок сдачи", selection: $store.db.assignments[index].dueDate)
                    Stepper("Максимальный балл: \(store.db.assignments[index].maxScore)", value: $store.db.assignments[index].maxScore, in: 1...100)
                }
                Section("Ученик") {
                    Text(store.db.assignments[index].assignedIDs.map { store.userName($0) }.joined(separator: ", "))
                }
                if store.role.canTeach {
                    Section {
                        if store.db.assignments[index].approvedByTeacher {
                            Label("Утверждено", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                        } else {
                            Button("Утвердить и отправить ученику") {
                                store.approveAIAssignment(assignmentID)
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            Button("Отклонить черновик", role: .destructive) {
                                store.db.assignments.removeAll { $0.id == assignmentID }
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Проверка AI-задания")
        } else {
            KEmptyState(text: "Задание удалено", icon: "trash")
        }
    }
}

// MARK: - Анализ учебного прогресса (задача 82)

struct ProgressAnalysisView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Анализ прогресса") {
            if store.role.canTeach || store.role == .psychologist {
                let analyses = store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }
                KCard {
                    Text("Сводка по ученикам").font(.headline)
                    Chart(analyses) { a in
                        BarMark(x: .value("Прогресс", a.overall * 100), y: .value("Ученик", store.userName(a.studentID)))
                            .foregroundStyle(a.risk.color)
                    }
                    .chartXScale(domain: 0...100)
                    .frame(height: CGFloat(max(analyses.count, 1)) * 44)
                }
            }
            StudentScoped { studentID in
                let analysis = ProgressAnalyzer.analyze(studentID, db: store.db, store: store)
                ProgressDashboardContent(studentID: studentID)
                KCard {
                    Text("Динамика по предметам").font(.headline)
                    ForEach(analysis.subjects) { stat in
                        HStack {
                            Text(stat.subject)
                            Spacer()
                            Text("\(Int(stat.average * 100))%").bold()
                            Label(String(format: "%+.0f%%", stat.trend * 100), systemImage: stat.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundStyle(stat.trend >= 0 ? KKSUTheme.success : KKSUTheme.danger)
                            Text("(\(stat.count))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                let insights = TeacherInsightEngine.insights(for: [analysis], store: store)
                if !insights.isEmpty {
                    KSectionHeader(title: "Выводы", icon: "lightbulb.fill")
                    ForEach(insights) { InsightCard(insight: $0) }
                }
            }
        }
    }
}

// MARK: - Рекомендации преподавателю (задача 83)

struct TeacherRecommendationsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var priority: RiskLevel?

    var body: some View {
        let analyses = store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }
        let insights = TeacherInsightEngine.insights(for: analyses, store: store).filter { priority == nil || $0.priority == priority }
        KPage("Рекомендации педагогу") {
            Text("Рекомендации формируются автоматически по оценкам, тестам, посещаемости, дедлайнам и профилю ученика.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                FilterChip(title: "Все", selected: priority == nil) { priority = nil }
                FilterChip(title: "Срочно", selected: priority == .high) { priority = .high }
                FilterChip(title: "Внимание", selected: priority == .medium) { priority = .medium }
                FilterChip(title: "Идеи", selected: priority == .low) { priority = .low }
            }
            if insights.isEmpty { KEmptyState(text: "Нет рекомендаций", icon: "checkmark.circle") }
            ForEach(insights) { insight in
                VStack(alignment: .leading, spacing: 6) {
                    InsightCard(insight: insight)
                    HStack {
                        NavigationLink { StudentOverviewView(studentID: insight.studentID) } label: { Label("Ученик", systemImage: "person") }
                        NavigationLink { ChatThreadView(otherID: insight.studentID) } label: { Label("Написать", systemImage: "bubble.left") }
                        NavigationLink(value: KKSURoute.aiTaskGenerator) { Label("AI-задание", systemImage: "sparkles") }
                    }
                    .font(.caption)
                }
            }
        }
    }
}
