//
//  KKSUStore.swift
//  KKSU Online
//
//  Единое хранилище платформы: база данных, авторизация, бизнес-логика
//  (оценивание, автопроверка тестов, сертификаты, уведомления, стадии проектов).
//  Данные сохраняются в Documents/kksu-database.json.
//

import Foundation
import CryptoKit
import SwiftUI
import UserNotifications

struct KKSUDatabase: Codable {
    var users: [KKSUUser] = []
    var studentProfiles: [StudentProfile] = []
    var questionnaires: [IntakeQuestionnaire] = []
    var applications: [EnrollmentApplication] = []
    var consents: [ParentConsent] = []
    var programs: [EducationProgram] = []
    var trajectory: [TrajectoryStep] = []
    var studyPlan: [StudyPlanItem] = []
    var sessions: [ScheduleSession] = []
    var calendarNotes: [CalendarNote] = []
    var assignments: [Assignment] = []
    var submissions: [Submission] = []
    var portfolio: [PortfolioItem] = []
    var achievements: [Achievement] = []
    var certificates: [Certificate] = []
    var history: [HistoryEntry] = []
    var library: [LibraryItem] = []
    var tests: [KKSUTest] = []
    var attempts: [TestAttempt] = []
    var threads: [ChatThread] = []
    var messages: [ChatMessage] = []
    var notifications: [KKSUNotification] = []
    var academyProfiles: [TeacherAcademyProfile] = []
    var teacherCourses: [TeacherCourse] = []
    var methodologies: [Methodology] = []
    var pilots: [MethodologyPilot] = []
    var reviews: [ExpertReview] = []
    var projects: [InventionProject] = []
    var teams: [ProjectTeam] = []
    var experiments: [ExperimentEntry] = []
    var notebook: [LabNotebookPage] = []
    var yiApplications: [YoungInventorsApplication] = []
    var globalClasses: [GlobalClass] = []
    var internationalProjects: [InternationalProject] = []
    var internationalExperts: [InternationalExpert] = []
    var engineeringCourses: [EngineeringCourse] = []
    var challenges: [EngineeringChallenge] = []
    var partners: [Partner] = []
    var internships: [Internship] = []
    var internshipApplications: [InternshipApplication] = []
    var events: [KKSUEvent] = []
    var eventRegistrations: [EventRegistration] = []
    var accessibility: [UUID: AccessibilitySettings] = [:]
    var preferences: [UUID: LearningPreferences] = [:]
    var aiChats: [UUID: [AIChatMessage]] = [:]
    var viewedLibraryIDs: [UUID: [UUID]] = [:]
    var currentUserID: UUID?
}

enum KKSUAuthError: LocalizedError {
    case emptyFields, invalidEmail, weakPassword, emailTaken, wrongCredentials, blocked, wrongRole(KKSURole), invalidCode, userNotFound

    var errorDescription: String? {
        switch self {
        case .emptyFields: return "Заполните все обязательные поля."
        case .invalidEmail: return "Введите корректный email."
        case .weakPassword: return "Пароль должен быть не короче 8 символов и содержать цифру."
        case .emailTaken: return "Пользователь с таким email уже зарегистрирован."
        case .wrongCredentials: return "Неверный email или пароль."
        case .blocked: return "Аккаунт заблокирован. Обратитесь к администратору."
        case .wrongRole(let role): return "Этот аккаунт зарегистрирован с ролью «\(role.title)». Выберите её."
        case .invalidCode: return "Код восстановления неверный или устарел."
        case .userNotFound: return "Пользователь с таким email не найден."
        }
    }
}

@MainActor
final class KKSUStore: ObservableObject {

    @Published var db: KKSUDatabase {
        didSet { scheduleSave() }
    }

    /// Платежи, продукты и доступы хранятся отдельным файлом (см. KKSUBilling.swift).
    @Published var billing: KKSUBillingDatabase {
        didSet { scheduleSave() }
    }

    private let fileURL: URL
    private let billingURL: URL
    private let persists: Bool
    private var saveTask: Task<Void, Never>?

    init(inMemory: Bool = false) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("kksu-database.json")
        billingURL = docs.appendingPathComponent("kksu-billing.json")
        persists = !inMemory

        let database: KKSUDatabase
        if !inMemory,
           let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder.kksu.decode(KKSUDatabase.self, from: data) {
            database = loaded
        } else {
            database = KKSUSeed.makeDatabase()
        }
        db = database

