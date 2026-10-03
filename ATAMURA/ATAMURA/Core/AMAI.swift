//
//  AMAI.swift
//  ATA MURA
//
//  AI ATA MURA: помощник изобретателя, «Объяснить простым языком»,
//  идеи для роликов и план выпуска влога.
//  Работает через Claude API (Messages API, raw HTTP — официального Swift SDK нет).
//  Без ключа или без сети отвечает встроенный локальный режим на правилах.
//
//  Для продакшена не храните ключ API в приложении: разверните свой прокси
//  и укажите его адрес в настройках AI — прокси добавит ключ на сервере.
//

import Foundation

enum AMAIError: LocalizedError {
    case notConfigured, http(Int, String), refusal, emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return L("ai.error.notConfigured")
        case .http(let code, let message): return L("ai.error.http", code, message)
        case .refusal: return L("ai.error.refusal")
        case .emptyResponse: return L("ai.error.empty")
        }
    }
}

@MainActor
final class AMAI: ObservableObject {
    static let shared = AMAI()

    static let model = "claude-opus-5-5"
    static let defaultEndpoint = "https://api.anthropic.com/v1/messages"

    @Published var apiKey: String {
        didSet { AMKeychain.save(apiKey, account: "anthropic-api-key") }
    }
    @Published var endpoint: String {
        didSet { UserDefaults.standard.set(endpoint, forKey: "atamura.ai.endpoint") }
    }

    var isConfigured: Bool { !apiKey.isEmpty || endpoint != Self.defaultEndpoint }

    private init() {
        apiKey = AMKeychain.read(account: "anthropic-api-key") ?? ""
        endpoint = UserDefaults.standard.string(forKey: "atamura.ai.endpoint") ?? Self.defaultEndpoint
    }

    private var languageInstruction: String {
        switch AMLanguage.current {
        case .ru: return "Отвечай на русском языке."
        case .en: return "Answer in English."
        case .kk: return "Қазақ тілінде жауап бер."
        }
    }

