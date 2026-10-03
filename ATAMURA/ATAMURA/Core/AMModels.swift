//
//  AMModels.swift
//  ATA MURA
//
//  Модели данных платформы: пользователи, публикации (TARIH), карта, истории,
//  изобретения, музей, исследования, курсы, журнал, новости, Creator Studio.
//

import Foundation
import CoreLocation

// MARK: - Общие типы

/// Текст на трёх языках (новости, журнал, курсы — то, что пишет редакция).
struct LocalizedText: Codable, Hashable {
    var ru: String = ""
    var en: String = ""
    var kk: String = ""

    init(ru: String = "", en: String = "", kk: String = "") {
        self.ru = ru
        self.en = en
        self.kk = kk
    }

    /// Текст на выбранном языке; если перевода нет — на любом заполненном.
    var value: String {
        let preferred: String
        switch AMLanguage.current {
        case .ru: preferred = ru
        case .en: preferred = en
        case .kk: preferred = kk
        }
        if !preferred.isEmpty { return preferred }
        return [ru, en, kk].first { !$0.isEmpty } ?? ""
    }

    var isEmpty: Bool { ru.isEmpty && en.isEmpty && kk.isEmpty }

    subscript(language: AMLanguage) -> String {
        get {
            switch language {
            case .ru: return ru
            case .en: return en
            case .kk: return kk
            }
        }
        set {
            switch language {
            case .ru: ru = newValue
            case .en: en = newValue
            case .kk: kk = newValue
            }
        }
    }
}

enum AMModerationStatus: String, Codable, CaseIterable {
    case pending, approved, needsRevision, rejected

    var title: String { L("moderation.\(rawValue)") }
    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .approved: return "checkmark.seal.fill"
        case .needsRevision: return "pencil.circle.fill"
        case .rejected: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Пользователи

enum AMRole: String, Codable, CaseIterable {
    case member, editor, admin

    var title: String { L("role.\(rawValue)") }
    var isStaff: Bool { self != .member }
}

/// Комфортный режим интерфейса (INCLUSIVE MODE).
enum AMInclusiveMode: String, Codable, CaseIterable, Identifiable {
    case standard, asd, dyslexia, lowVision, hearing, easyLanguage

    var id: String { rawValue }
    var title: String { L("inclusive.\(rawValue)") }
    var subtitle: String { L("inclusive.\(rawValue).hint") }
    var icon: String {
        switch self {
        case .standard: return "circle.grid.2x2"
        case .asd: return "leaf"
        case .dyslexia: return "textformat.size"
        case .lowVision: return "eye"
        case .hearing: return "captions.bubble"
        case .easyLanguage: return "text.bubble"
        }
    }
}

struct AMUser: Codable, Identifiable, Hashable {
    var id = UUID()
    var fullName: String
    var email: String
    var passwordHash: String = ""
    var role: AMRole = .member
    var city: String = ""
    var region: AMRegion?
    var bio: String = ""
    /// Подписи профиля: Inventor, Researcher, Web Developer…
    var titles: [String] = []
    var skills: [String] = []
    var orcid: String = ""
    var birthYear: Int?
    var avatar: Data?
    var points: Int = 0
    var completedQuests: [String] = []
    /// Эксперт/научный руководитель: готов консультировать.
    var isMentor = false
    var expertise: [String] = []
    var blocked = false
    var blockedUsers: [UUID] = []
    var createdAt = Date()

