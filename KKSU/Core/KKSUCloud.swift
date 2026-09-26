//
//  KKSUCloud.swift
//  KKSU Online
//
//  Сервер KKSU на Supabase (https://supabase.com): общие аккаунты и синхронизация
//  данных между устройствами учеников, родителей, педагогов и администраторов.
//
//  Работает через REST API Supabase (Auth + PostgREST) без сторонних библиотек.
//  Схема базы и правила доступа — backend/supabase/schema.sql, инструкция — backend/README.md.
//
//  Пока адрес и ключ проекта не заданы, приложение работает локально (демо-режим).
//

import Foundation
import CryptoKit

/// Параметры проекта Supabase. Заполните после создания проекта (Settings → API)
/// или введите в приложении: «Модули → Сервер KKSU».
/// anon-ключ публичный по замыслу Supabase: доступ к данным ограничивают правила RLS в базе.
enum KKSUCloudDefaults {
    static let projectURL = "https://vllechyeunbtozhubuud.supabase.co"
    /// Публичный (publishable/anon) ключ. Секретный ключ service_role в приложение не добавлять никогда.
    static let anonKey = "sb_publishable_ThNRdPI2yoG1rQxLAiwusg_CmxF8Y7Y"
    static let schoolID = "kksu"
}

struct CloudSession: Codable {
    var accessToken: String
    var refreshToken: String
    var userID: UUID
    var email: String
    var expiresAt: Date
}

struct CloudMember: Codable, Identifiable {
    var id: UUID { user_id }
    let user_id: UUID
    let school_id: String
    let role: String
    let full_name: String
    let approved: Bool
    let blocked: Bool

    var kksuRole: KKSURole { KKSURole(rawValue: role) ?? .student }
}

enum CloudSyncStatus: Equatable {
    case localOnly, signedOut, syncing, synced(Date), failed(String)

    var title: String {
        switch self {
        case .localOnly: return "Локальный режим (сервер не подключён)"
        case .signedOut: return "Сервер подключён, вход не выполнен"
        case .syncing: return "Синхронизация…"
        case .synced(let date): return "Синхронизировано \(date.kksuTime)"
        case .failed(let message): return "Ошибка синхронизации: \(message)"
        }
    }
}

enum KKSUCloudError: LocalizedError {
    case notConfigured, http(Int, String), emailConfirmation, pendingApproval, blocked, noSession, wrongRole(KKSURole)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Сервер KKSU не настроен."
        case .http(let code, let message): return message.isEmpty ? "Ошибка сервера (\(code))." : message
        case .emailConfirmation: return "Мы отправили письмо для подтверждения email. Подтвердите адрес и войдите."
        case .pendingApproval: return "Аккаунт сотрудника ожидает подтверждения администратором KKSU."
        case .blocked: return "Аккаунт заблокирован. Обратитесь к администратору."
        case .noSession: return "Войдите в аккаунт."
        case .wrongRole(let role): return "Этот аккаунт зарегистрирован с ролью «\(role.title)». Выберите её."
        }
    }
}

@MainActor
final class KKSUCloud: ObservableObject {
    static let shared = KKSUCloud()

    @Published var projectURL: String {
        didSet { UserDefaults.standard.set(projectURL, forKey: "kksu.cloud.url") }
    }
    @Published var anonKey: String {
        didSet { UserDefaults.standard.set(anonKey, forKey: "kksu.cloud.key") }
    }
    @Published var schoolID: String {
        didSet { UserDefaults.standard.set(schoolID, forKey: "kksu.cloud.school") }
    }
    @Published private(set) var session: CloudSession? {
        didSet { saveSession() }
    }
    @Published private(set) var status: CloudSyncStatus = .localOnly
    @Published private(set) var members: [CloudMember] = []

    weak var store: KKSUStore?
    private var syncTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var isSyncing = false
    private var needsAnotherSync = false

