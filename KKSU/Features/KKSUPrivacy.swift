//
//  KKSUPrivacy.swift
//  KKSU Online
//
//  Политика конфиденциальности, условия использования, права на данные:
//  выгрузка своих данных и удаление аккаунта (требование App Store 5.1.1(v)),
//  согласие родителя при регистрации несовершеннолетних.
//
//  Тексты — шаблон. Перед публикацией их должен проверить юрист: закон РК
//  «О персональных данных и их защите», для пользователей из США — COPPA,
//  из ЕС — GDPR.
//

import SwiftUI

enum KKSULegal {
    static let operatorName = "KKSU — Comfort School-University"
    static let contactEmail = "privacy@kksu.kz"
    static let updated = "25.09.2026"

    static let privacySections: [(String, String)] = [
        ("Кто обрабатывает данные",
         "Оператор персональных данных — \(operatorName). По вопросам данных пишите на \(contactEmail)."),
        ("Какие данные мы собираем",
         "Имя, email, телефон, роль на платформе; для учеников — класс, интересы, цели, учебные работы, оценки, посещаемость, проекты. Сведения об особых образовательных потребностях и анкета поступления заполняются только с согласия родителя. Платёжные данные карт мы не получаем и не храним: оплата идёт через App Store или банк плательщика."),
        ("Зачем",
         "Для обучения: расписание, задания, оценки, обратная связь, индивидуальная траектория и рекомендации; для связи педагогов, учеников и родителей; для выдачи сертификатов и учёта оплат."),
        ("Дети",
         "Аккаунт ученика младше 18 лет создаётся с согласия родителя или законного представителя. Родитель видит успеваемость ребёнка, может подписать или отозвать согласия, выгрузить или удалить данные ребёнка. Мы не показываем детям рекламу и не передаём их данные рекламным сетям."),
        ("Кто видит данные",
         "Ученик — свои данные. Родитель — данные своих детей. Педагоги, психолог и наставник — данные своих учеников в объёме, нужном для работы; психолог — только при согласии родителя. Администратор — для управления платформой."),
        ("AI-помощник",
         "Вопросы AI-помощнику отправляются в AI-сервис только если администратор подключил AI-шлюз и родитель дал согласие на использование AI. Без этого помощник работает на устройстве."),
        ("Хранение и защита",
         "Данные хранятся на устройстве и, при подключении сервера KKSU, на защищённом сервере с шифрованием соединения. Каждый пользователь получает доступ только к своим данным по правилам ролей."),
        ("Ваши права",
         "Вы можете в любой момент выгрузить свои данные, исправить их, отозвать согласия и удалить аккаунт в разделе «Профиль → Мои данные и конфиденциальность»."),
        ("Отслеживание",
         "Приложение не отслеживает пользователей в других приложениях и на сайтах и не использует рекламные идентификаторы.")
    ]

    static let termsSections: [(String, String)] = [
        ("Регистрация", "Регистрация и подача заявки бесплатны. Ученик младше 18 лет регистрируется с согласия родителя."),
        ("Платные услуги", "Цифровые курсы, программы и подписки в iOS-приложении оплачиваются через App Store. Конференции, конкурсы и очные услуги могут оплачиваться переводом по реквизитам KKSU."),
        ("Подписки", "Подписка продлевается автоматически, пока вы не отмените её в настройках Apple ID не позднее чем за 24 часа до конца периода."),
        ("Возвраты", "Возврат покупок App Store оформляется через Apple (reportaproblem.apple.com). Возврат оплат переводом — по запросу в приложении в течение срока, указанного в настройках оплаты."),
        ("Поведение", "Запрещены оскорбления, травля, публикация чужих персональных данных и материалов, нарушающих права других людей. Администратор может заблокировать аккаунт за нарушения."),
        ("Материалы", "Педагоги, размещающие курсы, подтверждают, что имеют права на материалы. Проекты учеников остаются собственностью их авторов.")
    ]
}