    var level: AMLevel { AMLevel.level(for: points) }
    var age: Int? {
        guard let birthYear else { return nil }
        return Calendar.current.component(.year, from: Date()) - birthYear
    }
    var initials: String {
        fullName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

enum AMLevel: Int, CaseIterable {
    case explorer, researcher, inventor, heritageKeeper, fellow

    var minPoints: Int {
        switch self {
        case .explorer: return 0
        case .researcher: return 300
        case .inventor: return 1000
        case .heritageKeeper: return 2500
        case .fellow: return 5000
        }
    }
    var title: String {
        switch self {
        case .explorer: return "Explorer"
        case .researcher: return "Researcher"
        case .inventor: return "Inventor"
        case .heritageKeeper: return "Heritage Keeper"
        case .fellow: return "ATA MURA Fellow"
        }
    }
    var icon: String {
        switch self {
        case .explorer: return "binoculars.fill"
        case .researcher: return "magnifyingglass"
        case .inventor: return "lightbulb.fill"
        case .heritageKeeper: return "building.columns.fill"
        case .fellow: return "star.circle.fill"
        }
    }
    var next: AMLevel? { AMLevel(rawValue: rawValue + 1) }

    static func level(for points: Int) -> AMLevel {
        allCases.last { points >= $0.minPoints } ?? .explorer
    }
}

// MARK: - Регионы

enum AMRegion: String, Codable, CaseIterable, Identifiable {
    case astana, almaty, shymkent, abai, akmola, aktobe, almatyRegion, atyrau, eastKazakhstan,
         jambyl, jetisu, westKazakhstan, karaganda, kostanay, kyzylorda, mangystau, pavlodar,
         northKazakhstan, turkistan, ulytau

    var id: String { rawValue }
    var title: String { L("region.\(rawValue)") }

    /// Центр региона на карте.
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .astana: return .init(latitude: 51.169, longitude: 71.449)
        case .almaty: return .init(latitude: 43.238, longitude: 76.889)
        case .shymkent: return .init(latitude: 42.341, longitude: 69.590)
        case .abai: return .init(latitude: 50.411, longitude: 80.227)
        case .akmola: return .init(latitude: 53.283, longitude: 69.383)
        case .aktobe: return .init(latitude: 50.283, longitude: 57.167)
        case .almatyRegion: return .init(latitude: 43.867, longitude: 77.067)
        case .atyrau: return .init(latitude: 47.117, longitude: 51.883)
        case .eastKazakhstan: return .init(latitude: 49.948, longitude: 82.628)
        case .jambyl: return .init(latitude: 42.900, longitude: 71.367)
        case .jetisu: return .init(latitude: 45.017, longitude: 78.383)
        case .westKazakhstan: return .init(latitude: 51.233, longitude: 51.367)
        case .karaganda: return .init(latitude: 49.806, longitude: 73.085)
        case .kostanay: return .init(latitude: 53.214, longitude: 63.625)
        case .kyzylorda: return .init(latitude: 44.853, longitude: 65.509)
        case .mangystau: return .init(latitude: 43.650, longitude: 51.167)
        case .pavlodar: return .init(latitude: 52.287, longitude: 76.967)
        case .northKazakhstan: return .init(latitude: 54.875, longitude: 69.162)
        case .turkistan: return .init(latitude: 43.297, longitude: 68.251)
        case .ulytau: return .init(latitude: 47.783, longitude: 67.767)
        }
    }
}

// MARK: - Публикации (TARIH и социальная лента)

enum AMPostType: String, Codable, CaseIterable, Identifiable {
    case history, person, place, archive, culture, research, hypothesis, invention,
         inclusive, youngInventor, news, video, familyStory

    var id: String { rawValue }
    var title: String { L("posttype.\(rawValue)") }
    var icon: String {
        switch self {
        case .history: return "book.closed.fill"
        case .person: return "person.fill"
        case .place: return "mappin.and.ellipse"
        case .archive: return "archivebox.fill"
        case .culture: return "music.note"
        case .research: return "doc.text.magnifyingglass"
        case .hypothesis: return "questionmark.bubble.fill"
        case .invention: return "lightbulb.fill"
        case .inclusive: return "figure.roll"
        case .youngInventor: return "graduationcap.fill"
        case .news: return "newspaper.fill"
        case .video: return "play.rectangle.fill"
        case .familyStory: return "person.2.fill"
        }
    }
}

/// Категория достоверности, которую выбирает автор.
enum AMEvidence: String, Codable, CaseIterable, Identifiable {
    case fact, scientific, archive, oralHistory, interpretation, hypothesis

