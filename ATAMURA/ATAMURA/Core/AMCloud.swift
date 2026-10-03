//
//  AMCloud.swift
//  ATA MURA
//
//  Сервер ATA MURA на Supabase: общие аккаунты, лента и публикации на всех устройствах.
//  Работает через REST API Supabase (Auth + PostgREST) без сторонних библиотек.
//  Схема базы и правила доступа — ATAMURA/backend/schema.sql, инструкция — ATAMURA/backend/README.md.
//
//  Пока сервер не подключён (Настройки → Сервер), приложение работает локально на устройстве.
//

import Foundation
import CryptoKit
import Security

enum AMKeychain {
    private static let service = "kz.atamura.app"

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

/// Параметры проекта Supabase. По умолчанию — проект, где уже работает KKSU:
/// таблицы ATA MURA (atamura_*) создаются в нём отдельно и не пересекаются с KKSU.
/// anon-ключ публичный по замыслу Supabase: доступ ограничивают правила RLS в базе.
enum AMCloudDefaults {
    static let projectURL = "https://vllechyeunbtozhubuud.supabase.co"
    static let anonKey = "sb_publishable_ThNRdPI2yoG1rQxLAiwusg_CmxF8Y7Y"
}

struct AMCloudSession: Codable {
    var accessToken: String
    var refreshToken: String
    var userID: UUID
    var email: String
    var expiresAt: Date
}

struct AMCloudMember: Codable, Identifiable {
    var id: UUID { user_id }
    let user_id: UUID
    let role: String
    let full_name: String
    let blocked: Bool

    var amRole: AMRole { AMRole(rawValue: role) ?? .member }
}

enum AMCloudStatus: Equatable {
    case localOnly, signedOut, syncing, synced(Date), failed(String)

    var title: String {
        switch self {
        case .localOnly: return L("cloud.status.local")
        case .signedOut: return L("cloud.status.signedOut")
        case .syncing: return L("cloud.status.syncing")
        case .synced(let date): return L("cloud.status.synced", date.amDateTime)
        case .failed(let message): return L("cloud.status.failed", message)
        }
    }
}

enum AMCloudError: LocalizedError {
    case notConfigured, http(Int, String), emailConfirmation, blocked, noSession

    var errorDescription: String? {
        switch self {
        case .notConfigured: return L("cloud.error.notConfigured")
        case .http(let code, let message): return message.isEmpty ? L("cloud.error.http", code) : message
        case .emailConfirmation: return L("cloud.error.confirm")
        case .blocked: return L("auth.error.blocked")
        case .noSession: return L("cloud.error.noSession")
        }
    }
}

@MainActor
final class AMCloud: ObservableObject {
    static let shared = AMCloud()

