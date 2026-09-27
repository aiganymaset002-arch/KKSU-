//
//  KKSUModeration.swift
//  KKSU Online
//
//  Безопасность пользовательского контента (App Store Guideline 1.2):
//  фильтр недопустимых слов, жалобы на сообщения, проекты и пользователей,
//  блокировка пользователей и модерация жалоб администратором.
//

import Foundation

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case harassment, inappropriate, spam, violence, personalData, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .harassment: return "Оскорбления или травля"
        case .inappropriate: return "Неприемлемый контент"
        case .spam: return "Спам или реклама"
        case .violence: return "Угрозы или насилие"
        case .personalData: return "Чужие личные данные"
        case .other: return "Другое"
        }
    }
}

enum ReportedContentKind: String, Codable {
    case message, project, user, lesson
    var title: String {
        switch self {
        case .message: return "Сообщение"
        case .project: return "Проект на выставке"
        case .user: return "Пользователь"
        case .lesson: return "Материал урока"
        }
    }
    var icon: String {
        switch self {
        case .message: return "bubble.left.fill"
        case .project: return "lightbulb.fill"
        case .user: return "person.fill"
        case .lesson: return "book.closed.fill"
        }
    }
}

enum ReportStatus: String, Codable {
    case open, resolved, dismissed
    var title: String {
        switch self {
        case .open: return "Новая"
        case .resolved: return "Приняты меры"
        case .dismissed: return "Отклонена"
        }
    }
}

struct ContentReport: Identifiable, Codable, Hashable {
    var id = UUID()
    var reporterID: UUID
    var reportedUserID: UUID?
    var kind: ReportedContentKind
    var contentID: UUID?
    /// Текст или название того, на что жалуются (для модератора).
    var excerpt: String
    var reason: ReportReason
    var comment: String = ""
    var createdAt = Date()
    var status: ReportStatus = .open
    var resolution: String = ""
    var resolvedAt: Date?
}

struct UserBlock: Identifiable, Codable, Hashable {
    var id = UUID()
    var blockerID: UUID
    var blockedID: UUID
    var createdAt = Date()
}

/// Простой фильтр недопустимых слов для сообщений и публикаций.
enum KKSUContentFilter {
    /// Основы грубых и оскорбительных слов (русский, казахский, английский).
    private static let stems = [
        "хуй", "хуе", "хуя", "пизд", "ебат", "ебан", "ёбан", "еблан", "бляд", "блят", "сука", "суки", "мудак", "мудил",
        "пидор", "пидар", "залуп", "гандон", "шлюх", "долбоеб", "долбаеб", "уебок", "уёбок", "выеб", "дебил", "урод",
        "сігей", "сигей", "амыңды", "қотақ", "котак",
        "fuck", "shit", "bitch", "cunt", "dick", "asshole", "nigger", "faggot", "whore", "slut", "retard"
    ]

    static func containsObjectionable(_ text: String) -> Bool {
        let normalized = text.lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .filter { $0.isLetter || $0.isWhitespace }
        return stems.contains { normalized.contains($0.replacingOccurrences(of: "ё", with: "е")) }
    }
}

extension KKSUStore {

    // MARK: - Блокировка пользователей

    /// Пользователи, которых заблокировал текущий пользователь.
    var blockedUserIDs: Set<UUID> {
        guard let me = currentUser?.id else { return [] }
        return Set(db.userBlocks.filter { $0.blockerID == me }.map(\.blockedID))
    }

    func hasBlocked(_ userID: UUID?) -> Bool {
        guard let userID else { return false }
        return blockedUserIDs.contains(userID)
    }

    func blockUser(_ userID: UUID) {
        guard let me = currentUser?.id, userID != me, !hasBlocked(userID) else { return }
        db.userBlocks.append(UserBlock(blockerID: me, blockedID: userID))
        log(me, "Пользователь заблокирован", details: userName(userID), icon: "hand.raised.slash")
    }

    func unblockUser(_ userID: UUID) {
        guard let me = currentUser?.id else { return }
        db.userBlocks.removeAll { $0.blockerID == me && $0.blockedID == userID }
    }

    // MARK: - Жалобы

    /// Отправляет жалобу модераторам. Контент сразу скрывается у того, кто пожаловался.
    func report(_ kind: ReportedContentKind, contentID: UUID?, reportedUserID: UUID?, excerpt: String,
                reason: ReportReason, comment: String, alsoBlock: Bool) {
        guard let me = currentUser?.id else { return }
        let report = ContentReport(reporterID: me, reportedUserID: reportedUserID, kind: kind, contentID: contentID,
                                   excerpt: String(excerpt.prefix(500)), reason: reason, comment: comment)
        db.contentReports.append(report)
        if alsoBlock, let reportedUserID { blockUser(reportedUserID) }
        for moderator in db.users where moderator.role == .admin && !moderator.isBlocked {
            notify(moderator.id, "Новая жалоба: \(reason.title)", "\(kind.title): \(report.excerpt.prefix(80))", kind: .system)
        }
    }

    /// Жалобы, которые текущий пользователь уже отправил на этот контент (контент скрывается).
    func isReportedByMe(_ contentID: UUID) -> Bool {
        guard let me = currentUser?.id else { return false }
        return db.contentReports.contains { $0.reporterID == me && $0.contentID == contentID && $0.status != .dismissed }
    }

    var openReports: [ContentReport] {
        db.contentReports.filter { $0.status == .open }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Модератор удаляет контент, на который пожаловались.
    func removeReportedContent(_ reportID: UUID) {
        guard let index = db.contentReports.firstIndex(where: { $0.id == reportID }) else { return }
        let report = db.contentReports[index]
        if let contentID = report.contentID {
            switch report.kind {
            case .message:
                db.messages.removeAll { $0.id == contentID }
            case .project:
                if let project = db.projects.firstIndex(where: { $0.id == contentID }) {
                    db.projects[project].showInExhibition = false
                }
            case .lesson:
                for c in db.schoolCourses.indices {
                    if let l = db.schoolCourses[c].lessons.firstIndex(where: { $0.id == contentID }) {
                        db.schoolCourses[c].lessons[l].isPublished = false
                    }
                }
            case .user:
                break
            }
        }
        closeReport(reportID, status: .resolved, resolution: "Контент удалён модератором")
    }

    /// Модератор блокирует нарушителя во всей школе.
    func banReportedUser(_ reportID: UUID) async {
        guard let report = db.contentReports.first(where: { $0.id == reportID }),
              let userID = report.reportedUserID else { return }
        if KKSUCloud.shared.isSignedIn {
            try? await KKSUCloud.shared.updateMember(userID, blocked: true)
        }
        if let index = db.users.firstIndex(where: { $0.id == userID }) { db.users[index].isBlocked = true }
        db.messages.removeAll { $0.senderID == userID && $0.id == report.contentID }
        closeReport(reportID, status: .resolved, resolution: "Пользователь заблокирован модератором")
    }

    func closeReport(_ reportID: UUID, status: ReportStatus, resolution: String) {
        guard let index = db.contentReports.firstIndex(where: { $0.id == reportID }) else { return }
        db.contentReports[index].status = status
        db.contentReports[index].resolution = resolution
        db.contentReports[index].resolvedAt = Date()
        let reporter = db.contentReports[index].reporterID
        notify(reporter, "Жалоба рассмотрена", status == .dismissed ? "Нарушений не найдено." : resolution, kind: .system)
    }
}