    var id: String { rawValue }
    var title: String { L("evidence.\(rawValue)") }
    var needsSources: Bool { self != .interpretation }
}

/// Отметка редакции после проверки.
enum AMVerification: String, Codable, CaseIterable {
    case none, verifiedFact, sourceConfirmed, authorOpinion, hypothesis

    var title: String { L("verification.\(rawValue)") }
    var icon: String {
        switch self {
        case .none: return "circle.dashed"
        case .verifiedFact: return "checkmark.seal.fill"
        case .sourceConfirmed: return "doc.badge.checkmark"
        case .authorOpinion: return "person.crop.circle.badge.questionmark"
        case .hypothesis: return "lightbulb.circle"
        }
    }
}

enum AMSourceKind: String, Codable, CaseIterable {
    case book, document, map, photo, link, interview

    var title: String { L("source.\(rawValue)") }
    var icon: String {
        switch self {
        case .book: return "book"
        case .document: return "doc.text"
        case .map: return "map"
        case .photo: return "photo"
        case .link: return "link"
        case .interview: return "mic"
        }
    }
}

struct AMSource: Codable, Hashable, Identifiable {
    var id = UUID()
    var kind: AMSourceKind = .book
    var title: String = ""
    /// Автор, год, архив, адрес ссылки.
    var detail: String = ""
    var attachment: Data?
}

struct AMPost: Codable, Identifiable, Hashable {
    var id = UUID()
    var authorId: UUID
    var authorName: String
    var type: AMPostType
    var evidence: AMEvidence = .fact
    var region: AMRegion?
    var title: String
    var body: String
    var sources: [AMSource] = []
    var images: [Data] = []
    var videoURL: String = ""
    /// Текстовая расшифровка аудио/видео (Hearing Accessibility).
    var transcript: String = ""
    var topicIds: [UUID] = []
    var status: AMModerationStatus = .pending
    var verification: AMVerification = .none
    var moderatorNote: String = ""
    /// Для «100 People — 100 Stories»: герой истории и годы жизни.
    var heroName: String = ""
    var heroYears: String = ""
    /// Отобрано редакцией в книгу «100 People — 100 Stories — 100 Ideas of Kazakhstan».
    var selectedForBook = false
    var createdAt = Date()
}

/// Тема энциклопедии («Связать с историей»): Турксиб, Шёлковый путь, Байконур…
struct AMTopic: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var summary: String
    var region: AMRegion?
    var period: String = ""
    var keywords: [String] = []
}

struct AMComment: Codable, Identifiable, Hashable {
    var id = UUID()
    var targetId: UUID
    var authorId: UUID
    var authorName: String
    var text: String
    var date = Date()
}

struct AMLike: Codable, Identifiable, Hashable {
    var id = UUID()
    var targetId: UUID
    var userId: UUID
}

struct AMReport: Codable, Identifiable, Hashable {
    var id = UUID()
    var targetId: UUID
    var targetTitle: String
    var reporterId: UUID
    var reason: String
    var resolved = false
    var date = Date()
}

// MARK: - Карта

enum AMPlaceKind: String, Codable, CaseIterable, Identifiable {
    case person, monument, mine, settlement, legend, photo, research, schoolProject, enterprise, invention

    var id: String { rawValue }
    var title: String { L("placekind.\(rawValue)") }
    var icon: String {
        switch self {
        case .person: return "person.fill"
        case .monument: return "building.columns.fill"
        case .mine: return "hammer.fill"
        case .settlement: return "tent.fill"
        case .legend: return "sparkles"
        case .photo: return "photo.fill"
        case .research: return "doc.text.magnifyingglass"
        case .schoolProject: return "graduationcap.fill"
        case .enterprise: return "building.2.fill"
        case .invention: return "lightbulb.fill"
        }
    }
}