struct LegalDocumentView: View {
    let title: String
    let sections: [(String, String)]

    var body: some View {
        KPage(title) {
            Text("Обновлено \(KKSULegal.updated)").font(.caption).foregroundStyle(.secondary)
            ForEach(sections, id: \.0) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.0).font(.headline)
                    Text(section.1).font(.callout)
                }
            }
            Text("Вопросы: \(KKSULegal.contactEmail)").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View { LegalDocumentView(title: "Политика конфиденциальности", sections: KKSULegal.privacySections) }
}

struct TermsOfUseView: View {
    var body: some View { LegalDocumentView(title: "Условия использования", sections: KKSULegal.termsSections) }
}

// MARK: - Мои данные: выгрузка и удаление аккаунта

struct MyDataView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var exportURL: URL?
    @State private var confirmDelete = false
    @State private var deleteChildID: UUID?

    var body: some View {
        List {
            Section {
                NavigationLink("Политика конфиденциальности") { PrivacyPolicyView() }
                NavigationLink("Условия использования") { TermsOfUseView() }
                if store.role == .parent || store.role == .admin {
                    RouteRow(route: .consents, subtitle: "Подписать или отозвать согласия")
                }
            }
            Section {
                Button {
                    exportURL = store.currentUser.flatMap { store.exportData(for: $0.id) }
                } label: {
                    Label("Выгрузить мои данные (JSON)", systemImage: "square.and.arrow.down")
                }
                if let exportURL {
                    ShareLink(item: exportURL) { Label("Сохранить или отправить файл", systemImage: "square.and.arrow.up") }
                }
            } header: {
                Text("Мои данные")
            } footer: {
                Text("Файл содержит ваш профиль, учебные работы, оценки, сообщения, сертификаты и платежи.")
            }
            if store.role == .parent, let me = store.currentUser {
                Section("Данные детей") {
                    ForEach(store.db.users.filter { me.linkedStudentIDs.contains($0.id) }) { child in
                        HStack {
                            Text(child.fullName)
                            Spacer()
                            if let url = store.exportData(for: child.id) {
                                ShareLink(item: url) { Image(systemName: "square.and.arrow.down") }
                            }
                            Button(role: .destructive) { deleteChildID = child.id } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }
            Section {
                Button("Удалить аккаунт", role: .destructive) { confirmDelete = true }
            } footer: {
                Text("Аккаунт и связанные с ним данные будут удалены без возможности восстановления. Записи об оплатах хранятся обезличенно, как требует бухгалтерский учёт. Активные подписки App Store отменяются в настройках Apple ID.")
            }
        }
        .navigationTitle("Данные и конфиденциальность")
        .confirmationDialog("Удалить аккаунт навсегда?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let id = store.currentUser?.id { store.deleteAccount(id) }
            }
        }
        .confirmationDialog("Удалить аккаунт ребёнка и все его данные?", isPresented: Binding(get: { deleteChildID != nil }, set: { if !$0 { deleteChildID = nil } }), titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let id = deleteChildID { store.deleteAccount(id) }
                deleteChildID = nil
            }
        }
    }
}

// MARK: - Логика данных

private struct UserDataExport: Encodable {
    let exportedAt: Date
    let user: ExportedUser
    let profile: StudentProfile?
    let questionnaires: [IntakeQuestionnaire]
    let consents: [ParentConsent]
    let submissions: [Submission]
    let attempts: [TestAttempt]
    let portfolio: [PortfolioItem]
    let achievements: [Achievement]
    let certificates: [Certificate]
    let messages: [ChatMessage]
    let history: [HistoryEntry]
    let projects: [InventionProject]
    let invoices: [Invoice]
    let entitlements: [Entitlement]
}

private struct ExportedUser: Encodable {
    let id: UUID
    let fullName: String
    let email: String
    let phone: String
    let role: KKSURole
    let createdAt: Date
}