    /// Хэши последних отправленных/полученных версий записей: "коллекция/id" → хэш.
    private var knownHashes: [String: String] {
        didSet { UserDefaults.standard.set(knownHashes, forKey: "kksu.cloud.hashes") }
    }
    /// Записи, которые сервер отклонил правилами доступа (не отправляем повторно, пока не изменятся).
    private var rejectedHashes: [String: String] = [:]
    private var lastPull: String? {
        didSet { UserDefaults.standard.set(lastPull, forKey: "kksu.cloud.lastPull") }
    }

    var isConfigured: Bool { !projectURL.trimmingCharacters(in: .whitespaces).isEmpty && !anonKey.isEmpty }
    var isSignedIn: Bool { isConfigured && session != nil }

    private init() {
        let defaults = UserDefaults.standard
        // Пустые значения из настроек не перекрывают параметры проекта по умолчанию.
        func stored(_ key: String) -> String? { defaults.string(forKey: key).flatMap { $0.isEmpty ? nil : $0 } }
        projectURL = stored("kksu.cloud.url") ?? KKSUCloudDefaults.projectURL
        anonKey = stored("kksu.cloud.key") ?? KKSUCloudDefaults.anonKey
        schoolID = stored("kksu.cloud.school") ?? KKSUCloudDefaults.schoolID
        knownHashes = defaults.dictionary(forKey: "kksu.cloud.hashes") as? [String: String] ?? [:]
        lastPull = defaults.string(forKey: "kksu.cloud.lastPull")
        if let data = KKSUKeychain.read(account: "cloud-session")?.data(using: .utf8) {
            session = try? JSONDecoder.kksu.decode(CloudSession.self, from: data)
        }
        status = isConfigured ? (session == nil ? .signedOut : .synced(Date())) : .localOnly
    }

    private func saveSession() {
        if let session, let data = try? JSONEncoder.kksu.encode(session), let text = String(data: data, encoding: .utf8) {
            KKSUKeychain.save(text, account: "cloud-session")
        } else {
            KKSUKeychain.save("", account: "cloud-session")
        }
    }

    func start(with store: KKSUStore) {
        self.store = store
        guard isSignedIn else { return }
        startPolling()
        scheduleSync(delay: 0.5)
    }

    // MARK: - HTTP

    private var baseURL: String {
        var url = projectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while url.hasSuffix("/") { url.removeLast() }
        return url
    }