    /// Запрос к Claude. `schema` включает структурированный вывод (ответ — JSON по схеме).
    func complete(system: String, messages: [(isUser: Bool, text: String)], schema: [String: Any]? = nil,
                  effort: String = "medium") async throws -> String {
        guard isConfigured, let url = URL(string: endpoint) else { throw AMAIError.notConfigured }
        var outputConfig: [String: Any] = ["effort": effort]
        if let schema { outputConfig["format"] = ["type": "json_schema", "schema": schema] }
        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": 16000,
            "system": system + "\n" + languageInstruction,
            "thinking": ["type": "adaptive"],
            "output_config": outputConfig,
            // Если запрос отклонён фильтром безопасности, сервер сам повторит его на запасной модели.
            "fallbacks": "default",
            "messages": messages.map { ["role": $0.isUser ? "user" : "assistant", "content": $0.text] }
        ]
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
            throw AMAIError.http(status, message)
        }
        if json["stop_reason"] as? String == "refusal" { throw AMAIError.refusal }
        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks.filter { $0["type"] as? String == "text" }.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw AMAIError.emptyResponse }
        return text
    }

    // MARK: - Помощник изобретателя

    private static let inventorSystem = """
    Ты — AI ATA MURA, наставник юных изобретателей Казахстана на платформе ATA MURA \
    («Heritage creates innovation»). Пользователи — школьники и студенты. Помогай превратить идею в проект: \
    определи проблему, предложи возможное решение, что изучить (конкретные компоненты, платы, темы), \
    первый простой и безопасный прототип и шаги. Пиши дружелюбно, коротко и конкретно, без опасных экспериментов. \
    Если вопрос про историю или культуру Казахстана — отвечай точно и предлагай проверить источники.
    """

    private static let draftSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "reply": ["type": "string", "description": "Ответ пользователю: проблема, решение, что изучить, первый прототип"],
            "is_invention": ["type": "boolean", "description": "Есть ли в сообщении идея устройства или проекта"],
            "title": ["type": "string"],
            "problem": ["type": "string"],
            "solution": ["type": "string"],
            "what_to_learn": ["type": "string"],
            "first_prototype": ["type": "string"],
            "direction": ["type": "string", "enum": AMDirection.allCases.map(\.rawValue)],
            "help_needed": ["type": "array", "items": ["type": "string"]]
        ],
        "required": ["reply", "is_invention", "title", "problem", "solution", "what_to_learn", "first_prototype", "direction", "help_needed"],
        "additionalProperties": false
    ]

    /// Ответ помощника и (если это идея устройства) черновик карточки проекта.
    func inventorReply(history: [AMChatMessage]) async -> AMChatMessage {
        let question = history.last(where: \.isUser)?.text ?? ""
        if isConfigured {
            do {
                let text = try await complete(system: Self.inventorSystem,
                                              messages: history.suffix(12).map { (isUser: $0.isUser, text: $0.text) },
                                              schema: Self.draftSchema)
                if let data = text.data(using: .utf8),
                   let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let reply = object["reply"] as? String ?? ""
                    var draft: AMProjectDraft?
                    if object["is_invention"] as? Bool == true {
                        draft = AMProjectDraft(title: object["title"] as? String ?? "",
                                               problem: object["problem"] as? String ?? "",
                                               solution: object["solution"] as? String ?? "",
                                               whatToLearn: object["what_to_learn"] as? String ?? "",
                                               firstPrototype: object["first_prototype"] as? String ?? "",
                                               direction: AMDirection(rawValue: object["direction"] as? String ?? "") ?? .other,
                                               helpNeeded: object["help_needed"] as? [String] ?? [])
                    }
                    return AMChatMessage(isUser: false, text: reply, projectDraft: draft)
                }
            } catch {
                let local = AMLocalAI.inventor(question)
                return AMChatMessage(isUser: false, text: local.text + "\n\n(\(error.localizedDescription))", projectDraft: local.draft)
            }
        }
        let local = AMLocalAI.inventor(question)
        return AMChatMessage(isUser: false, text: local.text, projectDraft: local.draft)
    }

    // MARK: - Easy Language

    func explainSimply(_ text: String) async -> String {
        if isConfigured {
            let system = "Перескажи текст для ребёнка 10 лет: короткие предложения, простые слова, объясни сложные термины, сохрани факты и даты. Не добавляй ничего от себя."
            if let answer = try? await complete(system: system, messages: [(isUser: true, text: text)], effort: "low") { return answer }
        }
        return AMLocalAI.simplify(text)
    }

    // MARK: - Creator Studio

    func ideaSuggestions(for idea: String) async -> String {
        if isConfigured {
            let system = """
            Ты — продюсер медиа ATA MURA (YouTube, Shorts, TikTok, Instagram, LinkedIn) о наследии, истории, \
            изобретателях и инклюзивной инженерии Казахстана. По идее ролика дай: 10 вариантов названий; \
            структуру ролика (хук первых 5 секунд → блоки → финал с призывом); 8 вопросов для интервью; \
            3 идеи Shorts, которые можно нарезать из длинного видео. Используй короткие списки.
            """
            if let answer = try? await complete(system: system, messages: [(isUser: true, text: idea)]) { return answer }
        }
        return AMLocalAI.ideaPack(idea)
    }

    func vlogEpisodePlan(_ entries: [AMVlogEntry]) async -> String {
        let notes = entries.sorted { $0.date < $1.date }.map { entry in
            "\(entry.date.amDate): \(entry.happened). Встречи: \(entry.meetings). Сняли: \(entry.filmed). Цитата: \(entry.quote). Показать: \(entry.forAudience)"
        }.joined(separator: "\n")
        if isConfigured {
            let system = "Ты — редактор влога ATA MURA. Из дневника недели собери план выпуска: название, хук, 4–6 сюжетных блоков по порядку (что показать, какие кадры, цитаты), финал и анонс следующей недели."
            if let answer = try? await complete(system: system, messages: [(isUser: true, text: notes)]) { return answer }
        }
        return AMLocalAI.vlogPlan(entries)
    }
}

// MARK: - Локальный AI-режим (без сети)

enum AMLocalAI {
    private struct Rule {
        let keywords: [String]
        let problem: String
        let solution: String
        let learn: String
        let prototype: String
        let direction: AMDirection
        let help: [String]
    }

    private static var rules: [Rule] { [
        Rule(keywords: ["слыш", "глух", "музык", "hearing", "deaf", "music", "есту", "саңырау", "музыка"],
             problem: L("localai.hearing.problem"), solution: L("localai.hearing.solution"),
             learn: "ESP32, вибромоторы (ERM/LRA), FFT — частотный анализ, микрофон INMP441",
             prototype: L("localai.hearing.prototype"), direction: .inclusiveEngineering, help: ["ESP32", "3D printing"]),
        Rule(keywords: ["слеп", "зрен", "незряч", "blind", "vision", "көз", "соқыр"],
             problem: L("localai.vision.problem"), solution: L("localai.vision.solution"),
             learn: "Arduino, ультразвуковой датчик HC-SR04, вибромотор, пьезоизлучатель",
             prototype: L("localai.vision.prototype"), direction: .inclusiveEngineering, help: ["Arduino"]),
        Rule(keywords: ["коляск", "wheelchair", "пандус", "арбақ", "мүгедек"],
             problem: L("localai.mobility.problem"), solution: L("localai.mobility.solution"),
             learn: "Механика рычагов, Arduino, сервоприводы, датчики наклона (MPU-6050)",
             prototype: L("localai.mobility.prototype"), direction: .inclusiveEngineering, help: ["Arduino", "3D printing"]),
        Rule(keywords: ["домбр", "dombra", "кобыз", "қобыз", "музыкальн инструмент"],
             problem: L("localai.dombra.problem"), solution: L("localai.dombra.solution"),
             learn: "Пьезодатчики, ESP32, MIDI, светодиодная лента WS2812",
             prototype: L("localai.dombra.prototype"), direction: .heritageTech, help: ["Arduino", "3D printing"]),
        Rule(keywords: ["вод", "water", "су ", "полив", "засух", "арал"],
             problem: L("localai.water.problem"), solution: L("localai.water.solution"),
             learn: "Датчик влажности почвы, реле, насос 5 В, солнечная панель",
             prototype: L("localai.water.prototype"), direction: .ecology, help: ["Arduino"]),
        Rule(keywords: ["энерг", "солн", "ветр", "energy", "solar", "wind", "күн", "жел"],
             problem: L("localai.energy.problem"), solution: L("localai.energy.solution"),
             learn: "Солнечные панели, контроллер заряда, литиевые аккумуляторы, мультиметр",
             prototype: L("localai.energy.prototype"), direction: .energy, help: ["Электроника"])
    ] }

