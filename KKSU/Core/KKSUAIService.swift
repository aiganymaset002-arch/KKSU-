//
//  KKSUAIService.swift
//  KKSU Online
//
//  AI-шлюз платформы (задачи 68, 79–81).
//  Работает через Claude API (Messages API, raw HTTP — официального Swift SDK нет).
//  Если ключ не задан или сеть недоступна — отвечает локальный AI-режим на правилах.
//
//  ВАЖНО для продакшена: не храните ключ API в клиентском приложении. Разверните
//  серверный прокси KKSU и укажите его адрес в настройках (поле «Адрес AI-шлюза»);
//  прокси добавит ключ на своей стороне.
//

import Foundation
import Security

// MARK: - Keychain

enum KKSUKeychain {
    private static let service = "kz.kksu.online.ai"

    static func save(_ value: String, account: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty else { return }
        var item = base
        item[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }

    static func read(account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - AI-сервис

enum KKSUAIError: LocalizedError {
    case notConfigured, http(Int, String), refusal, emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "AI-шлюз не настроен."
        case .http(let code, let message): return "Ошибка AI-сервиса (\(code)): \(message)"
        case .refusal: return "AI не может ответить на этот запрос. Переформулируйте вопрос или обратитесь к педагогу."
        case .emptyResponse: return "AI вернул пустой ответ."
        }
    }
}

@MainActor
final class KKSUAIService: ObservableObject {
    static let shared = KKSUAIService()

    static let model = "claude-opus-5"
    private static let defaultEndpoint = "https://api.anthropic.com/v1/messages"

    @Published var apiKey: String {
        didSet { KKSUKeychain.save(apiKey, account: "anthropic-api-key") }
    }
    @Published var endpoint: String {
        didSet { UserDefaults.standard.set(endpoint, forKey: "kksu.ai.endpoint") }
    }

    var isConfigured: Bool { !apiKey.isEmpty || endpoint != Self.defaultEndpoint }

    private init() {
        apiKey = KKSUKeychain.read(account: "anthropic-api-key") ?? ""
        endpoint = UserDefaults.standard.string(forKey: "kksu.ai.endpoint") ?? Self.defaultEndpoint
    }

    func resetEndpoint() { endpoint = Self.defaultEndpoint }

    /// Запрос к Claude. `jsonSchema` включает структурированный вывод (ответ — JSON по схеме).
    func complete(system: String, messages: [AIChatMessage], jsonSchema: [String: Any]? = nil, effort: String = "medium") async throws -> String {
        guard isConfigured, let url = URL(string: endpoint) else { throw KKSUAIError.notConfigured }

        var body: [String: Any] = [
            "model": Self.model,
            "max_tokens": 16000,
            "system": system,
            "thinking": ["type": "adaptive"],
            "fallbacks": "default",
            "messages": messages.map { ["role": $0.isUser ? "user" : "assistant", "content": $0.text] }
        ]
        var outputConfig: [String: Any] = ["effort": effort]
        if let jsonSchema {
            outputConfig["format"] = ["type": "json_schema", "schema": jsonSchema]
        }
        body["output_config"] = outputConfig

        var request = URLRequest(url: url, timeoutInterval: 180)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        if !apiKey.isEmpty { request.setValue(apiKey, forHTTPHeaderField: "x-api-key") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (200..<300).contains(status) else {
            let message = (json["error"] as? [String: Any])?["message"] as? String ?? String(data: data, encoding: .utf8) ?? ""
            throw KKSUAIError.http(status, message)
        }
        if json["stop_reason"] as? String == "refusal" { throw KKSUAIError.refusal }
        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks.filter { $0["type"] as? String == "text" }.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw KKSUAIError.emptyResponse }
        return text
    }
}

// MARK: - Контекст и промпты

enum AIAssistantMode: String {
    case student, teacher

    var title: String { self == .student ? "AI-помощник KKSU" : "AI-помощник педагога" }

