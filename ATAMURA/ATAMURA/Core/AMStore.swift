//
//  AMStore.swift
//  ATA MURA
//
//  Единое хранилище платформы: база данных, вход, публикации, модерация,
//  баллы и уровни, курсы и заказы, Creator Studio и Morning Dashboard.
//  Данные сохраняются в Documents/atamura-database.json и (если подключён сервер)
//  синхронизируются с Supabase — см. AMCloud.swift.
//

import Foundation
import CryptoKit
import SwiftUI

struct AMDatabase: Codable {
    var users: [AMUser] = []
    var posts: [AMPost] = []
    var topics: [AMTopic] = []
    var comments: [AMComment] = []
    var likes: [AMLike] = []
    var reports: [AMReport] = []
    var places: [AMPlace] = []
    var projects: [AMProject] = []
    var forgottenIdeas: [AMForgottenIdea] = []
    var invites: [AMInvite] = []
    var museum: [AMMuseumItem] = []
    var kidsThemes: [AMKidsTheme] = []
    var kidsWorks: [AMKidsWork] = []
    var research: [AMResearchArticle] = []
    var notifications: [AMNotification] = []
    var news: [AMNews] = []
    var magazines: [AMMagazineIssue] = []
    var courses: [AMCourse] = []
    var enrollments: [AMEnrollment] = []
    var orders: [AMOrder] = []
    var products: [AMProduct] = []
    var contentItems: [AMContentItem] = []
    var ideas: [AMIdea] = []
    var vlog: [AMVlogEntry] = []
    var guests: [AMGuest] = []
    var series: [AMSeries] = []
    var media: [AMMediaAsset] = []
    var events: [AMEvent] = []
    var partners: [AMPartner] = []
    var tasks: [AMTask] = []
    var projectOfWeekId: UUID?
    var projectOfWeekDate: Date?

    init() {}

    // Новые поля в будущих версиях не ломают сохранённую базу.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func list<T: Decodable>(_ key: CodingKeys) -> [T] { (try? c.decodeIfPresent([T].self, forKey: key)) ?? [] }
        users = list(.users); posts = list(.posts); topics = list(.topics); comments = list(.comments)
        likes = list(.likes); reports = list(.reports); places = list(.places); projects = list(.projects)
        forgottenIdeas = list(.forgottenIdeas); invites = list(.invites); museum = list(.museum)
        kidsThemes = list(.kidsThemes); kidsWorks = list(.kidsWorks); research = list(.research)
        notifications = list(.notifications); news = list(.news); magazines = list(.magazines)
        courses = list(.courses); enrollments = list(.enrollments); orders = list(.orders)
        products = list(.products); contentItems = list(.contentItems); ideas = list(.ideas)
        vlog = list(.vlog); guests = list(.guests); series = list(.series); media = list(.media)
        events = list(.events); partners = list(.partners); tasks = list(.tasks)
        projectOfWeekId = try? c.decodeIfPresent(UUID.self, forKey: .projectOfWeekId)
        projectOfWeekDate = try? c.decodeIfPresent(Date.self, forKey: .projectOfWeekDate)
    }
}

enum AMAuthError: LocalizedError {
    case invalidEmail, weakPassword, emailTaken, wrongCredentials, blocked, emptyName

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return L("auth.error.email")
        case .weakPassword: return L("auth.error.password")
        case .emailTaken: return L("auth.error.taken")
        case .wrongCredentials: return L("auth.error.credentials")
        case .blocked: return L("auth.error.blocked")
        case .emptyName: return L("auth.error.name")
        }
    }
}

/// Элемент ленты «Сегодня в ATA MURA».
struct AMFeedItem: Identifiable {
    enum Kind { case news, magazine, post, project, course, research, museum, kids }
    let id: UUID
    let kind: Kind
    let label: String
    let title: String
    let subtitle: String
    let date: Date
    let pinned: Bool
}

/// Пункт Morning Dashboard.
struct AMMorningItem: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let section: AMAdminSection
}

enum AMAdminSection: String, CaseIterable, Identifiable {
    case dashboard, calendar, vlog, ideas, series, guests, news, magazine, courses, orders,
         moderation, posts, projects, museum, research, users, events, partners, marketplace, media, analytics, tasks, map