struct AMPlace: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var summary: String
    var kind: AMPlaceKind
    var region: AMRegion
    var latitude: Double
    var longitude: Double
    var period: String = ""
    var image: Data?
    var topicIds: [UUID] = []
    var authorId: UUID?
    var status: AMModerationStatus = .approved

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

// MARK: - Inventors Lab

enum AMStage: String, Codable, CaseIterable, Identifiable {
    case problem, idea, sketch, calculation, prototype, testing, result

    var id: String { rawValue }
    var title: String { L("stage.\(rawValue)") }
    var icon: String {
        switch self {
        case .problem: return "exclamationmark.triangle"
        case .idea: return "lightbulb"
        case .sketch: return "pencil.and.outline"
        case .calculation: return "function"
        case .prototype: return "cpu"
        case .testing: return "checklist"
        case .result: return "flag.checkered"
        }
    }
    var progress: Double { Double(Self.allCases.firstIndex(of: self)! + 1) / Double(Self.allCases.count) }
}

enum AMDirection: String, Codable, CaseIterable, Identifiable {
    case inclusiveEngineering, heritageTech, ecology, energy, robotics, agro, transport, mining, education, medicine, art, other

    var id: String { rawValue }
    var title: String { L("direction.\(rawValue)") }
}

struct AMProject: Codable, Identifiable, Hashable {
    var id = UUID()
    var ownerId: UUID
    var ownerName: String
    var authorAge: Int?
    var title: String
    var region: AMRegion?
    var city: String = ""
    var direction: AMDirection = .inclusiveEngineering
    var stage: AMStage = .problem
    var problem: String = ""
    var idea: String = ""
    var sketch: String = ""
    var calculation: String = ""
    var prototype: String = ""
    var testing: String = ""
    var result: String = ""
    var whatToLearn: String = ""
    /// «Нужна помощь»: Arduino, 3D-печать…
    var helpNeeded: [String] = []
    var lookingForTeam = false
    var teamNeeds: String = ""
    var images: [Data] = []
    /// Продолжение идеи из «Forgotten Ideas of Kazakhstan».
    var continuesIdeaId: UUID?
    var status: AMModerationStatus = .pending
    var createdAt = Date()

    func text(for stage: AMStage) -> String {
        switch stage {
        case .problem: return problem
        case .idea: return idea
        case .sketch: return sketch
        case .calculation: return calculation
        case .prototype: return prototype
        case .testing: return testing
        case .result: return result
        }
    }

    mutating func setText(_ text: String, for stage: AMStage) {
        switch stage {
        case .problem: problem = text
        case .idea: idea = text
        case .sketch: sketch = text
        case .calculation: calculation = text
        case .prototype: prototype = text
        case .testing: testing = text
        case .result: result = text
        }
    }
}

struct AMForgottenIdea: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var year: String
    var author: String
    var region: AMRegion?
    var summary: String
    var whyNotRealized: String = ""
    var source: String = ""
}

enum AMInviteStatus: String, Codable { case pending, accepted, declined }

struct AMInvite: Codable, Identifiable, Hashable {
    var id = UUID()
    var projectId: UUID
    var projectTitle: String
    var fromId: UUID
    var fromName: String
    var toId: UUID
    var message: String = ""
    var status: AMInviteStatus = .pending
    var date = Date()
}

// MARK: - Цифровой музей

struct AMMuseumItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var ownerId: UUID
    var ownerName: String
    var title: String
    var whatIsIt: String = ""
    var belongedTo: String = ""
    var period: String = ""
    var region: AMRegion?
    var place: String = ""
    var story: String = ""
    var photos: [Data] = []
    var videoURL: String = ""
    var model3DURL: String = ""
    /// «Музей вещей моей семьи».
    var isFamily = true
    var topicIds: [UUID] = []
    var status: AMModerationStatus = .pending
    var createdAt = Date()
}

// MARK: - История глазами ребёнка

enum AMKidsFormat: String, Codable, CaseIterable, Identifiable {
    case drawing, model, lego, model3D, video, comic, invention