    private func request(_ path: String, method: String = "GET", json: Any? = nil,
                         authorized: Bool = true, headers: [String: String] = [:]) async throws -> Data {
        guard isConfigured, let url = URL(string: baseURL + path) else { throw KKSUCloudError.notConfigured }
        if authorized { try await refreshIfNeeded() }
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        // Токен пользователя передаём только после входа. Новые ключи sb_publishable_ — не JWT,
        // поэтому без сессии достаточно заголовка apikey.
        if authorized, let token = session?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let json { request.httpBody = try JSONSerialization.data(withJSONObject: json) }
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let message = (object?["error_description"] ?? object?["msg"] ?? object?["message"] ?? object?["error"]) as? String ?? ""
            throw KKSUCloudError.http(code, Self.translate(message))
        }
        return data
    }

    private static func translate(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("invalid login credentials") { return "Неверный email или пароль." }
        if lower.contains("already registered") { return "Пользователь с таким email уже зарегистрирован." }
        if lower.contains("email not confirmed") { return "Подтвердите email по ссылке из письма." }
        if lower.contains("password should be") { return "Пароль слишком простой: минимум 8 символов." }
        if lower.contains("token has expired") || lower.contains("otp") { return "Код неверный или устарел." }
        if lower.contains("row-level security") { return "Недостаточно прав для этого действия." }
        return message
    }

    private func applyAuthResponse(_ data: Data, fallbackEmail: String) throws -> CloudSession? {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = object["access_token"] as? String,
              let refresh = object["refresh_token"] as? String,
              let user = object["user"] as? [String: Any],
              let idString = user["id"] as? String, let id = UUID(uuidString: idString) else { return nil }
        let expiresIn = object["expires_in"] as? Double ?? 3600
        let email = user["email"] as? String ?? fallbackEmail
        return CloudSession(accessToken: access, refreshToken: refresh, userID: id, email: email,
                            expiresAt: Date().addingTimeInterval(expiresIn - 60))
    }

    private func refreshIfNeeded() async throws {
        guard let current = session, current.expiresAt < Date() else { return }
        guard let url = URL(string: baseURL + "/auth/v1/token?grant_type=refresh_token") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": current.refreshToken])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let refreshed = try applyAuthResponse(data, fallbackEmail: current.email) else {
            session = nil
            status = .signedOut
            throw KKSUCloudError.noSession
        }
        session = refreshed
    }

    // MARK: - Аккаунты

    /// Регистрация на сервере. Возвращает созданного пользователя, либо бросает emailConfirmation,
    /// если в проекте включено подтверждение email.
    func signUp(fullName: String, email: String, phone: String, password: String, role: KKSURole) async throws {
        guard let store else { throw KKSUCloudError.notConfigured }
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard KKSUStore.isValidEmail(email) else { throw KKSUAuthError.invalidEmail }
        guard KKSUStore.isStrongPassword(password) else { throw KKSUAuthError.weakPassword }
        let data = try await request("/auth/v1/signup", method: "POST",
                                     json: ["email": email, "password": password,
                                            "data": ["full_name": fullName, "role": role.rawValue, "phone": phone]],
                                     authorized: false)
        guard let newSession = try applyAuthResponse(data, fallbackEmail: email) else {
            throw KKSUCloudError.emailConfirmation
        }
        session = newSession
        let member = try await ensureMember(role: role, fullName: fullName)
        try await finishSignIn(member: member, email: email, phone: phone, fullName: fullName, expectedRole: nil, store: store)
    }

    func signIn(email: String, password: String, expectedRole: KKSURole?) async throws {
        guard let store else { throw KKSUCloudError.notConfigured }
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let data = try await request("/auth/v1/token?grant_type=password", method: "POST",
                                     json: ["email": email, "password": password], authorized: false)
        guard let newSession = try applyAuthResponse(data, fallbackEmail: email) else { throw KKSUCloudError.noSession }
        session = newSession
        let metadata = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["user"] as? [String: Any]
        let userData = metadata?["user_metadata"] as? [String: Any]
        let requestedRole = (userData?["role"] as? String).flatMap(KKSURole.init(rawValue:)) ?? expectedRole ?? .student
        let fullName = userData?["full_name"] as? String ?? email
        let phone = userData?["phone"] as? String ?? ""
        let member = try await ensureMember(role: requestedRole, fullName: fullName)
        try await finishSignIn(member: member, email: email, phone: phone, fullName: fullName, expectedRole: expectedRole, store: store)
    }

    private func ensureMember(role: KKSURole, fullName: String) async throws -> CloudMember {
        guard let session else { throw KKSUCloudError.noSession }
        if let existing = try await fetchMember(session.userID) { return existing }
        let data = try await request("/rest/v1/kksu_members", method: "POST",
                                     json: ["user_id": session.userID.uuidString, "school_id": schoolID,
                                            "role": role.rawValue, "full_name": fullName],
                                     headers: ["Prefer": "return=representation"])
        guard let member = try JSONDecoder().decode([CloudMember].self, from: data).first else { throw KKSUCloudError.noSession }
        return member
    }

    private func fetchMember(_ id: UUID) async throws -> CloudMember? {
        let data = try await request("/rest/v1/kksu_members?select=*&user_id=eq.\(id.uuidString)")
        return try JSONDecoder().decode([CloudMember].self, from: data).first
    }

    private func finishSignIn(member: CloudMember, email: String, phone: String, fullName: String,
                              expectedRole: KKSURole?, store: KKSUStore) async throws {
        if member.blocked { await signOut(); throw KKSUCloudError.blocked }
        if let expectedRole, expectedRole != member.kksuRole { await signOut(); throw KKSUCloudError.wrongRole(member.kksuRole) }
        if !member.approved { await signOut(); throw KKSUCloudError.pendingApproval }
        // Первый вход на этом устройстве: демо-данные убираем, данные школы загружаются с сервера.
        if !store.cloudDataLoaded {
            store.enterCloudMode()
            knownHashes = [:]
            lastPull = nil
        }
        store.adoptCloudUser(id: member.user_id, fullName: member.full_name.isEmpty ? fullName : member.full_name,
                             email: email, phone: phone, role: member.kksuRole)
        startPolling()
        await sync()
    }

    func signOut() async {
        if session != nil {
            _ = try? await request("/auth/v1/logout", method: "POST")
        }
        session = nil
        pollTask?.cancel()
        pollTask = nil
        status = isConfigured ? .signedOut : .localOnly
    }

    func requestPasswordReset(email: String) async throws {
        _ = try await request("/auth/v1/recover", method: "POST",
                              json: ["email": email.trimmingCharacters(in: .whitespaces).lowercased()], authorized: false)
    }

    /// Сброс пароля по 6-значному коду из письма (в шаблоне письма Supabase должен быть {{ .Token }}).
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        guard KKSUStore.isStrongPassword(newPassword) else { throw KKSUAuthError.weakPassword }
        let data = try await request("/auth/v1/verify", method: "POST",
                                     json: ["type": "recovery", "email": email.trimmingCharacters(in: .whitespaces).lowercased(),
                                            "token": code.trimmingCharacters(in: .whitespaces)], authorized: false)
        guard let recovery = try applyAuthResponse(data, fallbackEmail: email) else { throw KKSUAuthError.invalidCode }
        session = recovery
        _ = try await request("/auth/v1/user", method: "PUT", json: ["password": newPassword])
        await signOut()
    }

    func deleteAccount() async throws {
        _ = try await request("/rest/v1/rpc/kksu_delete_my_account", method: "POST", json: [String: String]())
        await signOut()
    }

    // MARK: - Участники (администратор)

    func loadMembers() async {
        guard isSignedIn else { return }
        do {
            let data = try await request("/rest/v1/kksu_members?select=*&school_id=eq.\(schoolID)&order=created_at.desc")
            members = try JSONDecoder().decode([CloudMember].self, from: data)
            store?.applyMembers(members)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func updateMember(_ userID: UUID, role: KKSURole? = nil, approved: Bool? = nil, blocked: Bool? = nil) async throws {
        var fields: [String: Any] = [:]
        if let role { fields["role"] = role.rawValue }
        if let approved { fields["approved"] = approved }
        if let blocked { fields["blocked"] = blocked }
        guard !fields.isEmpty else { return }
        _ = try await request("/rest/v1/kksu_members?user_id=eq.\(userID.uuidString)", method: "PATCH", json: fields)
        await loadMembers()
    }

    // MARK: - Синхронизация

    func scheduleSync(delay: Double = 1.5) {
        guard isSignedIn else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.sync()
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.sync()
            }
        }
    }

    func sync() async {
        guard isSignedIn, let store else { return }
        if isSyncing { needsAnotherSync = true; return }
        isSyncing = true
        status = .syncing
        defer { isSyncing = false }
        do {
            try await push(store)
            try await pull(store)
            await loadMembers()
            status = .synced(Date())
        } catch KKSUCloudError.noSession {
            status = .signedOut
        } catch {
            status = .failed(error.localizedDescription)
        }
        if needsAnotherSync {
            needsAnotherSync = false
            scheduleSync(delay: 0.3)
        }
    }

    private static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).prefix(12).map { String(format: "%02x", $0) }.joined()
    }

    private func push(_ store: KKSUStore) async throws {
        guard let me = session?.userID else { return }
        let isStaff = [.teacher, .psychologist, .expert, .mentor, .admin].contains(store.currentUser?.role ?? .student)
        let records = KKSUCloudCollections.encodeAll(store)
        var current: [String: String] = [:]
        var changed: [(key: String, hash: String, row: [String: Any])] = []
        for record in records {
            let key = "\(record.collection)/\(record.id.uuidString)"
            let hash = Self.hash(record.data)
            current[key] = hash
            guard knownHashes[key] != hash, rejectedHashes[key] != hash else { continue }
            if KKSUCloudCollections.staffOnly.contains(record.collection) && !isStaff { continue }
            guard let object = try? JSONSerialization.jsonObject(with: record.data) else { continue }
            changed.append((key, hash, ["collection": record.collection, "id": record.id.uuidString, "school_id": schoolID,
                                        "owner_id": me.uuidString, "visible_to": record.visibleTo.map(\.uuidString),
                                        "data": object, "deleted": false]))
        }
        // Удалённые локально записи помечаем на сервере как deleted.
        for (key, _) in knownHashes where current[key] == nil {
            let parts = key.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2, KKSUCloudCollections.syncedNames.contains(parts[0]) else { continue }
            if KKSUCloudCollections.staffOnly.contains(parts[0]) && !isStaff { continue }
            changed.append((key, "deleted", ["collection": parts[0], "id": parts[1], "school_id": schoolID,
                                             "owner_id": me.uuidString, "data": [String: String](), "deleted": true]))
        }
        guard !changed.isEmpty else { return }
        var updated = knownHashes
        for chunkStart in stride(from: 0, to: changed.count, by: 200) {
            let chunk = Array(changed[chunkStart..<min(chunkStart + 200, changed.count)])
            do {
                try await upsert(chunk.map(\.row))
                for item in chunk { updated[item.key] = item.hash == "deleted" ? nil : item.hash }
            } catch KKSUCloudError.http(let code, _) where code == 401 || code == 403 {
                // Часть записей запрещена правилами доступа — отправляем по одной и пропускаем запрещённые.
                for item in chunk {
                    do {
                        try await upsert([item.row])
                        updated[item.key] = item.hash == "deleted" ? nil : item.hash
                    } catch {
                        rejectedHashes[item.key] = item.hash
                    }
                }
            }
        }
        knownHashes = updated
    }

    private func upsert(_ rows: [[String: Any]]) async throws {
        _ = try await request("/rest/v1/kksu_records?on_conflict=collection,id", method: "POST", json: rows,
                              headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
    }

    private func pull(_ store: KKSUStore) async throws {
        var rows: [KKSUCloudCollections.PulledRow] = []
        var cursor = lastPull
        while true {
            var query = "/rest/v1/kksu_records?select=collection,id,data,deleted,updated_at&school_id=eq.\(schoolID)&order=updated_at.asc&limit=1000"
            if let cursor {
                let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-_.:"))) ?? cursor
                query += "&updated_at=gt.\(encoded)"
            }
            let data = try await request(query)
            guard let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { break }
            for item in list {
                guard let collection = item["collection"] as? String,
                      let idString = item["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                let deleted = item["deleted"] as? Bool ?? false
                let payload = deleted ? nil : (item["data"]).flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                rows.append(.init(collection: collection, id: id, data: payload, deleted: deleted))
                if let updatedAt = item["updated_at"] as? String { cursor = updatedAt }
            }
            if list.count < 1000 { break }
        }
        guard !rows.isEmpty else { return }
        KKSUCloudCollections.apply(rows, to: store)
        // Запоминаем версии полученных записей, чтобы не отправлять их обратно.
        var updated = knownHashes
        let byKey = Dictionary(KKSUCloudCollections.encodeAll(store).map { ("\($0.collection)/\($0.id.uuidString)", $0.data) },
                               uniquingKeysWith: { first, _ in first })
        for row in rows {
            let key = "\(row.collection)/\(row.id.uuidString)"
            if row.deleted { updated[key] = nil } else if let data = byKey[key] { updated[key] = Self.hash(data) }
        }
        knownHashes = updated
        lastPull = cursor
    }

    /// Загружает на сервер учебный контент из демо-набора (программы, библиотеку, тесты, курсы,
    /// партнёров, мероприятия, цены) — без демо-пользователей и их личных данных.
    func uploadStarterContent() async {
        guard let store else { return }
        store.importStarterContent()
        await sync()
    }
}