    var suggestions: [String] {
        switch self {
        case .student:
            return ["Какие у меня дедлайны?", "Объясни дроби простыми словами", "Как мой прогресс?", "Что мне повторить?", "Помоги спланировать неделю"]
        case .teacher:
            return ["Составь план урока по дробям", "Как адаптировать урок для ученика с нарушением слуха?", "Кто из учеников требует внимания?", "Напиши отзыв на работу ученика", "Идеи для проектного урока"]
        }
    }
}

@MainActor
enum AIContextBuilder {
    static func systemPrompt(mode: AIAssistantMode, store: KKSUStore) -> String {
        let user = store.currentUser
        var lines: [String] = []
        switch mode {
        case .student:
            lines.append("Ты — AI-помощник образовательной платформы KKSU Online (Comfort School-University). Твой собеседник — школьник, возможно с особыми образовательными потребностями.")
            lines.append("Объясняй простыми словами и короткими шагами, используй примеры из жизни. Не выполняй домашние задания за ученика целиком: подсказывай ход решения и задавай наводящие вопросы. Поддерживай и хвали за усилия.")
            lines.append("Если вопрос касается здоровья, безопасности или личных трудностей — мягко посоветуй обратиться к педагогу, психологу или родителям.")
            lines.append("Отвечай на языке ученика (по умолчанию — русский).")
            if let id = user?.id {
                let analysis = ProgressAnalyzer.analyze(id, db: store.db, store: store)
                let profile = store.profile(for: id)
                lines.append("Контекст ученика: имя — \(user?.firstName ?? ""), класс — \(profile?.grade ?? "—"), интересы — \((profile?.interests ?? []).joined(separator: ", ")).")
                if let needs = profile?.specialNeeds, !needs.isEmpty { lines.append("Особые потребности: \(needs). \(profile?.supportNotes ?? "")") }
                lines.append("Успеваемость: " + analysis.subjects.map { "\($0.subject) \(Int($0.average * 100))%" }.joined(separator: ", ") + ".")
                let deadlines = store.assignments(for: id).filter { $0.dueDate > Date() && store.submission(for: $0.id, studentID: id) == nil }
                lines.append("Ближайшие задания: " + deadlines.prefix(5).map { "\($0.title) (\($0.subject), до \($0.dueDate.kksuShort))" }.joined(separator: "; ") + ".")
                let prefs = store.preferences(for: id)
                lines.append("Темп обучения: \(prefs.pace.title.lowercased()), удобная длительность занятия: \(prefs.sessionMinutes) мин.")
            }
        case .teacher:
            lines.append("Ты — AI-помощник педагога платформы KKSU Online: инклюзивная школа, проектное обучение, изобретательство и инженерия.")
            lines.append("Помогаешь планировать уроки, адаптировать материалы для учеников с ООП, составлять задания, тесты и обратную связь. Давай конкретные, практичные ответы со структурой.")
            lines.append("Любые сгенерированные задания педагог обязан проверить перед отправкой ученику — напоминай об этом, когда предлагаешь задания.")
            let analyses = store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }
            let summary = analyses.map { a in
                "\(store.userName(a.studentID)): прогресс \(Int(a.overall * 100))%, статус «\(a.risk.title)», просрочено \(a.overdue.count)" +
                (store.profile(for: a.studentID)?.specialNeeds.isEmpty == false ? ", ООП: \(store.profile(for: a.studentID)?.specialNeeds ?? "")" : "")
            }
            lines.append("Данные учеников (обезличивай их в материалах для других людей): " + summary.joined(separator: "; ") + ".")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Локальный AI-режим (без сети)

@MainActor
enum LocalAssistant {
    static func reply(to text: String, mode: AIAssistantMode, store: KKSUStore) -> String {
        let q = text.lowercased()
        guard let user = store.currentUser else { return "Войдите в аккаунт, чтобы я мог помочь." }

        if mode == .student {
            let analysis = ProgressAnalyzer.analyze(user.id, db: store.db, store: store)
            if q.contains("дедлайн") || q.contains("задани") || q.contains("сдать") {
                let pending = store.assignments(for: user.id).filter { store.submission(for: $0.id, studentID: user.id) == nil }
                if pending.isEmpty { return "У тебя нет несданных заданий. Отличная работа! 🎉" }
                return "Вот что нужно сделать:\n" + pending.prefix(5).map { "• \($0.title) (\($0.subject)) — до \($0.dueDate.kksuDateTime)" }.joined(separator: "\n") +
                    "\n\nСовет: начни с ближайшего задания и раздели его на маленькие шаги по \(store.preferences(for: user.id).sessionMinutes) минут."
            }
            if q.contains("прогресс") || q.contains("успева") || q.contains("оценк") {
                var answer = "Твой общий прогресс — \(Int(analysis.overall * 100))%. "
                if let strong = analysis.strongest { answer += "Лучше всего получается «\(strong.subject)» (\(Int(strong.average * 100))%). " }
                if let weak = analysis.weakest, analysis.subjects.count > 1 { answer += "Больше внимания стоит уделить «\(weak.subject)». " }
                return answer + "Продолжай в том же духе!"
            }
            if q.contains("повтор") || q.contains("рекоменд") || q.contains("что учить") {
                let recs = RecommendationEngine.recommendations(for: user.id, store: store).prefix(3)
                if recs.isEmpty { return "Загляни в библиотеку видеоуроков — там много интересного!" }
                return "Рекомендую:\n" + recs.map { "• \($0.title) — \($0.reason.lowercased())" }.joined(separator: "\n")
            }
            if q.contains("распис") || q.contains("недел") || q.contains("план") {
                let sessions = store.db.sessions.filter { $0.participantIDs.contains(user.id) && $0.start > Date() }.sorted { $0.start < $1.start }.prefix(5)
                return "Ближайшие занятия:\n" + sessions.map { "• \($0.start.kksuDateTime) — \($0.subject): \($0.title)" }.joined(separator: "\n") +
                    "\n\nПланируй по 1–2 задания в день и делай перерывы каждые \(store.preferences(for: user.id).sessionMinutes) минут."
            }
            if let item = store.db.library.first(where: { item in
                !item.textAlternative.isEmpty && q.split(separator: " ").contains { word in word.count > 3 && item.title.lowercased().contains(word.prefix(5)) }
            }) {
                return "Вот простое объяснение из урока «\(item.title)»:\n\n\(item.textAlternative)\n\nХочешь, разберём пример вместе? Напиши, что именно непонятно."
            }
            return "Я локальный помощник KKSU и лучше всего подскажу про задания, дедлайны, расписание и прогресс. Попробуй спросить: «Какие у меня дедлайны?» или «Объясни дроби». Для полноценных ответов педагог или администратор может подключить AI-шлюз."
        }

        // Режим педагога
        if q.contains("план урока") || q.contains("урок") && q.contains("план") {
            let topic = text.components(separatedBy: " по ").last ?? "теме"
            return """
            План урока по \(topic) (45 мин):
            1. Мотивация (5 мин): жизненная ситуация, вопрос классу.
            2. Актуализация (5 мин): короткий опрос, визуальная опора на доске.
            3. Новый материал (15 мин): объяснение с наглядностью; письменные инструкции и субтитры к видео для учеников с нарушением слуха.
            4. Практика в парах (12 мин): 3 задания разного уровня сложности.
            5. Рефлексия (5 мин): «светофор» понимания.
            6. Домашнее задание (3 мин): выбор из двух вариантов.
            Не забудьте проверить материалы перед отправкой ученикам.
            """
        }
        if q.contains("адапт") || q.contains("слух") || q.contains("оуп") || q.contains("ооп") {
            return """
            Рекомендации по адаптации:
            • Дублируйте устные инструкции письменно; используйте субтитры (включены в библиотеке видео).
            • Добавляйте текстовые альтернативы к изображениям и схемам.
            • Делите задания на короткие шаги, давайте больше времени.
            • Используйте визуальные опоры и проверку понимания после каждого шага.
            • Согласуйте индивидуальный учебный план с психологом и родителями.
            """
        }
        if q.contains("внимани") || q.contains("риск") || q.contains("кто") {
            let insights = TeacherInsightEngine.insights(for: store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }, store: store)
            return insights.isEmpty ? "Все ученики стабильны." : insights.prefix(5).map { "• \($0.title)\n  → \($0.action)" }.joined(separator: "\n")
        }
        if q.contains("отзыв") || q.contains("обратн") {
            return "Шаблон отзыва: «[Имя], ты хорошо справился с [сильная сторона]. Обрати внимание на [зона роста]: попробуй [конкретный шаг]. Я уверен, у тебя получится!» — Конкретная похвала + одна зона роста + следующий шаг."
        }
        if q.contains("проект") {
            return "Идеи для проектного урока: 1) «Умный дом для бабушки» — датчики и доступность; 2) «Школа без барьеров» — аудит доступности здания; 3) «Эко-сортировщик» — AI-распознавание мусора. Используйте стадии Idea → Research → Prototype → Testing → Result в KKSU Inventions."
        }
        return "Я локальный помощник педагога: помогу с планом урока, адаптацией для учеников с ООП, списком учеников, требующих внимания, шаблонами отзывов и идеями проектов. Для развёрнутых ответов подключите AI-шлюз в настройках."
    }

    /// Шаблонная генерация индивидуального задания без сети (задача 81).
    static func generateTask(studentID: UUID, subject: String, topic: String, difficulty: Int, store: KKSUStore) -> (title: String, details: String, textAlternative: String) {
        let profile = store.profile(for: studentID)
        let interest = profile?.interests.first ?? "повседневной жизни"
        let prefs = store.preferences(for: studentID)
        let levels = ["базовый", "средний", "повышенный"]
        let level = levels[min(max(difficulty - 1, 0), 2)]
        let steps = prefs.pace == .gentle ? 3 : (difficulty >= 3 ? 6 : 4)
        var details = "Тема: \(topic). Уровень: \(level).\n"
        details += "Ситуация: представь, что ты работаешь над проектом, связанным с темой «\(interest)». Тебе нужно применить знания по теме «\(topic)».\n\n"
        details += "Выполни \(steps) шага(ов):\n"
        for step in 1...steps {
            details += "\(step). " + (step == 1 ? "Прочитай условие и выпиши, что известно." :
                                     step == steps ? "Проверь ответ и запиши вывод одним предложением." :
                                     "Реши подзадачу \(step - 1) и запиши решение по шагам.") + "\n"
        }
        if let needs = profile?.specialNeeds, !needs.isEmpty {
            details += "\nАдаптация: инструкции даны письменно, можно выполнять с перерывами каждые \(prefs.sessionMinutes) минут."
        }
        let alt = "Задание по предмету «\(subject)», тема «\(topic)», \(steps) шагов: прочитать условие, решить подзадачи, проверить ответ."
        return ("\(subject): \(topic) — индивидуальное задание", details, alt)
    }
}
