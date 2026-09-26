//
//  KKSUCourseModels.swift
//  KKSU Online
//
//  Конструктор курсов для педагога: курс → уроки. В уроке может быть
//  онлайн-занятие по ссылке, запись на YouTube, конспект, файлы, ссылки,
//  тест и домашнее задание. Ученики отмечают пройденные уроки.
//

import Foundation

struct LessonLink: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var url: String
}

struct CourseLesson: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var summary: String = ""
    /// Онлайн-урок: время и ссылка на видеоконференцию (пусто — комната Jitsi создаётся автоматически).
    var liveStart: Date?
    var liveDurationMinutes: Int = 45
    var livePlatform: ConferencePlatform = .jitsi
    var liveURL: String = ""
    /// id занятия в расписании, если урок добавлен в расписание.
    var sessionID: UUID?
    /// Запись урока или видео с YouTube.
    var videoURL: String = ""
    /// Конспект урока (поддерживается простая разметка: **жирный**, *курсив*, [ссылка](https://…)).
    var notes: String = ""
    var attachments: [Attachment] = []
    var links: [LessonLink] = []
    var testID: UUID?
    var assignmentID: UUID?
    var isPublished = true

    var hasLive: Bool { liveStart != nil || !liveURL.isEmpty }

    /// Ссылка для подключения к онлайн-уроку.
    var joinURL: URL? {
        if !liveURL.isEmpty { return URL(string: liveURL) }
        guard hasLive, livePlatform == .jitsi else { return nil }
        return URL(string: "https://meet.jit.si/KKSU-lesson-\(id.uuidString.prefix(8))")
    }

    var liveEnd: Date? { liveStart?.addingTimeInterval(TimeInterval(liveDurationMinutes * 60)) }
}

struct SchoolCourse: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var subject: String
    var summary: String = ""
    var teacherID: UUID?
    /// Ученики курса. Пусто — курс виден всем ученикам школы.
    var studentIDs: [UUID] = []
    var icon: String = "book.closed.fill"
    var isPublished = false
    var createdAt = Date()
    var lessons: [CourseLesson] = []

    var publishedLessons: [CourseLesson] { lessons.filter(\.isPublished) }
}

struct LessonProgress: Identifiable, Codable, Hashable {
    var id = UUID()
    var courseID: UUID
    var lessonID: UUID
    var studentID: UUID
    var completedAt = Date()
}

enum YouTubeLink {
    /// Достаёт id видео из ссылок youtube.com/watch?v=, youtu.be/, /shorts/, /live/, /embed/.
    static func videoID(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed), let host = components.host?.lowercased() else { return nil }
        if host.contains("youtu.be") {
            let id = components.path.split(separator: "/").first.map(String.init)
            return valid(id)
        }
        guard host.contains("youtube.com") || host.contains("youtube-nocookie.com") else { return nil }
        if let v = components.queryItems?.first(where: { $0.name == "v" })?.value { return valid(v) }
        let parts = components.path.split(separator: "/").map(String.init)
        if parts.count >= 2, ["shorts", "live", "embed", "v"].contains(parts[0]) { return valid(parts[1]) }
        return nil
    }

    private static func valid(_ id: String?) -> String? {
        guard let id, id.count >= 6, id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        return id
    }
}