    var id: String { rawValue }
    var title: String { L("admin.\(rawValue)") }
    var icon: String {
        switch self {
        case .dashboard: return "sun.horizon.fill"
        case .calendar: return "calendar"
        case .vlog: return "video.badge.waveform"
        case .ideas: return "lightbulb.fill"
        case .series: return "rectangle.stack.fill"
        case .guests: return "person.crop.rectangle.stack"
        case .news: return "newspaper.fill"
        case .magazine: return "magazine.fill"
        case .courses: return "graduationcap.fill"
        case .orders: return "creditcard.fill"
        case .moderation: return "checkmark.shield.fill"
        case .posts: return "text.bubble.fill"
        case .projects: return "lightbulb.max.fill"
        case .museum: return "building.columns.fill"
        case .research: return "doc.text.magnifyingglass"
        case .users: return "person.3.fill"
        case .events: return "calendar.badge.clock"
        case .partners: return "hand.raised.fill"
        case .marketplace: return "cart.fill"
        case .media: return "photo.stack.fill"
        case .analytics: return "chart.bar.xaxis"
        case .tasks: return "checklist"
        case .map: return "map.fill"
        }
    }
}

@MainActor
final class AMStore: ObservableObject {
    @Published var db = AMDatabase() {
        didSet { scheduleSave() }
    }
    @Published private(set) var currentUserId: UUID? {
        didSet { UserDefaults.standard.set(currentUserId?.uuidString, forKey: "atamura.currentUser") }
    }
    @Published var language: AMLanguage = AMLanguage.current {
        didSet {
            AMLanguage.current = language
            UserDefaults.standard.set(language.rawValue, forKey: "atamura.language")
        }
    }
    @Published var inclusiveMode: AMInclusiveMode {
        didSet { UserDefaults.standard.set(inclusiveMode.rawValue, forKey: "atamura.inclusive") }
    }
    @Published var aiChat: [AMChatMessage] = []
    /// Устройство уже работает с сервером (демо-данные убраны).
    @Published private(set) var cloudMode: Bool {
        didSet { UserDefaults.standard.set(cloudMode, forKey: "atamura.cloudMode") }
    }

    private var saveTask: Task<Void, Never>?
    private let fileURL: URL = {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return folder.appendingPathComponent("atamura-database.json")
    }()

    init() {
        inclusiveMode = AMInclusiveMode(rawValue: UserDefaults.standard.string(forKey: "atamura.inclusive") ?? "") ?? .standard
        cloudMode = UserDefaults.standard.bool(forKey: "atamura.cloudMode")
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder.am.decode(AMDatabase.self, from: data) {
            db = saved
        } else {
            db = AMSeed.database()
        }
        if let saved = UserDefaults.standard.string(forKey: "atamura.currentUser"), let id = UUID(uuidString: saved),
           db.users.contains(where: { $0.id == id }) {
            currentUserId = id
        }
    }