        if !inMemory,
           let data = try? Data(contentsOf: billingURL),
           let loaded = try? JSONDecoder.kksu.decode(KKSUBillingDatabase.self, from: data) {
            billing = loaded
        } else {
            billing = KKSUBillingSeed.make(db: database)
        }
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        guard persists else { return }
        do {
            let data = try JSONEncoder.kksu.encode(db)
            try data.write(to: fileURL, options: .atomic)
            let billingData = try JSONEncoder.kksu.encode(billing)
            try billingData.write(to: billingURL, options: .atomic)
            KKSUCloud.shared.scheduleSync()
        } catch {
            print("KKSU: не удалось сохранить базу — \(error)")
        }
    }

    func resetDemoData() {
        let current = db.currentUserID
        db = KKSUSeed.makeDatabase()
        billing = KKSUBillingSeed.make(db: db)
        if let current, db.users.contains(where: { $0.id == current }) { db.currentUserID = current }
    }

    // MARK: - Авторизация (задачи 2, 3, 4)

    var currentUser: KKSUUser? {
        guard let id = db.currentUserID else { return nil }
        return db.users.first { $0.id == id }
    }

    var role: KKSURole { currentUser?.role ?? .student }

    nonisolated static func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".") && !parts[0].isEmpty
    }

    nonisolated static func isStrongPassword(_ password: String) -> Bool {
        password.count >= 8 && password.contains(where: \.isNumber)
    }

    @discardableResult
    func register(fullName: String, email: String, phone: String, password: String, role: KKSURole) throws -> KKSUUser {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let name = fullName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else { throw KKSUAuthError.emptyFields }
        guard Self.isValidEmail(email) else { throw KKSUAuthError.invalidEmail }
        guard Self.isStrongPassword(password) else { throw KKSUAuthError.weakPassword }
        guard !db.users.contains(where: { $0.email == email }) else { throw KKSUAuthError.emailTaken }

        let salt = UUID().uuidString
        let user = KKSUUser(fullName: name, email: email, phone: phone, role: role,
                            passwordHash: Self.hash(password, salt: salt), salt: salt)
        db.users.append(user)
        if role == .student {
            db.studentProfiles.append(StudentProfile(userID: user.id))
        }
        log(user.id, "Регистрация на платформе", details: role.title, icon: "person.badge.plus")
        notify(user.id, "Добро пожаловать в KKSU Online!", "Заполните профиль, чтобы получить персональные рекомендации.", kind: .system)
        db.currentUserID = user.id
        return user
    }

    func login(email: String, password: String, expectedRole: KKSURole? = nil) throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !email.isEmpty, !password.isEmpty else { throw KKSUAuthError.emptyFields }
        guard let index = db.users.firstIndex(where: { $0.email == email }),
              db.users[index].passwordHash == Self.hash(password, salt: db.users[index].salt) else {
            throw KKSUAuthError.wrongCredentials
        }
        let user = db.users[index]
        guard !user.isBlocked else { throw KKSUAuthError.blocked }
        if let expectedRole, expectedRole != user.role { throw KKSUAuthError.wrongRole(user.role) }
        db.users[index].lastLogin = Date()
        db.currentUserID = user.id
        log(user.id, "Вход в систему", icon: "arrow.right.circle")
        requestNotificationPermission()
    }

    func logout() {
        db.currentUserID = nil
        Task { await KKSUCloud.shared.signOut() }
    }

    /// Генерирует одноразовый код восстановления (действует 15 минут).
    /// В продакшене код отправляется на email через сервер; в прототипе — во входящие уведомления.
    @discardableResult
    func requestPasswordReset(email: String) throws -> String {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard let index = db.users.firstIndex(where: { $0.email == email }) else { throw KKSUAuthError.userNotFound }
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        db.users[index].recoveryCode = Self.hash(code, salt: db.users[index].salt)
        db.users[index].recoveryExpires = Date().addingTimeInterval(15 * 60)
        notify(db.users[index].id, "Восстановление пароля", "Код для сброса пароля: \(code)", kind: .system)
        return code
    }

    func resetPassword(email: String, code: String, newPassword: String) throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard let index = db.users.firstIndex(where: { $0.email == email }) else { throw KKSUAuthError.userNotFound }
        let user = db.users[index]
        guard let stored = user.recoveryCode, let expires = user.recoveryExpires, expires > Date(),
              stored == Self.hash(code.trimmingCharacters(in: .whitespaces), salt: user.salt) else {
            throw KKSUAuthError.invalidCode
        }
        guard Self.isStrongPassword(newPassword) else { throw KKSUAuthError.weakPassword }
        let salt = UUID().uuidString
        db.users[index].salt = salt
        db.users[index].passwordHash = Self.hash(newPassword, salt: salt)
        db.users[index].recoveryCode = nil
        db.users[index].recoveryExpires = nil
        log(user.id, "Пароль изменён", icon: "key.fill")
    }

    // MARK: - Поиск

    func user(_ id: UUID?) -> KKSUUser? {
        guard let id else { return nil }
        return db.users.first { $0.id == id }
    }

    func userName(_ id: UUID?) -> String { user(id)?.fullName ?? "—" }

    func users(with role: KKSURole) -> [KKSUUser] {
        db.users.filter { $0.role == role }
    }

    var students: [KKSUUser] { users(with: .student) }

    func profile(for userID: UUID) -> StudentProfile? {
        db.studentProfiles.first { $0.userID == userID }
    }

    func program(_ id: UUID?) -> EducationProgram? {
        guard let id else { return nil }
        return db.programs.first { $0.id == id }
    }

    func project(_ id: UUID) -> InventionProject? { db.projects.first { $0.id == id } }

    func partner(_ id: UUID?) -> Partner? {
        guard let id else { return nil }
        return db.partners.first { $0.id == id }
    }

    /// Ученики, доступные текущему пользователю (дети родителя, подопечные наставника, все — для педагогов).
    var visibleStudents: [KKSUUser] {
        guard let user = currentUser else { return [] }
        switch user.role {
        case .student: return [user]
        case .parent, .mentor:
            let linked = students.filter { user.linkedStudentIDs.contains($0.id) }
            return linked.isEmpty && user.role == .mentor ? students : linked
        case .partner: return []
        default: return students
        }
    }

    // MARK: - Настройки (задачи 73, 74, 77)

    var accessibility: AccessibilitySettings {
        get { db.currentUserID.flatMap { db.accessibility[$0] } ?? AccessibilitySettings() }
        set { if let id = db.currentUserID { db.accessibility[id] = newValue } }
    }

    func preferences(for userID: UUID) -> LearningPreferences {
        db.preferences[userID] ?? LearningPreferences()
    }

    var currentPreferences: LearningPreferences {
        get { db.currentUserID.map { preferences(for: $0) } ?? LearningPreferences() }
        set { if let id = db.currentUserID { db.preferences[id] = newValue } }
    }

    // MARK: - История и уведомления (задачи 25, 35)

    func log(_ userID: UUID, _ action: String, details: String = "", icon: String = "clock") {
        db.history.append(HistoryEntry(userID: userID, action: action, details: details, icon: icon))
    }

    func notify(_ userID: UUID, _ title: String, _ body: String, kind: NotificationKind = .info) {
        db.notifications.append(KKSUNotification(userID: userID, title: title, body: body, kind: kind))
    }

    var myNotifications: [KKSUNotification] {
        guard let id = db.currentUserID else { return [] }
        return db.notifications.filter { $0.userID == id }.sorted { $0.date > $1.date }
    }

    var unreadCount: Int { myNotifications.filter { !$0.isRead }.count }

    func markAllRead() {
        guard let id = db.currentUserID else { return }
        for index in db.notifications.indices where db.notifications[index].userID == id {
            db.notifications[index].isRead = true
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Системное напоминание о дедлайне за сутки (задача 36).
    func scheduleDeadlineReminder(for assignment: Assignment) {
        let fireDate = assignment.dueDate.addingTimeInterval(-24 * 3600)
        guard fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Дедлайн завтра"
        content.body = "«\(assignment.title)» — сдать до \(assignment.dueDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "deadline-\(assignment.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Задания и оценивание (задачи 19, 20, 21, 36)

    /// Задания, видимые ученику: только одобренные педагогом.
    func assignments(for studentID: UUID) -> [Assignment] {
        db.assignments.filter {
            $0.audience == .students && $0.approvedByTeacher &&
            ($0.assignedIDs.isEmpty || $0.assignedIDs.contains(studentID))
        }.sorted { $0.dueDate < $1.dueDate }
    }

    func submission(for assignmentID: UUID, studentID: UUID) -> Submission? {
        db.submissions.filter { $0.assignmentID == assignmentID && $0.studentID == studentID }
            .max { $0.submittedAt < $1.submittedAt }
    }

    func publish(_ assignment: Assignment) {
        db.assignments.append(assignment)
        guard assignment.approvedByTeacher else { return }
        announce(assignment)
    }

    private func announce(_ assignment: Assignment) {
        let targets = assignment.assignedIDs.isEmpty ? students.map(\.id) : assignment.assignedIDs
        for id in targets {
            notify(id, "Новое задание: \(assignment.title)", "Срок сдачи: \(assignment.dueDate.formatted(date: .abbreviated, time: .shortened))", kind: .deadline)
        }
        scheduleDeadlineReminder(for: assignment)
    }

    /// Педагог утверждает задание, сгенерированное AI (задача 81).
    func approveAIAssignment(_ id: UUID) {
        guard let index = db.assignments.firstIndex(where: { $0.id == id }) else { return }
        db.assignments[index].approvedByTeacher = true
        db.assignments[index].teacherID = db.currentUserID
        announce(db.assignments[index])
    }

    func submitWork(assignmentID: UUID, studentID: UUID, text: String, attachments: [Attachment]) {
        db.submissions.append(Submission(assignmentID: assignmentID, studentID: studentID, text: text, attachments: attachments))
        let assignment = db.assignments.first { $0.id == assignmentID }
        log(studentID, "Сдана работа", details: assignment?.title ?? "", icon: "tray.and.arrow.up.fill")
        if let teacher = assignment?.teacherID {
            notify(teacher, "Новая работа на проверку", "\(userName(studentID)): \(assignment?.title ?? "")", kind: .info)
        }
        checkAchievements(for: studentID)
    }

    func grade(submissionID: UUID, score: Int, feedback: String, returnForRevision: Bool = false) {
        guard let index = db.submissions.firstIndex(where: { $0.id == submissionID }) else { return }
        db.submissions[index].score = score
        db.submissions[index].feedback = feedback
        db.submissions[index].gradedAt = Date()
        db.submissions[index].gradedBy = db.currentUserID
        db.submissions[index].status = returnForRevision ? .returned : .graded
        let sub = db.submissions[index]
        let title = db.assignments.first { $0.id == sub.assignmentID }?.title ?? "Задание"
        notify(sub.studentID, returnForRevision ? "Работа возвращена на доработку" : "Работа оценена",
               "\(title): \(score) балл(ов). \(feedback)", kind: .grade)
        for parent in db.users where parent.role == .parent && parent.linkedStudentIDs.contains(sub.studentID) {
            notify(parent.id, "Новая оценка ребёнка", "\(userName(sub.studentID)) — \(title): \(score)", kind: .grade)
        }
        log(sub.studentID, "Получена оценка", details: "\(title): \(score)", icon: "star.fill")
        if let pIndex = db.studentProfiles.firstIndex(where: { $0.userID == sub.studentID }) {
            db.studentProfiles[pIndex].xp += score * 10
        }
        checkAchievements(for: sub.studentID)
    }

    // MARK: - Автопроверка тестов (задача 30)

    static func evaluate(_ question: TestQuestion, answer: TestAnswer?) -> Bool {
        guard let answer else { return false }
        switch question.kind {
        case .single, .multiple:
            return Set(answer.selected) == Set(question.correctIndices) && !answer.selected.isEmpty
        case .number:
            let normalize: (String) -> Double? = { Double($0.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) }
            guard let given = normalize(answer.text), let correct = normalize(question.correctText) else { return false }
            return abs(given - correct) < 0.0001
        case .text:
            let clean: (String) -> String = { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "ё", with: "е") }
            let variants = question.correctText.split(separator: "|").map { clean(String($0)) }
            return variants.contains(clean(answer.text))
        }
    }

    @discardableResult
    func submitTest(_ test: KKSUTest, answers: [TestAnswer], userID: UUID) -> TestAttempt {
        var score = 0
        for question in test.questions where Self.evaluate(question, answer: answers.first { $0.questionID == question.id }) {
            score += question.points
        }
        let maxScore = test.maxScore
        let passed = maxScore > 0 && Double(score) / Double(maxScore) * 100 >= Double(test.passingPercent)
        let attempt = TestAttempt(testID: test.id, userID: userID, answers: answers, score: score, maxScore: maxScore, passed: passed)
        db.attempts.append(attempt)
        log(userID, "Пройден тест", details: "\(test.title): \(attempt.percent)%", icon: "checklist")
        notify(userID, passed ? "Тест сдан" : "Тест не сдан", "\(test.title): \(score) из \(maxScore)", kind: .grade)
        checkAchievements(for: userID)
        return attempt
    }

    // MARK: - Достижения и сертификаты (задачи 23, 42, 99)

    func award(_ userID: UUID, _ title: String, icon: String, points: Int) {
        guard !db.achievements.contains(where: { $0.userID == userID && $0.title == title }) else { return }
        db.achievements.append(Achievement(userID: userID, title: title, icon: icon, points: points))
        notify(userID, "Новое достижение!", title, kind: .info)
    }

    func checkAchievements(for userID: UUID) {
        let subs = db.submissions.filter { $0.studentID == userID }
        let graded = subs.compactMap(\.score)
        if subs.count >= 1 { award(userID, "Первая сданная работа", icon: "tray.and.arrow.up.fill", points: 10) }
        if subs.count >= 10 { award(userID, "10 сданных работ", icon: "trophy.fill", points: 50) }
        if graded.contains(where: { $0 >= 10 }) { award(userID, "Высший балл", icon: "star.fill", points: 30) }
        let passedTests = db.attempts.filter { $0.userID == userID && $0.passed }
        if passedTests.count >= 1 { award(userID, "Первый сданный тест", icon: "checkmark.seal.fill", points: 15) }
        if passedTests.contains(where: { $0.percent == 100 }) { award(userID, "Тест на 100%", icon: "rosette", points: 40) }
        if db.projects.contains(where: { $0.authorIDs.contains(userID) && $0.stage == .result }) {
            award(userID, "Проект доведён до результата", icon: "flag.checkered", points: 100)
        }
    }

    @discardableResult
    func issueCertificate(to userID: UUID, title: String, issuer: CertificateIssuer, hours: Int? = nil) -> Certificate {
        if let existing = db.certificates.first(where: { $0.userID == userID && $0.title == title && $0.issuer == issuer }) {
            return existing
        }
        let year = Calendar.current.component(.year, from: Date())
        let serial = "\(year)-\(String(format: "%05d", db.certificates.count + 1))-\(UUID().uuidString.prefix(4))"
        let cert = Certificate(userID: userID, recipientName: userName(userID), title: title, issuer: issuer, serial: serial, hours: hours)
        db.certificates.append(cert)
        notify(userID, "Выдан сертификат", "\(issuer.title): \(title)", kind: .info)
        log(userID, "Получен сертификат", details: title, icon: "doc.badge.ellipsis")
        return cert
    }

    // MARK: - Teacher Academy (задачи 38, 39, 42)

    func enroll(inTeacherCourse id: UUID) {
        guard let user = currentUser, let index = db.teacherCourses.firstIndex(where: { $0.id == id }) else { return }
        if !db.teacherCourses[index].enrolledIDs.contains(user.id) {
            db.teacherCourses[index].enrolledIDs.append(user.id)
            log(user.id, "Запись на курс повышения квалификации", details: db.teacherCourses[index].title, icon: "person.crop.rectangle.stack")
        }
    }

    func toggleModule(_ module: String, courseID: UUID) {
        guard let user = currentUser, let index = db.teacherCourses.firstIndex(where: { $0.id == courseID }) else { return }
        let key = user.id.uuidString
        var done = db.teacherCourses[index].completedModules[key] ?? []
        if let pos = done.firstIndex(of: module) { done.remove(at: pos) } else { done.append(module) }
        db.teacherCourses[index].completedModules[key] = done
        let course = db.teacherCourses[index]
        if Set(done).isSuperset(of: course.modules) && !course.completedIDs.contains(user.id) {
            db.teacherCourses[index].completedIDs.append(user.id)
            issueCertificate(to: user.id, title: "Курс «\(course.title)»", issuer: .teacherAcademy, hours: course.hours)
        }
    }

    // MARK: - Проекты (задачи 50–58)

    func advance(projectID: UUID, note: String) {
        guard let index = db.projects.firstIndex(where: { $0.id == projectID }),
              let next = db.projects[index].stage.next else { return }
        db.projects[index].stage = next
        db.projects[index].stageHistory.append(StageChange(stage: next, date: Date(), note: note))
        if next == .prototype || next == .testing { db.projects[index].isPrototype = true }
        let project = db.projects[index]
        for author in project.authorIDs {
            notify(author, "Проект перешёл на стадию \(next.title)", project.title, kind: .info)
            log(author, "Стадия проекта: \(next.title)", details: project.title, icon: next.icon)
            checkAchievements(for: author)
        }
    }

    func submitReview(_ review: ExpertReview) {
        db.reviews.append(review)
        switch review.target {
        case .methodology:
            if let index = db.methodologies.firstIndex(where: { $0.id == review.targetID }) {
                db.methodologies[index].status = review.decision == .approve ? .approved : .reviewed
            }
        case .youngInventors:
            if let index = db.yiApplications.firstIndex(where: { $0.id == review.targetID }) {
                let app = db.yiApplications[index]
                let all = db.reviews.filter { $0.targetID == app.id }
                let avg = all.map(\.average).reduce(0, +) / Double(max(all.count, 1))
                db.yiApplications[index].status = review.decision == .reject ? .rejected : (avg >= 8 ? .finalist : .underReview)
                notify(app.applicantID, "Экспертиза Young Inventors", "Статус заявки: \(db.yiApplications[index].status.title)", kind: .info)
            }
        case .project:
            if let project = project(review.targetID) {
                for author in project.authorIDs {
                    notify(author, "Экспертная оценка проекта", "\(project.title): \(String(format: "%.1f", review.average))/10", kind: .info)
                }
            }
        }
    }

    func reviews(for targetID: UUID) -> [ExpertReview] { db.reviews.filter { $0.targetID == targetID } }

    // MARK: - Мероприятия (задачи 98, 99)

    func register(eventID: UUID, role: EventRole, talk: String) {
        guard let user = currentUser,
              !db.eventRegistrations.contains(where: { $0.eventID == eventID && $0.userID == user.id }) else { return }
        db.eventRegistrations.append(EventRegistration(eventID: eventID, userID: user.id, role: role, talkTitle: talk))
        let title = db.events.first { $0.id == eventID }?.title ?? ""
        notify(user.id, "Регистрация подтверждена", title, kind: .event)
        log(user.id, "Регистрация на мероприятие", details: title, icon: "calendar.badge.plus")
    }

    func confirmAttendance(registrationID: UUID) {
        guard let index = db.eventRegistrations.firstIndex(where: { $0.id == registrationID }) else { return }
        db.eventRegistrations[index].attended = true
        let reg = db.eventRegistrations[index]
        guard let event = db.events.first(where: { $0.id == reg.eventID }) else { return }
        let cert = issueCertificate(to: reg.userID, title: "\(reg.role.title): «\(event.title)»", issuer: .conference, hours: event.hours)
        db.eventRegistrations[index].certificateID = cert.id
    }

    // MARK: - Сообщения (задача 34)

    func thread(with otherID: UUID) -> ChatThread {
        guard let me = db.currentUserID else { return ChatThread(participantIDs: [otherID], title: "") }
        if let existing = db.threads.first(where: { Set($0.participantIDs) == Set([me, otherID]) }) { return existing }
        let thread = ChatThread(participantIDs: [me, otherID], title: "")
        db.threads.append(thread)
        return thread
    }

    func send(_ text: String, in threadID: UUID) {
        guard let me = db.currentUserID, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        db.messages.append(ChatMessage(threadID: threadID, senderID: me, text: text, readBy: [me]))
        if let thread = db.threads.first(where: { $0.id == threadID }) {
            for other in thread.participantIDs where other != me {
                notify(other, "Сообщение от \(userName(me))", text, kind: .message)
            }
        }
    }

    // MARK: - Загрузка файлов (задачи 20, 49)

    static var uploadsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func storeFile(data: Data, fileName: String) -> Attachment? {
        let stored = "\(UUID().uuidString)-\(fileName)"
        do {
            try data.write(to: uploadsDirectory.appendingPathComponent(stored), options: .atomic)
            return Attachment(fileName: fileName, kind: .detect(fileName: fileName), sizeBytes: data.count, storedName: stored)
        } catch {
            return nil
        }
    }

    static func importFile(at url: URL) -> Attachment? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return storeFile(data: data, fileName: url.lastPathComponent)
    }

    static func fileURL(for attachment: Attachment) -> URL? {
        if let stored = attachment.storedName { return uploadsDirectory.appendingPathComponent(stored) }
        return attachment.remoteURL.flatMap(URL.init(string:))
    }
}

extension JSONEncoder {
    static var kksu: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var kksu: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