extension KKSUStore {
    /// Выгрузка всех данных пользователя в JSON-файл (право на доступ к своим данным).
    func exportData(for userID: UUID) -> URL? {
        guard let user = user(userID) else { return nil }
        let export = UserDataExport(
            exportedAt: Date(),
            user: ExportedUser(id: user.id, fullName: user.fullName, email: user.email, phone: user.phone, role: user.role, createdAt: user.createdAt),
            profile: profile(for: userID),
            questionnaires: db.questionnaires.filter { $0.studentID == userID },
            consents: db.consents.filter { $0.studentID == userID || $0.parentID == userID },
            submissions: db.submissions.filter { $0.studentID == userID },
            attempts: db.attempts.filter { $0.userID == userID },
            portfolio: db.portfolio.filter { $0.studentID == userID },
            achievements: db.achievements.filter { $0.userID == userID },
            certificates: db.certificates.filter { $0.userID == userID },
            messages: db.messages.filter { $0.senderID == userID },
            history: db.history.filter { $0.userID == userID },
            projects: db.projects.filter { $0.authorIDs.contains(userID) },
            invoices: billing.invoices.filter { $0.payerID == userID || $0.beneficiaryIDs.contains(userID) },
            entitlements: billing.entitlements.filter { $0.userID == userID })
        let encoder = JSONEncoder.kksu
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(export) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KKSU-data-\(user.firstName).json")
        return (try? data.write(to: url)) != nil ? url : nil
    }

    /// Удаление аккаунта и персональных данных. Платежи остаются обезличенными.
    func deleteAccount(_ userID: UUID) {
        let isSelf = userID == db.currentUserID
        db.users.removeAll { $0.id == userID }
        for index in db.users.indices {
            db.users[index].linkedStudentIDs.removeAll { $0 == userID }
        }
        db.studentProfiles.removeAll { $0.userID == userID }
        db.questionnaires.removeAll { $0.studentID == userID }
        db.consents.removeAll { $0.studentID == userID || $0.parentID == userID }
        db.trajectory.removeAll { $0.studentID == userID }
        db.studyPlan.removeAll { $0.studentID == userID }
        db.calendarNotes.removeAll { $0.userID == userID }
        db.submissions.removeAll { $0.studentID == userID }
        db.portfolio.removeAll { $0.studentID == userID }
        db.achievements.removeAll { $0.userID == userID }
        db.certificates.removeAll { $0.userID == userID }
        db.history.removeAll { $0.userID == userID }
        db.attempts.removeAll { $0.userID == userID }
        db.notifications.removeAll { $0.userID == userID }
        db.messages.removeAll { $0.senderID == userID }
        db.threads.removeAll { $0.participantIDs.contains(userID) }
        db.academyProfiles.removeAll { $0.userID == userID }
        db.internshipApplications.removeAll { $0.studentID == userID }
        db.eventRegistrations.removeAll { $0.userID == userID }
        db.yiApplications.removeAll { $0.applicantID == userID }
        db.accessibility[userID] = nil
        db.preferences[userID] = nil
        db.aiChats[userID] = nil
        db.viewedLibraryIDs[userID] = nil
        for index in db.projects.indices {
            db.projects[index].authorIDs.removeAll { $0 == userID }
            if db.projects[index].mentorID == userID { db.projects[index].mentorID = nil }
        }
        for index in db.teams.indices {
            db.teams[index].memberIDs.removeAll { $0 == userID }
        }
        for index in db.sessions.indices {
            db.sessions[index].participantIDs.removeAll { $0 == userID }
            db.sessions[index].attendedIDs.removeAll { $0 == userID }
        }
        billing.entitlements.removeAll { $0.userID == userID }
        billing.marketplaceCourses.removeAll { $0.teacherID == userID }
        if isSelf { db.currentUserID = nil }
    }
}
