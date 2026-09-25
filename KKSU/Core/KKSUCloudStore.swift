//
//  KKSUCloudStore.swift
//  KKSU Online
//
//  Связь локального хранилища с сервером KKSU: переход в облачный режим,
//  создание локального профиля по аккаунту сервера, роли из таблицы участников,
//  загрузка стартового учебного контента.
//

import Foundation

extension KKSUStore {

    /// Данные этого устройства уже загружены с сервера (демо-данные удалены).
    var cloudDataLoaded: Bool {
        UserDefaults.standard.bool(forKey: "kksu.cloud.loaded")
    }

    /// Убирает демо-данные: в облачном режиме всё содержимое приходит с сервера школы.
    func enterCloudMode() {
        db = KKSUDatabase()
        billing = KKSUBillingDatabase()
        UserDefaults.standard.set(true, forKey: "kksu.cloud.loaded")
    }

    /// Вернуться к демо-режиму на этом устройстве (данные сервера не удаляются).
    func leaveCloudMode() {
        UserDefaults.standard.set(false, forKey: "kksu.cloud.loaded")
        db = KKSUSeed.makeDatabase()
        billing = KKSUBillingSeed.make(db: db)
    }

    /// Создаёт или обновляет локальный профиль по аккаунту сервера и выполняет вход.
    func adoptCloudUser(id: UUID, fullName: String, email: String, phone: String, role: KKSURole) {
        if let index = db.users.firstIndex(where: { $0.id == id }) {
            db.users[index].email = email
            if !phone.isEmpty { db.users[index].phone = phone }
            db.users[index].role = role
            db.users[index].lastLogin = Date()
        } else {
            var user = KKSUUser(fullName: fullName, email: email, phone: phone, role: role, passwordHash: "", salt: "")
            user.id = id
            user.lastLogin = Date()
            db.users.append(user)
            log(id, "Регистрация на платформе", details: role.title, icon: "person.badge.plus")
        }
        if role == .student && profile(for: id) == nil {
            db.studentProfiles.append(StudentProfile(userID: id))
        }
        db.currentUserID = id
        requestNotificationPermission()
    }

    /// Роль и блокировка берутся из таблицы участников сервера — её меняет только администратор.
    func applyMembers(_ members: [CloudMember]) {
        var users = db.users
        var changed = false
        for member in members {
            guard let index = users.firstIndex(where: { $0.id == member.user_id }) else { continue }
            let blocked = member.blocked || !member.approved
            if users[index].role != member.kksuRole || users[index].isBlocked != blocked {
                users[index].role = member.kksuRole
                users[index].isBlocked = blocked
                changed = true
            }
        }
        if changed { db.users = users }
    }

    /// Учебный контент из демо-набора без демо-пользователей и их личных данных.
    func importStarterContent() {
        let seed = KKSUSeed.makeDatabase()
        let seedBilling = KKSUBillingSeed.make(db: seed)
        func add<T: Identifiable>(_ items: [T], to path: WritableKeyPath<KKSUDatabase, [T]>) where T.ID == UUID {
            let existing = Set(db[keyPath: path].map(\.id))
            db[keyPath: path] += items.filter { !existing.contains($0.id) }
        }
        add(seed.programs, to: \.programs)
        add(seed.library, to: \.library)
        add(seed.tests.map { var t = $0; t.authorID = currentUser?.id; return t }, to: \.tests)
        add(seed.teacherCourses.map { var c = $0; c.enrolledIDs = []; c.completedIDs = []; c.completedModules = [:]; return c }, to: \.teacherCourses)
        add(seed.methodologies, to: \.methodologies)
        add(seed.globalClasses.map { var g = $0; g.participantIDs = []; return g }, to: \.globalClasses)
        add(seed.internationalExperts, to: \.internationalExperts)
        add(seed.engineeringCourses.map { var e = $0; e.enrolledIDs = []; return e }, to: \.engineeringCourses)
        add(seed.challenges.map { var c = $0; c.completedIDs = []; return c }, to: \.challenges)
        add(seed.partners, to: \.partners)
        add(seed.internships, to: \.internships)
        add(seed.events, to: \.events)
        let existingProducts = Set(billing.products.map(\.id))
        billing.products += seedBilling.products.filter { !existingProducts.contains($0.id) && $0.kind != .marketplaceCourse }
        let existingCodes = Set(billing.promoCodes.map { $0.code })
        billing.promoCodes += seedBilling.promoCodes.filter { !existingCodes.contains($0.code) }
    }
}