    /// Сервер включается вручную после выполнения schema.sql (Настройки → Сервер).
    @Published var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: "atamura.cloud.enabled") }
    }
    @Published var projectURL: String {
        didSet { UserDefaults.standard.set(projectURL, forKey: "atamura.cloud.url") }
    }
    @Published var anonKey: String {
        didSet { UserDefaults.standard.set(anonKey, forKey: "atamura.cloud.key") }
    }
    @Published private(set) var session: AMCloudSession? {
        didSet { saveSession() }
    }
    @Published private(set) var status: AMCloudStatus = .localOnly
    @Published private(set) var members: [AMCloudMember] = []

    weak var store: AMStore?
    private var syncTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var isSyncing = false
    private var needsAnotherSync = false
    private var knownHashes: [String: String] {
        didSet { UserDefaults.standard.set(knownHashes, forKey: "atamura.cloud.hashes") }
    }
    private var rejectedHashes: [String: String] = [:]
    private var lastPull: String? {
        didSet { UserDefaults.standard.set(lastPull, forKey: "atamura.cloud.lastPull") }
    }

    var isConfigured: Bool { enabled && !projectURL.trimmingCharacters(in: .whitespaces).isEmpty && !anonKey.isEmpty }
    var isSignedIn: Bool { isConfigured && session != nil }

    private init() {
        let defaults = UserDefaults.standard
        func stored(_ key: String) -> String? { defaults.string(forKey: key).flatMap { $0.isEmpty ? nil : $0 } }
        enabled = defaults.bool(forKey: "atamura.cloud.enabled")
        projectURL = stored("atamura.cloud.url") ?? AMCloudDefaults.projectURL
        anonKey = stored("atamura.cloud.key") ?? AMCloudDefaults.anonKey
        knownHashes = defaults.dictionary(forKey: "atamura.cloud.hashes") as? [String: String] ?? [:]
        lastPull = defaults.string(forKey: "atamura.cloud.lastPull")
        if let data = AMKeychain.read(account: "cloud-session")?.data(using: .utf8) {
            session = try? JSONDecoder.am.decode(AMCloudSession.self, from: data)
        }
        status = isConfigured ? (session == nil ? .signedOut : .synced(Date())) : .localOnly
    }

    private func saveSession() {
        if let session, let data = try? JSONEncoder.am.encode(session), let text = String(data: data, encoding: .utf8) {
            AMKeychain.save(text, account: "cloud-session")
        } else {
            AMKeychain.save("", account: "cloud-session")
        }
    }

    func start(with store: AMStore) {
        self.store = store
        status = isConfigured ? (session == nil ? .signedOut : status) : .localOnly
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
        guard isConfigured, let url = URL(string: baseURL + path) else { throw AMCloudError.notConfigured }
        if authorized { try await refreshIfNeeded() }
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
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
            throw AMCloudError.http(code, Self.translate(message))
        }
        return data
    }

    private static func translate(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("invalid login credentials") { return L("auth.error.credentials") }
        if lower.contains("already registered") { return L("auth.error.taken") }
        if lower.contains("email not confirmed") { return L("cloud.error.confirm") }
        if lower.contains("password should be") { return L("auth.error.password") }
        if lower.contains("row-level security") { return L("cloud.error.rls") }
        if lower.contains("does not exist") || lower.contains("schema cache") { return L("cloud.error.schema") }
        return message
    }

    private func applyAuthResponse(_ data: Data, fallbackEmail: String) throws -> AMCloudSession? {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = object["access_token"] as? String,
              let refresh = object["refresh_token"] as? String,
              let user = object["user"] as? [String: Any],
              let idString = user["id"] as? String, let id = UUID(uuidString: idString) else { return nil }
        let expiresIn = object["expires_in"] as? Double ?? 3600
        return AMCloudSession(accessToken: access, refreshToken: refresh, userID: id,
                              email: user["email"] as? String ?? fallbackEmail,
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
            throw AMCloudError.noSession
        }
        session = refreshed
    }

    // MARK: - Аккаунты

    func signUp(fullName: String, email: String, password: String) async throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard AMStore.isValidEmail(email) else { throw AMAuthError.invalidEmail }
        guard AMStore.isStrongPassword(password) else { throw AMAuthError.weakPassword }
        let data = try await request("/auth/v1/signup", method: "POST",
                                     json: ["email": email, "password": password, "data": ["full_name": fullName]],
                                     authorized: false)
        guard let newSession = try applyAuthResponse(data, fallbackEmail: email) else { throw AMCloudError.emailConfirmation }
        session = newSession
        try await finishSignIn(fullName: fullName, email: email)
    }

    func signIn(email: String, password: String) async throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let data = try await request("/auth/v1/token?grant_type=password", method: "POST",
                                     json: ["email": email, "password": password], authorized: false)
        guard let newSession = try applyAuthResponse(data, fallbackEmail: email) else { throw AMCloudError.noSession }
        session = newSession
        let user = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["user"] as? [String: Any]
        let fullName = (user?["user_metadata"] as? [String: Any])?["full_name"] as? String ?? email
        try await finishSignIn(fullName: fullName, email: email)
    }

    private func finishSignIn(fullName: String, email: String) async throws {
        guard let session, let store else { throw AMCloudError.noSession }
        var member = try await fetchMember(session.userID)
        if member == nil {
            let data = try await request("/rest/v1/atamura_members", method: "POST",
                                         json: ["user_id": session.userID.uuidString, "role": "member", "full_name": fullName],
                                         headers: ["Prefer": "return=representation"])
            member = try JSONDecoder().decode([AMCloudMember].self, from: data).first
        }
        guard let member else { throw AMCloudError.noSession }
        if member.blocked { await signOut(); throw AMCloudError.blocked }
        if !store.cloudMode {
            store.enterCloudMode()
            knownHashes = [:]
            lastPull = nil
        }
        store.adoptCloudUser(id: member.user_id, fullName: member.full_name.isEmpty ? fullName : member.full_name,
                             email: email, role: member.amRole)
        startPolling()
        await sync()
    }

    private func fetchMember(_ id: UUID) async throws -> AMCloudMember? {
        let data = try await request("/rest/v1/atamura_members?select=*&user_id=eq.\(id.uuidString)")
        return try JSONDecoder().decode([AMCloudMember].self, from: data).first
    }

    func signOut() async {
        if session != nil { _ = try? await request("/auth/v1/logout", method: "POST") }
        session = nil
        pollTask?.cancel()
        pollTask = nil
        status = isConfigured ? .signedOut : .localOnly
    }

    func requestPasswordReset(email: String) async throws {
        _ = try await request("/auth/v1/recover", method: "POST",
                              json: ["email": email.trimmingCharacters(in: .whitespaces).lowercased()], authorized: false)
    }

    func deleteAccount() async throws {
        guard isSignedIn else { return }
        _ = try await request("/rest/v1/rpc/atamura_delete_my_account", method: "POST", json: [String: String]())
        await signOut()
    }

    // MARK: - Участники (администратор)

    func loadMembers() async {
        guard isSignedIn else { return }
        if let data = try? await request("/rest/v1/atamura_members?select=*&order=created_at.desc"),
           let list = try? JSONDecoder().decode([AMCloudMember].self, from: data) {
            members = list
            guard let store else { return }
            for member in list {
                if let index = store.db.users.firstIndex(where: { $0.id == member.user_id }) {
                    if store.db.users[index].role != member.amRole { store.db.users[index].role = member.amRole }
                    if store.db.users[index].blocked != member.blocked { store.db.users[index].blocked = member.blocked }
                }
            }
        }
    }

    func updateMember(_ userID: UUID, role: AMRole? = nil, blocked: Bool? = nil) async throws {
        var fields: [String: Any] = [:]
        if let role { fields["role"] = role.rawValue }
        if let blocked { fields["blocked"] = blocked }
        guard !fields.isEmpty, isSignedIn else { return }
        _ = try await request("/rest/v1/atamura_members?user_id=eq.\(userID.uuidString)", method: "PATCH", json: fields)
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
                try? await Task.sleep(nanoseconds: 30_000_000_000)
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
        } catch AMCloudError.noSession {
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

    private func push(_ store: AMStore) async throws {
        guard let me = session?.userID else { return }
        let isStaff = store.isStaff
        var current: [String: String] = [:]
        var changed: [(key: String, hash: String, row: [String: Any])] = []
        for record in AMCloudCollections.encodeAll(store) {
            let key = "\(record.collection)/\(record.id.uuidString)"
            let hash = Self.hash(record.data)
            current[key] = hash
            guard knownHashes[key] != hash, rejectedHashes[key] != hash else { continue }
            if !isStaff {
                if AMCloudCollections.staffOnly.contains(record.collection) { continue }
                if record.ownerId != me && !AMCloudCollections.sharedWrite.contains(record.collection) { continue }
            }
            guard let object = try? JSONSerialization.jsonObject(with: record.data) else { continue }
            var row: [String: Any] = ["collection": record.collection, "id": record.id.uuidString,
                                      "visible_to": record.visibleTo.map(\.uuidString), "published": record.published,
                                      "data": object, "deleted": false]
            row["owner_id"] = record.ownerId?.uuidString ?? NSNull()
            changed.append((key, hash, row))
        }
        for (key, _) in knownHashes where current[key] == nil {
            let parts = key.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            if !isStaff && AMCloudCollections.staffOnly.contains(parts[0]) { continue }
            changed.append((key, "deleted", ["collection": parts[0], "id": parts[1], "published": false,
                                             "data": [String: String](), "deleted": true]))
        }
        guard !changed.isEmpty else { return }
        var updated = knownHashes
        for start in stride(from: 0, to: changed.count, by: 25) {
            let chunk = Array(changed[start..<min(start + 25, changed.count)])
            do {
                try await upsert(chunk.map(\.row))
                for item in chunk { updated[item.key] = item.hash == "deleted" ? nil : item.hash }
            } catch AMCloudError.http(let code, _) where code == 401 || code == 403 || code == 400 {
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
        _ = try await request("/rest/v1/atamura_records?on_conflict=collection,id", method: "POST", json: rows,
                              headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
    }

    private func pull(_ store: AMStore) async throws {
        var rows: [AMCloudCollections.PulledRow] = []
        var cursor = lastPull
        while true {
            var query = "/rest/v1/atamura_records?select=collection,id,data,deleted,updated_at&order=updated_at.asc&limit=500"
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
                let payload = deleted ? nil : item["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                rows.append(.init(collection: collection, id: id, data: payload, deleted: deleted))
                if let updatedAt = item["updated_at"] as? String { cursor = updatedAt }
            }
            if list.count < 500 { break }
        }
        guard !rows.isEmpty else { return }
        AMCloudCollections.apply(rows, to: store)
        var updated = knownHashes
        let byKey = Dictionary(AMCloudCollections.encodeAll(store).map { ("\($0.collection)/\($0.id.uuidString)", $0.data) },
                               uniquingKeysWith: { first, _ in first })
        for row in rows {
            let key = "\(row.collection)/\(row.id.uuidString)"
            if row.deleted { updated[key] = nil } else if let data = byKey[key] { updated[key] = Self.hash(data) }
        }
        knownHashes = updated
        lastPull = cursor
    }

    /// Загружает на сервер справочники из стартового набора (темы, места карты, забытые идеи, курсы…).
    func uploadStarterContent() async {
        guard let store, store.isStaff else { return }
        let seed = AMSeed.database()
        func merge<T: Identifiable>(_ local: inout [T], _ extra: [T]) where T.ID == UUID {
            let ids = Set(local.map(\.id))
            local += extra.filter { !ids.contains($0.id) }
        }
        merge(&store.db.topics, seed.topics)
        merge(&store.db.places, seed.places)
        merge(&store.db.forgottenIdeas, seed.forgottenIdeas)
        merge(&store.db.kidsThemes, seed.kidsThemes)
        merge(&store.db.courses, seed.courses)
        merge(&store.db.products, seed.products)
        merge(&store.db.series, seed.series)
        await sync()
    }
}

// MARK: - Коллекции синхронизации

struct AMCloudRecord {
    let collection: String
    let id: UUID
    let ownerId: UUID?
    let visibleTo: [UUID]
    let published: Bool
    let data: Data
}

@MainActor
enum AMCloudCollections {
    struct PulledRow {
        let collection: String
        let id: UUID
        let data: Data?
        let deleted: Bool
    }

    /// Меняет только редакция (см. atamura_is_staff_only в schema.sql).
    static let staffOnly: Set<String> = ["topics", "forgottenIdeas", "kidsThemes", "news", "magazines", "courses", "products",
                                         "contentItems", "ideas", "vlog", "guests", "series", "media", "events", "partners",
                                         "tasks", "settings"]
    /// Записи, которые создают для другого человека (уведомление, приглашение в проект).
    static let sharedWrite: Set<String> = ["notifications", "invites"]

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private struct SyncCollection {
        let encode: (AMStore) -> [AMCloudRecord]
        let apply: (AMStore, [PulledRow]) -> Void
    }

    private static func list<T: Codable & Identifiable>(_ name: String, _ path: WritableKeyPath<AMDatabase, [T]>,
                                                       owner: @escaping (T) -> UUID?,
                                                       published: @escaping (T) -> Bool,
                                                       visible: @escaping (T) -> [UUID] = { _ in [] },
                                                       prepare: @escaping (T) -> T = { $0 },
                                                       merge: @escaping (T, T) -> T = { _, remote in remote }) -> (String, SyncCollection) where T.ID == UUID {
        (name, SyncCollection(encode: { store in
            store.db[keyPath: path].compactMap { item in
                guard let data = try? encoder.encode(prepare(item)) else { return nil }
                return AMCloudRecord(collection: name, id: item.id, ownerId: owner(item), visibleTo: visible(item),
                                     published: published(item), data: data)
            }
        }, apply: { store, rows in
            var items = store.db[keyPath: path]
            for row in rows where row.collection == name {
                if row.deleted {
                    items.removeAll { $0.id == row.id }
                } else if let data = row.data, let remote = try? JSONDecoder.am.decode(T.self, from: data) {
                    if let index = items.firstIndex(where: { $0.id == row.id }) {
                        items[index] = merge(items[index], remote)
                    } else {
                        items.append(remote)
                    }
                }
            }
            store.db[keyPath: path] = items
        }))
    }

    private static var collections: [(String, SyncCollection)] {
        var result: [(String, SyncCollection)] = []
        result.append(list("users", \.users, owner: { $0.id }, published: { _ in true },
                     prepare: { user in
                         var user = user
                         user.passwordHash = ""
                         user.email = ""
                         return user
                     },
                     merge: { local, remote in
                         var merged = remote
                         merged.email = local.email
                         merged.passwordHash = local.passwordHash
                         return merged
                     }))
        result.append(list("posts", \.posts, owner: { $0.authorId }, published: { $0.status == .approved }))
        result.append(list("topics", \.topics, owner: { _ in nil }, published: { _ in true }))
        result.append(list("comments", \.comments, owner: { $0.authorId }, published: { _ in true }))
        result.append(list("likes", \.likes, owner: { $0.userId }, published: { _ in true }))
        result.append(list("reports", \.reports, owner: { $0.reporterId }, published: { _ in false }))
        result.append(list("places", \.places, owner: { $0.authorId }, published: { $0.status == .approved }))
        result.append(list("projects", \.projects, owner: { $0.ownerId }, published: { $0.status == .approved }))
        result.append(list("forgottenIdeas", \.forgottenIdeas, owner: { _ in nil }, published: { _ in true }))
        result.append(list("invites", \.invites, owner: { $0.fromId }, published: { $0.status == .accepted }, visible: { [$0.toId] }))
        result.append(list("museum", \.museum, owner: { $0.ownerId }, published: { $0.status == .approved }))
        result.append(list("kidsThemes", \.kidsThemes, owner: { _ in nil }, published: { _ in true }))
        result.append(list("kidsWorks", \.kidsWorks, owner: { $0.ownerId }, published: { $0.status == .approved }))
        result.append(list("research", \.research, owner: { $0.ownerId }, published: { $0.reviewStatus == .published }))
        result.append(list("notifications", \.notifications, owner: { _ in nil }, published: { _ in false }, visible: { [$0.userId] }))
        result.append(list("news", \.news, owner: { _ in nil }, published: { !$0.isDraft }))
        result.append(list("magazines", \.magazines, owner: { _ in nil }, published: { $0.published }))
        result.append(list("courses", \.courses, owner: { _ in nil }, published: { $0.published }))
        result.append(list("enrollments", \.enrollments, owner: { $0.userId }, published: { _ in false }))
        result.append(list("orders", \.orders, owner: { $0.userId }, published: { _ in false }))
        result.append(list("products", \.products, owner: { _ in nil }, published: { $0.published }))
        result.append(list("contentItems", \.contentItems, owner: { _ in nil }, published: { _ in false }))
        result.append(list("ideas", \.ideas, owner: { _ in nil }, published: { _ in false }))
        result.append(list("vlog", \.vlog, owner: { _ in nil }, published: { _ in false }))
        result.append(list("guests", \.guests, owner: { _ in nil }, published: { _ in false }))
        result.append(list("series", \.series, owner: { _ in nil }, published: { _ in false }))
        result.append(list("media", \.media, owner: { _ in nil }, published: { _ in false }))
        result.append(list("events", \.events, owner: { _ in nil }, published: { $0.published }))
        result.append(list("partners", \.partners, owner: { _ in nil }, published: { _ in false }))
        result.append(list("tasks", \.tasks, owner: { _ in nil }, published: { _ in false }))
        return result
    }

    /// Проект недели хранится отдельной записью настроек.
    private static let settingsID = UUID(uuidString: "00000000-0000-0000-0000-00000000A7A1")!

    private struct Settings: Codable {
        var projectOfWeekId: UUID?
        var projectOfWeekDate: Date?
    }

    static func encodeAll(_ store: AMStore) -> [AMCloudRecord] {
        var records = collections.flatMap { $0.1.encode(store) }
        let settings = Settings(projectOfWeekId: store.db.projectOfWeekId, projectOfWeekDate: store.db.projectOfWeekDate)
        if let data = try? encoder.encode(settings) {
            records.append(AMCloudRecord(collection: "settings", id: settingsID, ownerId: nil, visibleTo: [], published: true, data: data))
        }
        return records
    }

    static func apply(_ rows: [PulledRow], to store: AMStore) {
        let names = Set(rows.map(\.collection))
        for (name, collection) in collections where names.contains(name) {
            collection.apply(store, rows)
        }
        if let row = rows.last(where: { $0.collection == "settings" && $0.id == settingsID }), let data = row.data,
           let settings = try? JSONDecoder.am.decode(Settings.self, from: data) {
            store.db.projectOfWeekId = settings.projectOfWeekId
            store.db.projectOfWeekDate = settings.projectOfWeekDate
        }
    }
}