    var id: String { rawValue }
    var title: String { L("kidsformat.\(rawValue)") }
    var icon: String {
        switch self {
        case .drawing: return "paintbrush.fill"
        case .model: return "cube.fill"
        case .lego: return "square.stack.3d.up.fill"
        case .model3D: return "rotate.3d"
        case .video: return "video.fill"
        case .comic: return "rectangle.split.3x3"
        case .invention: return "lightbulb.fill"
        }
    }
}

struct AMKidsTheme: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var prompt: String
}

struct AMKidsWork: Codable, Identifiable, Hashable {
    var id = UUID()
    var ownerId: UUID
    var ownerName: String
    var age: Int?
    var themeId: UUID?
    var format: AMKidsFormat
    var title: String
    var summary: String
    var images: [Data] = []
    var videoURL: String = ""
    var status: AMModerationStatus = .pending
    var createdAt = Date()
}

// MARK: - ATA MURA Research

enum AMReviewStatus: String, Codable, CaseIterable {
    case draft, submitted, inReview, reviewed, published

    var title: String { L("review.\(rawValue)") }
}

struct AMArticleVersion: Codable, Hashable, Identifiable {
    var id = UUID()
    var number: Int
    var note: String
    var date = Date()
}

struct AMPeerReview: Codable, Hashable, Identifiable {
    var id = UUID()
    var reviewerName: String
    var verdict: String
    var text: String
    var date = Date()
}

struct AMResearchArticle: Codable, Identifiable, Hashable {
    var id = UUID()
    var ownerId: UUID
    var authors: String
    var orcid: String = ""
    var title: String
    var abstract: String
    var body: String = ""
    var field: String = ""
    var keywords: [String] = []
    var region: AMRegion?
    var sources: [AMSource] = []
    var doi: String = ""
    var pdf: Data?
    var versions: [AMArticleVersion] = []
    var reviewStatus: AMReviewStatus = .draft
    var reviews: [AMPeerReview] = []
    var needsSupervisor = false
    var supervisorExpertise: String = ""
    var supervisorId: UUID?
    var createdAt = Date()
}

// MARK: - Квесты

struct AMQuest: Identifiable, Hashable {
    let id: String
    let points: Int
    let icon: String

    var title: String { L("quest.\(id)") }
    var hint: String { L("quest.\(id).hint") }

    static let all: [AMQuest] = [
        AMQuest(id: "firstPost", points: 30, icon: "square.and.pencil"),
        AMQuest(id: "familyRoots", points: 50, icon: "tree.fill"),
        AMQuest(id: "elderInterview", points: 100, icon: "mic.fill"),
        AMQuest(id: "museumItem", points: 80, icon: "building.columns"),
        AMQuest(id: "kidsWork", points: 120, icon: "paintpalette.fill"),
        AMQuest(id: "mapPlace", points: 60, icon: "mappin.circle.fill"),
        AMQuest(id: "engineering", points: 300, icon: "wrench.and.screwdriver.fill"),
        AMQuest(id: "continueIdea", points: 200, icon: "arrow.triangle.branch"),
        AMQuest(id: "research", points: 500, icon: "doc.text.magnifyingglass")
    ]
}

// MARK: - Уведомления

struct AMNotification: Codable, Identifiable, Hashable {
    var id = UUID()
    var userId: UUID
    var title: String
    var body: String
    var date = Date()
    var read = false
}

// MARK: - Новости и журнал

struct AMNews: Codable, Identifiable, Hashable {
    var id = UUID()
    var title = LocalizedText()
    var body = LocalizedText()
    var image: Data?
    var videoURL: String = ""
    var linkTitle: String = ""
    var linkURL: String = ""
    var pinned = false
    var publishAt = Date()
    var isDraft = false
    var authorName: String = ""
    var createdAt = Date()

    var isPublished: Bool { !isDraft && publishAt <= Date() }
    var isScheduled: Bool { !isDraft && publishAt > Date() }
}

