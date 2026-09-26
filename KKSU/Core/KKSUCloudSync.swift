//
//  KKSUCloudSync.swift
//  KKSU Online
//
//  Какие данные синхронизируются с сервером и кому видна каждая запись.
//  visible_to — список пользователей, которым запись доступна (кроме сотрудников школы,
//  которые видят всё после подтверждения администратором). Пустой список — запись видна
//  всей школе (программы, расписание, библиотека). staffOnlyAudience — только сотрудникам.
//

import Foundation

struct CloudRecord {
    let collection: String
    let id: UUID
    let visibleTo: [UUID]
    let data: Data
}

@MainActor
struct CloudCollection {
    let name: String
    let encode: (KKSUStore) -> [CloudRecord]
    let apply: (KKSUStore, [KKSUCloudCollections.PulledRow]) -> Void
}

@MainActor
enum KKSUCloudCollections {

    struct PulledRow {
        let collection: String
        let id: UUID
        let data: Data?
        let deleted: Bool
    }

    /// Запись видна только сотрудникам школы.
    static let staffOnlyAudience = [UUID(uuidString: "00000000-0000-0000-0000-000000000000")!]
    static let billingSettingsID = UUID(uuidString: "00000000-0000-0000-0000-0000000B1111")!

    /// Коллекции, которые на сервере может менять только персонал (см. kksu_is_staff_only в schema.sql).
    static let staffOnly: Set<String> = ["entitlements", "products", "promoCodes", "billingSettings", "programs", "partners", "internships", "events"]

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder.kksu
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    // MARK: - Аудитории

    /// Ученик, его родители и наставники.
    static func audience(_ studentID: UUID?, _ store: KKSUStore) -> [UUID] {
        guard let studentID else { return staffOnlyAudience }
        let guardians = store.db.users.filter { ($0.role == .parent || $0.role == .mentor) && $0.linkedStudentIDs.contains(studentID) }.map(\.id)
        return [studentID] + guardians
    }

    static func audience(of ids: [UUID], _ store: KKSUStore) -> [UUID] {
        let all = ids.flatMap { audience($0, store) }
        return all.isEmpty ? staffOnlyAudience : Array(Set(all))
    }

    static func projectAudience(_ projectID: UUID, _ store: KKSUStore) -> [UUID] {
        guard let project = store.project(projectID) else { return staffOnlyAudience }
        return audience(of: project.authorIDs + [project.mentorID].compactMap { $0 }, store)
    }

    // MARK: - Конструкторы коллекций

    private static func list<T: Codable & Identifiable>(_ name: String, _ path: WritableKeyPath<KKSUDatabase, [T]>,
                                                       visible: @escaping (T, KKSUStore) -> [UUID],
                                                       prepare: @escaping (T, KKSUStore) -> T = { item, _ in item },
                                                       merge: @escaping (T?, T) -> T = { _, remote in remote }) -> CloudCollection where T.ID == UUID {
        CloudCollection(name: name, encode: { store in
            store.db[keyPath: path].compactMap { item in
                guard let data = try? encoder.encode(prepare(item, store)) else { return nil }
                return CloudRecord(collection: name, id: item.id, visibleTo: visible(item, store), data: data)
            }
        }, apply: { store, rows in
            var items = store.db[keyPath: path]
            for row in rows {
                if row.deleted {
                    items.removeAll { $0.id == row.id }
                } else if let data = row.data, let remote = try? JSONDecoder.kksu.decode(T.self, from: data) {
                    if let index = items.firstIndex(where: { $0.id == row.id }) {
                        items[index] = merge(items[index], remote)
                    } else {
                        items.append(merge(nil, remote))
                    }
                }
            }
            store.db[keyPath: path] = items
        })
    }