    static func inventor(_ question: String) -> (text: String, draft: AMProjectDraft?) {
        let lower = question.lowercased()
        guard let rule = rules.first(where: { rule in rule.keywords.contains { lower.contains($0) } }) else {
            let generic = L("localai.generic")
            let draft = question.count > 25 ? AMProjectDraft(title: String(question.prefix(60)), problem: question,
                                                            solution: L("localai.generic.solution"),
                                                            whatToLearn: "Arduino / ESP32, 3D-моделирование (Tinkercad), основы электроники",
                                                            firstPrototype: L("localai.generic.prototype"),
                                                            direction: .other, helpNeeded: ["Arduino"]) : nil
            return (generic, draft)
        }
        let text = """
        \(L("ai.field.problem")): \(rule.problem)
        \(L("ai.field.solution")): \(rule.solution)
        \(L("ai.field.learn")): \(rule.learn)
        \(L("ai.field.prototype")): \(rule.prototype)

        \(L("localai.next"))
        """
        let title = String(question.prefix(60))
        return (text, AMProjectDraft(title: title, problem: rule.problem, solution: rule.solution, whatToLearn: rule.learn,
                                     firstPrototype: rule.prototype, direction: rule.direction, helpNeeded: rule.help))
    }

    /// Упрощение текста: короткие предложения, первые ключевые мысли.
    static func simplify(_ text: String) -> String {
        let sentences = text.replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let short = sentences.prefix(6).map { sentence -> String in
            let parts = sentence.components(separatedBy: CharacterSet(charactersIn: ",;:—"))
            let first = parts.first?.trimmingCharacters(in: .whitespaces) ?? sentence
            return "• " + (first.count > 20 ? first : sentence) + "."
        }
        return L("localai.simple.header") + "\n\n" + short.joined(separator: "\n")
    }

    static func ideaPack(_ idea: String) -> String {
        let topic = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        let titles = [
            "\(topic): история, которую не рассказывали",
            "Как \(topic.lowercased()) изменило Казахстан",
            "\(topic) за 1 минуту",
            "Забытые герои: \(topic.lowercased())",
            "\(topic) глазами детей",
            "Что бы сделал инженер сегодня? \(topic)",
            "\(topic): факты, мифы и архивы",
            "Мы нашли архив: \(topic.lowercased())",
            "\(topic) — от прошлого к будущему",
            "ATA MURA Expedition: \(topic.lowercased())"
        ]
        return """
        \(L("localai.idea.titles"))
        \(titles.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))

        \(L("localai.idea.structure"))
        1. \(L("localai.idea.s1"))
        2. \(L("localai.idea.s2"))
        3. \(L("localai.idea.s3"))
        4. \(L("localai.idea.s4"))
        5. \(L("localai.idea.s5"))

        \(L("localai.idea.questions"))
        \(L("localai.idea.q"))

        \(L("localai.idea.shorts"))
        \(L("localai.idea.shortsList"))
        """
    }

    static func vlogPlan(_ entries: [AMVlogEntry]) -> String {
        guard !entries.isEmpty else { return L("vlog.empty") }
        let sorted = entries.sorted { $0.date < $1.date }
        var lines = [L("localai.vlog.title"), "", L("localai.vlog.hook") + ": " + (sorted.first { !$0.quote.isEmpty }?.quote ?? sorted[0].happened), ""]
        for (index, entry) in sorted.enumerated() {
            var block = "\(index + 1). \(entry.date.amDate) — \(entry.happened)"
            if !entry.meetings.isEmpty { block += "\n   \(L("vlog.meetings")): \(entry.meetings)" }
            if !entry.filmed.isEmpty { block += "\n   \(L("vlog.filmed")): \(entry.filmed)" }
            if !entry.forAudience.isEmpty { block += "\n   \(L("vlog.forAudience")): \(entry.forAudience)" }
            lines.append(block)
        }
        lines.append("")
        lines.append(L("localai.vlog.final"))
        return lines.joined(separator: "\n")
    }
}