struct AMMagazineIssue: Codable, Identifiable, Hashable {
    var id = UUID()
    var number: Int
    var title = LocalizedText()
    var summary = LocalizedText()
    var cover: Data?
    var pdf: Data?
    var pdfURL: String = ""
    var releaseDate = Date()
    var authors: String = ""
    var editorialBoard: String = ""
    var price: Int = 0
    var published = false
}

// MARK: - ATA MURA Academy

enum AMCourseAccess: String, Codable, CaseIterable {
    case free, paid, subscription, membersOnly

    var title: String { L("access.\(rawValue)") }
}

struct AMQuizQuestion: Codable, Hashable, Identifiable {
    var id = UUID()
    var question: String
    var options: [String]
    var correctIndex: Int
}

struct AMLesson: Codable, Hashable, Identifiable {
    var id = UUID()
    var title: String
    var text: String = ""
    var videoURL: String = ""
    var pdfURL: String = ""
    var homework: String = ""
    var quiz: [AMQuizQuestion] = []
}

struct AMPromoCode: Codable, Hashable, Identifiable {
    var id = UUID()
    var code: String
    var percent: Int
}

struct AMCourse: Codable, Identifiable, Hashable {
    var id = UUID()
    var title = LocalizedText()
    var summary = LocalizedText()
    var cover: Data?
    var teacher: String = ""
    var lessons: [AMLesson] = []
    var access: AMCourseAccess = .free
    var price: Int = 0
    var discountPercent: Int = 0
    var promoCodes: [AMPromoCode] = []
    var salesStart = Date()
    var seats: Int?
    var hasCertificate = true
    var published = false

    var finalPrice: Int { access == .free ? 0 : price * (100 - min(max(discountPercent, 0), 100)) / 100 }
}

struct AMEnrollment: Codable, Identifiable, Hashable {
    var id = UUID()
    var userId: UUID
    var courseId: UUID
    var completedLessons: [UUID] = []
    var date = Date()
}

// MARK: - Заказы и Marketplace

enum AMOrderItemKind: String, Codable { case course, magazine, product }

enum AMOrderStatus: String, Codable, CaseIterable {
    case pending, paid, cancelled, refunded

    var title: String { L("order.\(rawValue)") }
}

enum AMPaymentMethod: String, Codable, CaseIterable {
    case kaspi, card, transfer, cash

    var title: String { L("payment.\(rawValue)") }
}

struct AMOrder: Codable, Identifiable, Hashable {
    var id = UUID()
    var userId: UUID
    var userName: String
    var itemKind: AMOrderItemKind
    var itemId: UUID
    var title: String
    var amount: Int
    var promoCode: String = ""
    var method: AMPaymentMethod = .kaspi
    var status: AMOrderStatus = .pending
    var date = Date()
}

enum AMProductKind: String, Codable, CaseIterable {
    case ebook, magazine, ticket, masterclass, kit, lecture

    var title: String { L("product.\(rawValue)") }
    var icon: String {
        switch self {
        case .ebook: return "book.fill"
        case .magazine: return "magazine.fill"
        case .ticket: return "ticket.fill"
        case .masterclass: return "person.3.fill"
        case .kit: return "shippingbox.fill"
        case .lecture: return "lock.rectangle.stack.fill"
        }
    }
}

struct AMProduct: Codable, Identifiable, Hashable {
    var id = UUID()
    var kind: AMProductKind
    var title: String
    var summary: String
    var price: Int
    var image: Data?
    var stock: Int?
    var published = true
}

// MARK: - Creator Studio (админка)

enum AMPlatform: String, Codable, CaseIterable, Identifiable {
    case youtube, shorts, tiktok, instagram, linkedin, ataMura

    var id: String { rawValue }
    var title: String {
        switch self {
        case .youtube: return "YouTube"
        case .shorts: return "Shorts"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .linkedin: return "LinkedIn"
        case .ataMura: return "ATA MURA"
        }
    }
}

enum AMContentStatus: String, Codable, CaseIterable, Identifiable {
    case idea, script, shooting, editing, ready, published