    private static func billingList<T: Codable & Identifiable>(_ name: String, _ path: WritableKeyPath<KKSUBillingDatabase, [T]>,
                                                              visible: @escaping (T, KKSUStore) -> [UUID]) -> CloudCollection where T.ID == UUID {
        CloudCollection(name: name, encode: { store in
            store.billing[keyPath: path].compactMap { item in
                guard let data = try? encoder.encode(item) else { return nil }
                return CloudRecord(collection: name, id: item.id, visibleTo: visible(item, store), data: data)
            }
        }, apply: { store, rows in
            var items = store.billing[keyPath: path]
            for row in rows {
                if row.deleted {
                    items.removeAll { $0.id == row.id }
                } else if let data = row.data, let remote = try? JSONDecoder.kksu.decode(T.self, from: data) {
                    if let index = items.firstIndex(where: { $0.id == row.id }) { items[index] = remote } else { items.append(remote) }
                }
            }
            store.billing[keyPath: path] = items
        })
    }

    private struct UserSettingsRecord: Codable {
        var accessibility: AccessibilitySettings?
        var preferences: LearningPreferences?
    }

    // MARK: - Все коллекции

    static let all: [CloudCollection] = [
        // Каталог пользователей школы: имена и роли. Email, телефон и пароли на сервер не попадают —
        // вход выполняется через Supabase Auth.
        list("users", \.users, visible: { _, _ in [] }, prepare: { user, store in
            var copy = user
            copy.passwordHash = ""
            copy.salt = ""
            copy.recoveryCode = nil
            copy.recoveryExpires = nil
            if user.id != store.currentUser?.id { copy.email = ""; copy.phone = "" }
            return copy
        }, merge: { local, remote in
            guard let local else { return remote }
            var merged = remote
            if remote.email.isEmpty { merged.email = local.email }
            if remote.phone.isEmpty { merged.phone = local.phone }
            merged.passwordHash = local.passwordHash
            merged.salt = local.salt
            return merged
        }),
        list("studentProfiles", \.studentProfiles) { item, store in audience(item.userID, store) },
        list("questionnaires", \.questionnaires) { item, store in audience(item.studentID, store) },
        list("applications", \.applications) { item, _ in item.applicantUserID.map { [$0] } ?? staffOnlyAudience },
        list("consents", \.consents) { item, store in Array(Set(audience(item.studentID, store) + [item.parentID])) },
        list("programs", \.programs) { _, _ in [] },
        list("trajectory", \.trajectory) { item, store in audience(item.studentID, store) },
        list("studyPlan", \.studyPlan) { item, store in audience(item.studentID, store) },
        list("sessions", \.sessions) { _, _ in [] },
        list("calendarNotes", \.calendarNotes) { item, _ in [item.userID] },
        list("assignments", \.assignments) { item, store in
            if !item.approvedByTeacher { return staffOnlyAudience }
            if item.audience == .teachers || item.assignedIDs.isEmpty { return [] }
            return audience(of: item.assignedIDs, store)
        },
        list("submissions", \.submissions) { item, store in audience(item.studentID, store) },
        list("portfolio", \.portfolio) { item, store in audience(item.studentID, store) },
        list("achievements", \.achievements) { item, store in audience(item.userID, store) },
        list("certificates", \.certificates) { item, store in audience(item.userID, store) },
        list("history", \.history) { item, store in audience(item.userID, store) },
        list("library", \.library) { _, _ in [] },
        list("tests", \.tests) { _, _ in [] },
        list("attempts", \.attempts) { item, store in audience(item.userID, store) },
        list("threads", \.threads) { item, _ in item.participantIDs },
        list("messages", \.messages) { item, store in
            store.db.threads.first { $0.id == item.threadID }?.participantIDs ?? [item.senderID]
        },
        list("notifications", \.notifications) { item, _ in [item.userID] },
        list("academyProfiles", \.academyProfiles) { item, _ in [item.userID] },
        list("teacherCourses", \.teacherCourses) { _, _ in [] },
        list("methodologies", \.methodologies) { _, _ in [] },
        list("pilots", \.pilots) { _, _ in [] },
        list("reviews", \.reviews) { item, store in
            guard item.target == .youngInventors, let app = store.db.yiApplications.first(where: { $0.id == item.targetID }) else { return [] }
            return audience(app.applicantID, store)
        },
        list("projects", \.projects) { item, store in
            item.showInExhibition ? [] : audience(of: item.authorIDs + [item.mentorID].compactMap { $0 }, store)
        },
        list("teams", \.teams) { _, _ in [] },
        list("experiments", \.experiments) { item, store in projectAudience(item.projectID, store) },
        list("notebook", \.notebook) { item, store in projectAudience(item.projectID, store) },
        list("yiApplications", \.yiApplications) { item, store in audience(item.applicantID, store) },
        list("globalClasses", \.globalClasses) { _, _ in [] },
        list("internationalProjects", \.internationalProjects) { _, _ in [] },
        list("internationalExperts", \.internationalExperts) { _, _ in [] },
        list("engineeringCourses", \.engineeringCourses) { _, _ in [] },
        list("challenges", \.challenges) { _, _ in [] },
        list("partners", \.partners) { _, _ in [] },
        list("internships", \.internships) { _, _ in [] },
        list("internshipApplications", \.internshipApplications) { item, store in
            let partnerID = store.db.internships.first { $0.id == item.internshipID }?.partnerID
            let partnerUsers = store.db.users.filter { $0.role == .partner && $0.partnerID != nil && $0.partnerID == partnerID }.map(\.id)
            return Array(Set(audience(item.studentID, store) + partnerUsers))
        },
        list("events", \.events) { _, _ in [] },
        list("eventRegistrations", \.eventRegistrations) { item, _ in [item.userID] },
        // Оплата
        billingList("products", \.products) { _, _ in [] },
        billingList("promoCodes", \.promoCodes) { _, _ in [] },
        billingList("invoices", \.invoices) { item, store in audience(of: [item.payerID] + item.beneficiaryIDs, store) },
        billingList("entitlements", \.entitlements) { item, store in audience(item.userID, store) },
        billingList("marketplaceCourses", \.marketplaceCourses) { _, _ in [] },
        // Настройки оплаты — одна запись
        CloudCollection(name: "billingSettings", encode: { store in
            guard let data = try? encoder.encode(store.billing.settings) else { return [] }
            return [CloudRecord(collection: "billingSettings", id: billingSettingsID, visibleTo: [], data: data)]
        }, apply: { store, rows in
            if let data = rows.last?.data, let settings = try? JSONDecoder.kksu.decode(PaymentSettings.self, from: data) {
                store.billing.settings = settings
            }
        }),
        // Личные настройки доступности и обучения — видны только владельцу
        CloudCollection(name: "userSettings", encode: { store in
            let ids = Set(store.db.accessibility.keys).union(store.db.preferences.keys)
            return ids.compactMap { id in
                let record = UserSettingsRecord(accessibility: store.db.accessibility[id], preferences: store.db.preferences[id])
                guard let data = try? encoder.encode(record) else { return nil }
                return CloudRecord(collection: "userSettings", id: id, visibleTo: [id], data: data)
            }
        }, apply: { store, rows in
            for row in rows {
                guard let data = row.data, let record = try? JSONDecoder.kksu.decode(UserSettingsRecord.self, from: data) else { continue }
                if let a = record.accessibility { store.db.accessibility[row.id] = a }
                if let p = record.preferences { store.db.preferences[row.id] = p }
            }
        })
    ]

    static let syncedNames: Set<String> = Set(all.map(\.name))

    static func encodeAll(_ store: KKSUStore) -> [CloudRecord] {
        all.flatMap { $0.encode(store) }
    }

    static func apply(_ rows: [PulledRow], to store: KKSUStore) {
        let grouped = Dictionary(grouping: rows, by: \.collection)
        for collection in all {
            if let items = grouped[collection.name], !items.isEmpty {
                collection.apply(store, items)
            }
        }
    }
}