    // MARK: - Сохранение

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
        AMCloud.shared.scheduleSync()
    }

    func saveNow() {
        guard let data = try? JSONEncoder.am.encode(db) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    // MARK: - Пользователь

    var currentUser: AMUser? {
        guard let currentUserId else { return nil }
        return db.users.first { $0.id == currentUserId }
    }
    var isStaff: Bool { currentUser?.role.isStaff ?? false }
    var isAdmin: Bool { currentUser?.role == .admin }

    func user(_ id: UUID?) -> AMUser? {
        guard let id else { return nil }
        return db.users.first { $0.id == id }
    }

    func updateCurrentUser(_ change: (inout AMUser) -> Void) {
        guard let index = db.users.firstIndex(where: { $0.id == currentUserId }) else { return }
        change(&db.users[index])
    }

    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".") && !parts[0].isEmpty
    }

    static func isStrongPassword(_ password: String) -> Bool {
        password.count >= 8 && password.contains(where: \.isNumber) && password.contains(where: \.isLetter)
    }

    static func hash(_ password: String, email: String) -> String {
        let digest = SHA256.hash(data: Data("atamura|\(email.lowercased())|\(password)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Локальная регистрация (без сервера). Первый пользователь на устройстве становится администратором.
    func register(fullName: String, email: String, password: String, city: String, region: AMRegion?, birthYear: Int?) throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let name = fullName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { throw AMAuthError.emptyName }
        guard Self.isValidEmail(email) else { throw AMAuthError.invalidEmail }
        guard Self.isStrongPassword(password) else { throw AMAuthError.weakPassword }
        guard !db.users.contains(where: { $0.email == email }) else { throw AMAuthError.emailTaken }
        let hasRealUsers = db.users.contains { !$0.passwordHash.isEmpty }
        var user = AMUser(fullName: name, email: email)
        user.passwordHash = Self.hash(password, email: email)
        user.role = hasRealUsers ? .member : .admin
        user.city = city
        user.region = region
        user.birthYear = birthYear
        db.users.append(user)
        currentUserId = user.id
        notify(user.id, title: L("notify.welcome.title"), body: L("notify.welcome.body"))
    }

    func login(email: String, password: String) throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard let user = db.users.first(where: { $0.email == email }),
              user.passwordHash == Self.hash(password, email: email) else { throw AMAuthError.wrongCredentials }
        guard !user.blocked else { throw AMAuthError.blocked }
        currentUserId = user.id
    }

    func logout() {
        saveNow()
        currentUserId = nil
        aiChat = []
        Task { await AMCloud.shared.signOut() }
    }

    /// Пользователь с сервера (после входа через Supabase).
    func adoptCloudUser(id: UUID, fullName: String, email: String, role: AMRole) {
        if let index = db.users.firstIndex(where: { $0.id == id }) {
            db.users[index].role = role
            db.users[index].email = email
            if db.users[index].fullName.isEmpty { db.users[index].fullName = fullName }
        } else {
            var user = AMUser(fullName: fullName, email: email)
            user.id = id
            user.role = role
            db.users.append(user)
        }
        currentUserId = id
    }

    func enterCloudMode() {
        guard !cloudMode else { return }
        cloudMode = true
        // Демо-пользователи и их материалы не попадают на сервер; справочники остаются.
        let seedUserIds = Set(db.users.filter { $0.passwordHash.isEmpty }.map(\.id))
        db.users.removeAll { seedUserIds.contains($0.id) }
        db.posts.removeAll { seedUserIds.contains($0.authorId) }
        db.projects.removeAll { seedUserIds.contains($0.ownerId) }
        db.museum.removeAll { seedUserIds.contains($0.ownerId) }
        db.kidsWorks.removeAll { seedUserIds.contains($0.ownerId) }
        db.research.removeAll { seedUserIds.contains($0.ownerId) }
        db.comments.removeAll { seedUserIds.contains($0.authorId) }
        db.likes.removeAll { seedUserIds.contains($0.userId) }
    }

    func deleteMyAccount() {
        guard let me = currentUserId else { return }
        db.posts.removeAll { $0.authorId == me }
        db.projects.removeAll { $0.ownerId == me }
        db.museum.removeAll { $0.ownerId == me }
        db.kidsWorks.removeAll { $0.ownerId == me }
        db.research.removeAll { $0.ownerId == me }
        db.comments.removeAll { $0.authorId == me }
        db.likes.removeAll { $0.userId == me }
        db.enrollments.removeAll { $0.userId == me }
        db.notifications.removeAll { $0.userId == me }
        db.invites.removeAll { $0.fromId == me || $0.toId == me }
        db.users.removeAll { $0.id == me }
        currentUserId = nil
        aiChat = []
        Task {
            try? await AMCloud.shared.deleteAccount()
        }
    }

    // MARK: - Уведомления и баллы

    func notify(_ userId: UUID, title: String, body: String) {
        db.notifications.append(AMNotification(userId: userId, title: title, body: body))
    }

    var myNotifications: [AMNotification] {
        db.notifications.filter { $0.userId == currentUserId }.sorted { $0.date > $1.date }
    }

    var unreadCount: Int { myNotifications.filter { !$0.read }.count }

    func markNotificationsRead() {
        for index in db.notifications.indices where db.notifications[index].userId == currentUserId {
            db.notifications[index].read = true
        }
    }

    /// Засчитывает квест один раз и начисляет баллы.
    func complete(quest id: String, for userId: UUID? = nil) {
        guard let quest = AMQuest.all.first(where: { $0.id == id }),
              let index = db.users.firstIndex(where: { $0.id == (userId ?? currentUserId) }),
              !db.users[index].completedQuests.contains(id) else { return }
        let oldLevel = db.users[index].level
        db.users[index].completedQuests.append(id)
        db.users[index].points += quest.points
        let user = db.users[index]
        notify(user.id, title: L("notify.quest.title", quest.points), body: quest.title)
        if user.level != oldLevel {
            notify(user.id, title: L("notify.level.title"), body: user.level.title)
        }
    }

    func addPoints(_ points: Int, to userId: UUID) {
        guard let index = db.users.firstIndex(where: { $0.id == userId }) else { return }
        db.users[index].points += points
    }

    // MARK: - Видимость контента

    /// Опубликованное видят все; на модерации — автор и редакция. Заблокированных авторов не показываем.
    func isVisible(status: AMModerationStatus, ownerId: UUID) -> Bool {
        if currentUser?.blockedUsers.contains(ownerId) == true { return false }
        return status == .approved || ownerId == currentUserId || isStaff
    }

    var visiblePosts: [AMPost] {
        db.posts.filter { isVisible(status: $0.status, ownerId: $0.authorId) }.sorted { $0.createdAt > $1.createdAt }
    }
    var approvedPosts: [AMPost] {
        db.posts.filter { $0.status == .approved && currentUser?.blockedUsers.contains($0.authorId) != true }
            .sorted { $0.createdAt > $1.createdAt }
    }
    var visibleProjects: [AMProject] {
        db.projects.filter { isVisible(status: $0.status, ownerId: $0.ownerId) }.sorted { $0.createdAt > $1.createdAt }
    }
    var visibleMuseum: [AMMuseumItem] {
        db.museum.filter { isVisible(status: $0.status, ownerId: $0.ownerId) }.sorted { $0.createdAt > $1.createdAt }
    }
    var visibleKidsWorks: [AMKidsWork] {
        db.kidsWorks.filter { isVisible(status: $0.status, ownerId: $0.ownerId) }.sorted { $0.createdAt > $1.createdAt }
    }
    var visibleResearch: [AMResearchArticle] {
        db.research.filter { $0.reviewStatus == .published || $0.ownerId == currentUserId || isStaff }
            .sorted { $0.createdAt > $1.createdAt }
    }
    var publishedNews: [AMNews] {
        db.news.filter(\.isPublished).sorted { ($0.pinned ? 1 : 0, $0.publishAt) > ($1.pinned ? 1 : 0, $1.publishAt) }
    }
    var publishedMagazines: [AMMagazineIssue] {
        db.magazines.filter { $0.published && $0.releaseDate <= Date() }.sorted { $0.number > $1.number }
    }
    var publishedCourses: [AMCourse] { db.courses.filter(\.published) }

    // MARK: - Публикации

    /// Автоматическая связь с темами энциклопедии по ключевым словам («Связать с историей»).
    func suggestedTopics(for text: String) -> [AMTopic] {
        let lower = text.lowercased()
        return db.topics.filter { topic in
            ([topic.title] + topic.keywords).contains { keyword in
                let key = keyword.lowercased().trimmingCharacters(in: .whitespaces)
                return key.count >= 3 && lower.contains(key)
            }
        }
    }

    func publish(_ post: AMPost) {
        var post = post
        post.status = isStaff ? .approved : .pending
        let auto = suggestedTopics(for: post.title + " " + post.body).map(\.id)
        post.topicIds = Array(Set(post.topicIds + auto))
        if let index = db.posts.firstIndex(where: { $0.id == post.id }) {
            db.posts[index] = post
        } else {
            db.posts.append(post)
            complete(quest: "firstPost")
            if post.type == .familyStory { complete(quest: "familyRoots") }
            if post.evidence == .oralHistory { complete(quest: "elderInterview") }
        }
    }

    func deletePost(_ id: UUID) {
        db.posts.removeAll { $0.id == id }
        db.comments.removeAll { $0.targetId == id }
        db.likes.removeAll { $0.targetId == id }
    }

    func likes(_ targetId: UUID) -> Int { db.likes.filter { $0.targetId == targetId }.count }

    func isLiked(_ targetId: UUID) -> Bool {
        db.likes.contains { $0.targetId == targetId && $0.userId == currentUserId }
    }

    func toggleLike(_ targetId: UUID) {
        guard let me = currentUserId else { return }
        if let index = db.likes.firstIndex(where: { $0.targetId == targetId && $0.userId == me }) {
            db.likes.remove(at: index)
        } else {
            db.likes.append(AMLike(targetId: targetId, userId: me))
        }
    }

    func comments(_ targetId: UUID) -> [AMComment] {
        db.comments.filter { $0.targetId == targetId && currentUser?.blockedUsers.contains($0.authorId) != true }
            .sorted { $0.date < $1.date }
    }

    func addComment(_ text: String, to targetId: UUID) {
        guard let user = currentUser, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        db.comments.append(AMComment(targetId: targetId, authorId: user.id, authorName: user.fullName, text: text))
    }

    func report(_ targetId: UUID, title: String, reason: String) {
        guard let me = currentUserId else { return }
        db.reports.append(AMReport(targetId: targetId, targetTitle: title, reporterId: me, reason: reason))
    }

    func block(_ userId: UUID) {
        updateCurrentUser { user in
            if !user.blockedUsers.contains(userId) { user.blockedUsers.append(userId) }
        }
    }

    func moderate(postId: UUID, status: AMModerationStatus, verification: AMVerification? = nil, note: String = "") {
        guard let index = db.posts.firstIndex(where: { $0.id == postId }) else { return }
        let wasApproved = db.posts[index].status == .approved
        db.posts[index].status = status
        if let verification { db.posts[index].verification = verification }
        db.posts[index].moderatorNote = note
        let post = db.posts[index]
        if status == .approved && !wasApproved { addPoints(20, to: post.authorId) }
        notify(post.authorId, title: L("notify.moderation.title"), body: "«\(post.title)» — \(status.title)" + (note.isEmpty ? "" : "\n\(note)"))
    }

    func topicContent(_ topic: AMTopic) -> (posts: [AMPost], places: [AMPlace], museum: [AMMuseumItem]) {
        (approvedPosts.filter { $0.topicIds.contains(topic.id) },
         db.places.filter { $0.topicIds.contains(topic.id) },
         db.museum.filter { $0.status == .approved && $0.topicIds.contains(topic.id) })
    }

    // MARK: - Карта

    func addPlace(_ place: AMPlace) {
        var place = place
        place.authorId = currentUserId
        place.status = isStaff ? .approved : .pending
        db.places.append(place)
        complete(quest: "mapPlace")
    }

    var visiblePlaces: [AMPlace] {
        db.places.filter { $0.status == .approved || $0.authorId == currentUserId || isStaff }
    }

    // MARK: - Inventors Lab

    func saveProject(_ project: AMProject) {
        var project = project
        if let index = db.projects.firstIndex(where: { $0.id == project.id }) {
            if !isStaff && db.projects[index].status == .approved { project.status = .approved }
            db.projects[index] = project
        } else {
            project.status = isStaff ? .approved : .pending
            db.projects.append(project)
            complete(quest: "engineering")
            if project.continuesIdeaId != nil { complete(quest: "continueIdea") }
        }
    }

    func continuations(of idea: AMForgottenIdea) -> [AMProject] {
        visibleProjects.filter { $0.continuesIdeaId == idea.id }
    }

    func team(of project: AMProject) -> [AMUser] {
        let ids = db.invites.filter { $0.projectId == project.id && $0.status == .accepted }.map(\.toId)
        return db.users.filter { ids.contains($0.id) }
    }

    func invite(_ userId: UUID, to project: AMProject, message: String) {
        guard let me = currentUser else { return }
        db.invites.append(AMInvite(projectId: project.id, projectTitle: project.title, fromId: me.id, fromName: me.fullName,
                                   toId: userId, message: message))
        notify(userId, title: L("notify.invite.title"), body: L("notify.invite.body", me.fullName, project.title))
    }

    var myInvites: [AMInvite] {
        db.invites.filter { $0.toId == currentUserId && $0.status == .pending }
    }

    func answer(invite id: UUID, accept: Bool) {
        guard let index = db.invites.firstIndex(where: { $0.id == id }) else { return }
        db.invites[index].status = accept ? .accepted : .declined
        let invite = db.invites[index]
        notify(invite.fromId, title: L("notify.inviteAnswer.title"),
               body: "\(currentUser?.fullName ?? "") — \(accept ? L("invite.accepted") : L("invite.declined"))")
    }

    var projectOfWeek: AMProject? {
        guard let id = db.projectOfWeekId else { return nil }
        return db.projects.first { $0.id == id }
    }

    func setProjectOfWeek(_ id: UUID) {
        db.projectOfWeekId = id
        db.projectOfWeekDate = Date()
        if let project = db.projects.first(where: { $0.id == id }) {
            addPoints(100, to: project.ownerId)
            notify(project.ownerId, title: L("notify.projectOfWeek.title"), body: project.title)
        }
    }

    // MARK: - Музей, дети, исследования

    func saveMuseumItem(_ item: AMMuseumItem) {
        var item = item
        if let index = db.museum.firstIndex(where: { $0.id == item.id }) {
            db.museum[index] = item
        } else {
            item.status = isStaff ? .approved : .pending
            item.topicIds = suggestedTopics(for: item.title + " " + item.story).map(\.id)
            db.museum.append(item)
            complete(quest: "museumItem")
        }
    }

    func saveKidsWork(_ work: AMKidsWork) {
        var work = work
        work.status = isStaff ? .approved : .pending
        db.kidsWorks.append(work)
        complete(quest: "kidsWork")
    }

    func saveResearch(_ article: AMResearchArticle) {
        if let index = db.research.firstIndex(where: { $0.id == article.id }) {
            db.research[index] = article
        } else {
            var article = article
            article.versions = [AMArticleVersion(number: 1, note: L("research.firstVersion"))]
            db.research.append(article)
        }
    }

    func submitResearch(_ id: UUID) {
        guard let index = db.research.firstIndex(where: { $0.id == id }) else { return }
        db.research[index].reviewStatus = .submitted
        for staff in db.users where staff.role.isStaff {
            notify(staff.id, title: L("notify.research.title"), body: db.research[index].title)
        }
    }

    func setReviewStatus(_ id: UUID, _ status: AMReviewStatus) {
        guard let index = db.research.firstIndex(where: { $0.id == id }) else { return }
        db.research[index].reviewStatus = status
        let article = db.research[index]
        notify(article.ownerId, title: L("notify.research.status"), body: "«\(article.title)» — \(status.title)")
        if status == .published { complete(quest: "research", for: article.ownerId) }
    }

    /// Подбор научного руководителя по совпадению ключевых слов.
    func mentors(for article: AMResearchArticle) -> [AMUser] {
        let words = Set((article.keywords + [article.field, article.supervisorExpertise])
            .flatMap { $0.lowercased().split(whereSeparator: { !$0.isLetter }) }.map(String.init).filter { $0.count > 3 })
        return db.users.filter(\.isMentor).sorted { a, b in
            score(a, words) > score(b, words)
        }
    }

    private func score(_ user: AMUser, _ words: Set<String>) -> Int {
        let text = user.expertise.joined(separator: " ").lowercased()
        return words.filter { text.contains($0) }.count
    }

    // MARK: - Профиль

    struct ProfileStats {
        let projects: Int
        let articles: Int
        let stories: Int
        let inventions: Int
        let museum: Int
    }

    func stats(for userId: UUID) -> ProfileStats {
        let posts = db.posts.filter { $0.authorId == userId && $0.status == .approved }
        let projects = db.projects.filter { $0.ownerId == userId }
        return ProfileStats(projects: projects.count,
                            articles: db.research.filter { $0.ownerId == userId }.count + posts.filter { $0.type == .research }.count,
                            stories: posts.filter { [.history, .familyStory, .person, .place].contains($0.type) }.count,
                            inventions: projects.filter { [.prototype, .testing, .result].contains($0.stage) }.count,
                            museum: db.museum.filter { $0.ownerId == userId }.count)
    }

    // MARK: - Академия, журнал, заказы

    func enrollment(_ courseId: UUID) -> AMEnrollment? {
        db.enrollments.first { $0.courseId == courseId && $0.userId == currentUserId }
    }

    func hasAccess(courseId: UUID) -> Bool { enrollment(courseId) != nil || isStaff }

    func seatsLeft(_ course: AMCourse) -> Int? {
        guard let seats = course.seats else { return nil }
        return max(seats - db.enrollments.filter { $0.courseId == course.id }.count, 0)
    }

    func price(of course: AMCourse, promo: String) -> Int {
        let base = course.finalPrice
        guard let code = course.promoCodes.first(where: { $0.code.caseInsensitiveCompare(promo.trimmingCharacters(in: .whitespaces)) == .orderedSame }) else {
            return base
        }
        return base * (100 - min(max(code.percent, 0), 100)) / 100
    }

    /// Бесплатный курс — сразу запись; платный — заказ, который подтверждает администратор.
    @discardableResult
    func enroll(_ course: AMCourse, promo: String = "", method: AMPaymentMethod = .kaspi) -> AMOrder? {
        guard let user = currentUser, enrollment(course.id) == nil else { return nil }
        let amount = price(of: course, promo: promo)
        if course.access == .free || amount == 0 || (course.access == .membersOnly && user.level.rawValue >= AMLevel.researcher.rawValue) {
            db.enrollments.append(AMEnrollment(userId: user.id, courseId: course.id))
            return nil
        }
        let order = AMOrder(userId: user.id, userName: user.fullName, itemKind: .course, itemId: course.id,
                            title: course.title.value, amount: amount, promoCode: promo, method: method)
        db.orders.append(order)
        notifyStaff(title: L("notify.order.title"), body: "\(user.fullName): \(order.title) — \(amount.tenge)")
        return order
    }

    @discardableResult
    func buy(kind: AMOrderItemKind, itemId: UUID, title: String, amount: Int, method: AMPaymentMethod) -> AMOrder? {
        guard let user = currentUser else { return nil }
        let order = AMOrder(userId: user.id, userName: user.fullName, itemKind: kind, itemId: itemId,
                            title: title, amount: amount, method: method)
        db.orders.append(order)
        notifyStaff(title: L("notify.order.title"), body: "\(user.fullName): \(title) — \(amount.tenge)")
        return order
    }

    func hasPaid(itemId: UUID) -> Bool {
        isStaff || db.orders.contains { $0.itemId == itemId && $0.userId == currentUserId && $0.status == .paid }
    }

    func pendingOrder(itemId: UUID) -> AMOrder? {
        db.orders.first { $0.itemId == itemId && $0.userId == currentUserId && $0.status == .pending }
    }

    func setOrderStatus(_ id: UUID, _ status: AMOrderStatus) {
        guard let index = db.orders.firstIndex(where: { $0.id == id }) else { return }
        db.orders[index].status = status
        let order = db.orders[index]
        if status == .paid, order.itemKind == .course,
           !db.enrollments.contains(where: { $0.courseId == order.itemId && $0.userId == order.userId }) {
            db.enrollments.append(AMEnrollment(userId: order.userId, courseId: order.itemId))
        }
        if status == .refunded || status == .cancelled, order.itemKind == .course {
            db.enrollments.removeAll { $0.courseId == order.itemId && $0.userId == order.userId }
        }
        notify(order.userId, title: L("notify.orderStatus.title"), body: "\(order.title) — \(status.title)")
    }

    func toggleLesson(_ lessonId: UUID, courseId: UUID) {
        guard let index = db.enrollments.firstIndex(where: { $0.courseId == courseId && $0.userId == currentUserId }) else { return }
        if let lesson = db.enrollments[index].completedLessons.firstIndex(of: lessonId) {
            db.enrollments[index].completedLessons.remove(at: lesson)
        } else {
            db.enrollments[index].completedLessons.append(lessonId)
            addPoints(10, to: db.enrollments[index].userId)
        }
    }

    func notifyStaff(title: String, body: String) {
        for staff in db.users where staff.role.isStaff { notify(staff.id, title: title, body: body) }
    }

    func publishNews(_ news: AMNews) {
        if let index = db.news.firstIndex(where: { $0.id == news.id }) {
            db.news[index] = news
        } else {
            db.news.append(news)
        }
    }

    // MARK: - Лента «Сегодня в ATA MURA»

    var feed: [AMFeedItem] {
        var items: [AMFeedItem] = []
        items += publishedNews.prefix(10).map {
            AMFeedItem(id: $0.id, kind: .news, label: L("feed.news"), title: $0.title.value,
                       subtitle: String($0.body.value.prefix(140)), date: $0.publishAt, pinned: $0.pinned)
        }
        items += publishedMagazines.prefix(2).map {
            AMFeedItem(id: $0.id, kind: .magazine, label: L("feed.magazine"), title: "ATA MURA Magazine №\($0.number) — \($0.title.value)",
                       subtitle: $0.summary.value, date: $0.releaseDate, pinned: false)
        }
        items += approvedPosts.prefix(20).map {
            AMFeedItem(id: $0.id, kind: .post, label: $0.type.title, title: $0.title,
                       subtitle: String($0.body.prefix(140)), date: $0.createdAt, pinned: false)
        }
        items += db.projects.filter { $0.status == .approved }.prefix(5).map {
            AMFeedItem(id: $0.id, kind: .project, label: "Young Inventor", title: $0.title,
                       subtitle: $0.problem, date: $0.createdAt, pinned: $0.id == db.projectOfWeekId)
        }
        items += publishedCourses.prefix(3).map {
            AMFeedItem(id: $0.id, kind: .course, label: L("feed.course"), title: $0.title.value,
                       subtitle: $0.finalPrice.tenge, date: $0.salesStart, pinned: false)
        }
        items += db.research.filter { $0.reviewStatus == .published }.prefix(3).map {
            AMFeedItem(id: $0.id, kind: .research, label: "ATA MURA Research", title: $0.title,
                       subtitle: $0.authors, date: $0.createdAt, pinned: false)
        }
        items += db.museum.filter { $0.status == .approved }.prefix(3).map {
            AMFeedItem(id: $0.id, kind: .museum, label: L("feed.museum"), title: $0.title,
                       subtitle: $0.period, date: $0.createdAt, pinned: false)
        }
        return items.sorted { ($0.pinned ? 1 : 0, $0.date) > ($1.pinned ? 1 : 0, $1.date) }
    }

    // MARK: - Поиск

    struct SearchResults {
        var posts: [AMPost] = []
        var projects: [AMProject] = []
        var people: [AMUser] = []
        var places: [AMPlace] = []
        var museum: [AMMuseumItem] = []
        var research: [AMResearchArticle] = []
        var topics: [AMTopic] = []
        var isEmpty: Bool {
            posts.isEmpty && projects.isEmpty && people.isEmpty && places.isEmpty && museum.isEmpty && research.isEmpty && topics.isEmpty
        }
    }

    func search(_ query: String) -> SearchResults {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return SearchResults() }
        func has(_ values: String...) -> Bool { values.contains { $0.lowercased().contains(q) } }
        var results = SearchResults()
        results.posts = approvedPosts.filter { has($0.title, $0.body, $0.heroName, $0.region?.title ?? "") }
        results.projects = db.projects.filter { $0.status == .approved && has($0.title, $0.problem, $0.idea, $0.city) }
        results.people = db.users.filter { has($0.fullName, $0.city, $0.titles.joined(separator: " "), $0.expertise.joined(separator: " ")) }
        results.places = visiblePlaces.filter { has($0.title, $0.summary, $0.region.title) }
        results.museum = db.museum.filter { $0.status == .approved && has($0.title, $0.story, $0.belongedTo) }
        results.research = db.research.filter { $0.reviewStatus == .published && has($0.title, $0.abstract, $0.authors, $0.keywords.joined(separator: " ")) }
        results.topics = db.topics.filter { has($0.title, $0.summary, $0.keywords.joined(separator: " ")) }
        return results
    }

    // MARK: - Модерация

    var pendingModerationCount: Int {
        db.posts.filter { $0.status == .pending }.count
            + db.projects.filter { $0.status == .pending }.count
            + db.museum.filter { $0.status == .pending }.count
            + db.kidsWorks.filter { $0.status == .pending }.count
            + db.places.filter { $0.status == .pending }.count
            + db.reports.filter { !$0.resolved }.count
    }

    // MARK: - Morning Dashboard

    var morningItems: [AMMorningItem] {
        let calendar = Calendar.current
        var items: [AMMorningItem] = []
        for task in db.tasks where !task.done {
            if let due = task.due, calendar.isDateInToday(due) || due < Date() {
                items.append(AMMorningItem(icon: "checklist", text: task.title, section: .tasks))
            }
        }
        for item in db.contentItems {
            if let shoot = item.shootDate, calendar.isDateInToday(shoot) {
                items.append(AMMorningItem(icon: "video.fill", text: L("morning.shoot", item.title), section: .calendar))
            }
            if let publish = item.publishDate, calendar.isDateInToday(publish) || calendar.isDateInTomorrow(publish),
               item.status != .published {
                items.append(AMMorningItem(icon: "paperplane", text: L("morning.publish", item.title), section: .calendar))
            }
            if item.status == .script, let publish = item.publishDate,
               publish.timeIntervalSinceNow < 7 * 86_400 {
                items.append(AMMorningItem(icon: "doc.plaintext", text: L("morning.script", item.title), section: .calendar))
            }
        }
        for guest in db.guests where guest.status == .invited {
            items.append(AMMorningItem(icon: "person.crop.circle.badge.questionmark", text: L("morning.guest", guest.name), section: .guests))
        }
        let pendingPosts = db.posts.filter { $0.status == .pending }.count
        if pendingPosts > 0 {
            items.append(AMMorningItem(icon: "checkmark.shield", text: L("morning.moderation", pendingPosts), section: .moderation))
        }
        let pendingOrders = db.orders.filter { $0.status == .pending }.count
        if pendingOrders > 0 {
            items.append(AMMorningItem(icon: "creditcard", text: L("morning.orders", pendingOrders), section: .orders))
        }
        let chosenThisWeek = db.projectOfWeekDate.map { calendar.isDate($0, equalTo: Date(), toGranularity: .weekOfYear) } ?? false
        if !chosenThisWeek && !db.projects.isEmpty {
            items.append(AMMorningItem(icon: "star", text: L("morning.projectOfWeek"), section: .projects))
        }
        let submitted = db.research.filter { $0.reviewStatus == .submitted }.count
        if submitted > 0 {
            items.append(AMMorningItem(icon: "doc.text.magnifyingglass", text: L("morning.research", submitted), section: .research))
        }
        for news in db.news where news.isScheduled && calendar.isDateInToday(news.publishAt) {
            items.append(AMMorningItem(icon: "newspaper", text: L("morning.news", news.title.value), section: .news))
        }
        return items
    }

    // MARK: - Аналитика

    struct SeriesStat: Identifiable {
        let id: UUID
        let name: String
        let episodes: Int
        let planned: Int
        let averageViews: Int
    }

    var seriesStats: [SeriesStat] {
        db.series.map { series in
            let items = db.contentItems.filter { $0.seriesId == series.id }
            let published = items.filter { $0.status == .published }
            let average = published.isEmpty ? 0 : published.map(\.views).reduce(0, +) / published.count
            return SeriesStat(id: series.id, name: series.name, episodes: published.count, planned: series.plannedEpisodes, averageViews: average)
        }
    }

    /// Подсказка: какая рубрика набирает больше всего и что снять дальше.
    var analyticsInsight: String? {
        let stats = seriesStats.filter { $0.averageViews > 0 }.sorted { $0.averageViews > $1.averageViews }
        guard let best = stats.first else { return nil }
        if let worst = stats.last, worst.id != best.id, worst.averageViews > 0 {
            let ratio = Double(best.averageViews) / Double(worst.averageViews)
            return L("analytics.insight.compare", best.name, String(format: "%.1f", ratio), worst.name)
        }
        return L("analytics.insight.single", best.name)
    }
}

// MARK: - JSON

extension JSONEncoder {
    static let am: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let am: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