    var id: String { rawValue }
    var title: String { L("cstatus.\(rawValue)") }
    var icon: String {
        switch self {
        case .idea: return "lightbulb"
        case .script: return "doc.plaintext"
        case .shooting: return "video"
        case .editing: return "scissors"
        case .ready: return "checkmark.circle"
        case .published: return "paperplane.fill"
        }
    }
}

struct AMContentItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var seriesId: UUID?
    var platforms: [AMPlatform] = [.youtube]
    var status: AMContentStatus = .idea
    var shootDate: Date?
    var publishDate: Date?
    var reminder = false
    var responsible: String = ""
    var idea: String = ""
    var goal: String = ""
    var audience: String = ""
    var hook: String = ""
    var script: String = ""
    var shotList: String = ""
    var interviewQuestions: String = ""
    var props: String = ""
    var location: String = ""
    var participants: String = ""
    var music: String = ""
    var cover: Data?
    var descriptionText: String = ""
    var hashtags: String = ""
    var links: String = ""
    var guestIds: [UUID] = []
    var views: Int = 0
    var likes: Int = 0
    var comments: Int = 0
    var newSubscribers: Int = 0
    var resultNotes: String = ""
    var createdAt = Date()
}

struct AMIdea: Codable, Identifiable, Hashable {
    var id = UUID()
    var text: String
    var tags: [String] = []
    var aiSuggestion: String = ""
    var contentItemId: UUID?
    var createdAt = Date()
}

struct AMVlogEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var happened: String = ""
    var meetings: String = ""
    var filmed: String = ""
    var quote: String = ""
    var forAudience: String = ""
    var photos: [Data] = []
}

enum AMGuestCategory: String, Codable, CaseIterable {
    case scientist, child, engineer, partner, veteran, historian, other

    var title: String { L("guestcat.\(rawValue)") }
}

enum AMGuestStatus: String, Codable, CaseIterable {
    case candidate, invited, agreed, filmed, declined

    var title: String { L("gueststatus.\(rawValue)") }
}

struct AMGuest: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var category: AMGuestCategory = .scientist
    var contacts: String = ""
    var topic: String = ""
    var status: AMGuestStatus = .candidate
    var shootDate: Date?
    var questions: String = ""
    var notes: String = ""
}

struct AMSeries: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var summary: String = ""
    var plannedEpisodes: Int = 10
}

enum AMMediaKind: String, Codable, CaseIterable {
    case photo, video, logo, music, document, archive, cover

    var title: String { L("media.\(rawValue)") }
    var icon: String {
        switch self {
        case .photo: return "photo"
        case .video: return "film"
        case .logo: return "seal"
        case .music: return "music.note"
        case .document: return "doc"
        case .archive: return "archivebox"
        case .cover: return "rectangle.portrait"
        }
    }
}

struct AMMediaAsset: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var kind: AMMediaKind
    var data: Data?
    var url: String = ""
    var tags: String = ""
    var date = Date()
}

struct AMEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var place: String = ""
    var summary: String = ""
    var published = true
}

enum AMPartnerKind: String, Codable, CaseIterable {
    case partner, sponsor

    var title: String { L("partnerkind.\(rawValue)") }
}

struct AMPartner: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var kind: AMPartnerKind = .partner
    var contact: String = ""
    var agreement: String = ""
    var amount: Int = 0
    var notes: String = ""
}

struct AMTask: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var due: Date?
    var done = false
    var assignee: String = ""
    var createdAt = Date()
}

// MARK: - AI-помощник

struct AMChatMessage: Codable, Identifiable, Hashable {
    var id = UUID()
    var isUser: Bool
    var text: String
    var date = Date()
    /// Черновик проекта, предложенный AI (кнопка «Создать проект ATA MURA»).
    var projectDraft: AMProjectDraft?
}

struct AMProjectDraft: Codable, Hashable {
    var title: String
    var problem: String
    var solution: String
    var whatToLearn: String
    var firstPrototype: String
    var direction: AMDirection
    var helpNeeded: [String]
}
