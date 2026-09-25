//
//  KKSUModels.swift
//  KKSU Online
//
//  Доменные модели платформы. Все модели — значимые типы (Codable),
//  чтобы вся база сохранялась одним JSON-файлом (см. KKSUStore).
//

import Foundation

// MARK: - Поступление (задачи 11, 12, 13)

struct IntakeQuestionnaire: Identifiable, Codable, Hashable {
    var id = UUID()
    var studentID: UUID
    var date = Date()
    var learningFormat: LearningFormat = .mixed
    var strengths: String = ""
    var difficulties: String = ""
    var healthNotes: String = ""
    var communication: String = ""
    var parentExpectations: String = ""
    var assistiveTech: [String] = []
    var needsPsychologist = false
}

enum LearningFormat: String, Codable, CaseIterable, Identifiable {
    case online, offline, mixed
    var id: String { rawValue }
    var title: String {
        switch self {
        case .online: return "Онлайн"
        case .offline: return "Очно"
        case .mixed: return "Смешанный"
        }
    }
}

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case submitted, review, interview, accepted, rejected
    var id: String { rawValue }
    var title: String {
        switch self {
        case .submitted: return "Подана"
        case .review: return "На рассмотрении"
        case .interview: return "Собеседование"
        case .accepted: return "Принята"
        case .rejected: return "Отклонена"
        }
    }
}

struct EnrollmentApplication: Identifiable, Codable, Hashable {
    var id = UUID()
    var applicantUserID: UUID?
    var childName: String
    var childAge: Int
    var parentName: String
    var email: String
    var phone: String
    var programID: UUID?
    var format: LearningFormat = .mixed
    var comment: String = ""
    var status: ApplicationStatus = .submitted
    var date = Date()
}

enum ConsentType: String, Codable, CaseIterable, Identifiable {
    case personalData, photoVideo, aiUsage, psychologist, international, publication
    var id: String { rawValue }
    var title: String {
        switch self {
        case .personalData: return "Обработка персональных данных"
        case .photoVideo: return "Фото- и видеосъёмка"
        case .aiUsage: return "Использование AI-помощника"
        case .psychologist: return "Сопровождение психолога"
        case .international: return "Участие в международных проектах"
        case .publication: return "Публикация проектов на выставке"
        }
    }
    var isRequired: Bool { self == .personalData }
}

struct ParentConsent: Identifiable, Codable, Hashable {
    var id = UUID()
    var studentID: UUID
    var parentID: UUID
    var type: ConsentType
    var granted: Bool
    var signatureName: String
    var date = Date()
}

// MARK: - Программы и траектория (задачи 14, 15, 16)

enum ProgramDirection: String, Codable, CaseIterable, Identifiable {
    case school, engineering, inventions, global, inclusive, digital, teacherAcademy
    var id: String { rawValue }
    var title: String {
        switch self {
        case .school: return "Школьная программа"
        case .engineering: return "Инженерия"
        case .inventions: return "Изобретательство"
        case .global: return "Международные"
        case .inclusive: return "Инклюзия"
        case .digital: return "Цифровые навыки / AI"
        case .teacherAcademy: return "Teacher Academy"
        }
    }
    var icon: String {
        switch self {
        case .school: return "book.fill"
        case .engineering: return "gearshape.2.fill"
        case .inventions: return "lightbulb.fill"
        case .global: return "globe.europe.africa.fill"
        case .inclusive: return "figure.roll"
        case .digital: return "cpu.fill"
        case .teacherAcademy: return "person.crop.rectangle.stack.fill"
        }
    }
}

struct EducationProgram: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var direction: ProgramDirection
    var ageRange: String
    var durationWeeks: Int
    var format: LearningFormat
    var summary: String
    var subjects: [String]
    var seats: Int = 20
}

enum StepStatus: String, Codable, CaseIterable, Identifiable {
    case planned, inProgress, done
    var id: String { rawValue }
    var title: String {
        switch self {
        case .planned: return "Запланировано"
        case .inProgress: return "В процессе"
        case .done: return "Завершено"
        }
    }
    var icon: String {
        switch self {
        case .planned: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        }
    }
}

struct TrajectoryStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var studentID: UUID
    var title: String
    var programID: UUID?
    var targetDate: Date
    var status: StepStatus = .planned
    var note: String = ""
}

struct StudyPlanItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var studentID: UUID
    var subject: String
    var hoursPerWeek: Int
    var goal: String
    var term: String
    var adaptation: String = ""
}

// MARK: - Расписание, онлайн-занятия (задачи 17, 18, 32, 33)

enum ConferencePlatform: String, Codable, CaseIterable, Identifiable {
    case jitsi, zoom, meet, teams, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .jitsi: return "Jitsi Meet"
        case .zoom: return "Zoom"
        case .meet: return "Google Meet"
        case .teams: return "Microsoft Teams"
        case .other: return "Другая"
        }
    }
}

struct ScheduleSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var subject: String
    var teacherID: UUID?
    var start: Date
    var durationMinutes: Int = 45
    var room: String = ""
    var isOnline: Bool = true
    var platform: ConferencePlatform = .jitsi
    var meetingURL: String = ""
    var participantIDs: [UUID] = []
    var attendedIDs: [UUID] = []
    var recordingURL: String = ""

    var end: Date { start.addingTimeInterval(TimeInterval(durationMinutes * 60)) }

    /// Ссылка на видеоконференцию. Для Jitsi комната создаётся автоматически.
    var joinURL: URL? {
        if !meetingURL.isEmpty { return URL(string: meetingURL) }
        guard isOnline, platform == .jitsi else { return nil }
        return URL(string: "https://meet.jit.si/KKSU-\(id.uuidString.prefix(8))")
    }
}

struct CalendarNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var title: String
    var date: Date
}

// MARK: - Задания, работы, оценки (задачи 19, 20, 21, 36, 81)

enum AssignmentAudience: String, Codable {
    case students, teachers
}

struct Assignment: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var subject: String
    var details: String
    var teacherID: UUID?
    var createdAt = Date()
    var dueDate: Date
    var maxScore: Int = 10
    var assignedIDs: [UUID] = []
    var audience: AssignmentAudience = .students
    var courseID: UUID?
    /// Задание сгенерировано AI и не видно ученику, пока педагог его не одобрит.
    var isAIGenerated = false
    var approvedByTeacher = true
    var textAlternative: String = ""
}

enum AttachmentKind: String, Codable, CaseIterable, Identifiable {
    case photo, video, drawing, document, pdf, presentation, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .photo: return "Фото"
        case .video: return "Видео"
        case .drawing: return "Чертёж"
        case .document: return "Документ"
        case .pdf: return "PDF"
        case .presentation: return "Презентация"
        case .other: return "Файл"
        }
    }
    var icon: String {
        switch self {
        case .photo: return "photo.fill"
        case .video: return "video.fill"
        case .drawing: return "pencil.and.ruler.fill"
        case .document: return "doc.text.fill"
        case .pdf: return "doc.richtext.fill"
        case .presentation: return "rectangle.on.rectangle.angled.fill"
        case .other: return "paperclip"
        }
    }

    static func detect(fileName: String) -> AttachmentKind {
        switch (fileName as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif": return .photo
        case "mov", "mp4", "m4v": return .video
        case "dwg", "dxf", "svg", "step", "stl": return .drawing
        case "pdf": return .pdf
        case "ppt", "pptx", "key": return .presentation
        case "doc", "docx", "txt", "rtf", "pages", "md": return .document
        default: return .other
        }
    }
}

struct Attachment: Identifiable, Codable, Hashable {
    var id = UUID()
    var fileName: String
    var kind: AttachmentKind
    var sizeBytes: Int = 0
    /// Имя файла в папке Documents/uploads.
    var storedName: String?
    var remoteURL: String?
    /// Текстовая альтернатива (задача 76).
    var altText: String = ""
}

enum SubmissionStatus: String, Codable {
    case submitted, graded, returned
    var title: String {
        switch self {
        case .submitted: return "На проверке"
        case .graded: return "Оценено"
        case .returned: return "На доработку"
        }
    }
}

struct Submission: Identifiable, Codable, Hashable {
    var id = UUID()
    var assignmentID: UUID
    var studentID: UUID
    var submittedAt = Date()
    var text: String
    var attachments: [Attachment] = []
    var score: Int?
    var feedback: String = ""
    var gradedAt: Date?
    var gradedBy: UUID?
    var status: SubmissionStatus = .submitted
}

// MARK: - Портфолио, достижения, сертификаты, история (задачи 22, 23, 25, 42, 99)

struct PortfolioItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var studentID: UUID
    var title: String
    var category: String
    var date = Date()
    var summary: String
    var attachments: [Attachment] = []
    var verifiedBy: UUID?
}

struct Achievement: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var title: String
    var icon: String
    var points: Int
    var date = Date()
}

enum CertificateIssuer: String, Codable, CaseIterable {
    case school, teacherAcademy, youngInventors, conference, internship
    var title: String {
        switch self {
        case .school: return "KKSU Online"
        case .teacherAcademy: return "KKSU Teacher Academy"
        case .youngInventors: return "Young Inventors 30"
        case .conference: return "Конференции KKSU"
        case .internship: return "Стажировки KKSU"
        }
    }
}

struct Certificate: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var recipientName: String
    var title: String
    var issuer: CertificateIssuer
    var date = Date()
    var serial: String
    var hours: Int?

    /// Строка для проверки подлинности сертификата.
    var verificationCode: String { "KKSU-\(serial)" }
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var date = Date()
    var action: String
    var details: String = ""
    var icon: String = "clock"
}

// MARK: - Библиотеки (задачи 26, 27, 28, 40, 75, 76)

enum LibraryKind: String, Codable, CaseIterable, Identifiable {
    case video, methodical, pdf, presentation, instruction, textbook
    var id: String { rawValue }
    var title: String {
        switch self {
        case .video: return "Видеоурок"
        case .methodical: return "Методический материал"
        case .pdf: return "PDF"
        case .presentation: return "Презентация"
        case .instruction: return "Инструкция"
        case .textbook: return "Учебник"
        }
    }
    var icon: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .methodical: return "text.book.closed.fill"
        case .pdf: return "doc.richtext.fill"
        case .presentation: return "rectangle.on.rectangle.angled.fill"
        case .instruction: return "list.bullet.clipboard.fill"
        case .textbook: return "books.vertical.fill"
        }
    }
}

enum ContentFormat: String, Codable, CaseIterable, Identifiable {
    case video, text, audio, interactive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .video: return "Видео"
        case .text: return "Текст"
        case .audio: return "Аудио"
        case .interactive: return "Интерактив"
        }
    }
}

struct CaptionSegment: Codable, Hashable {
    var start: Double
    var end: Double
    var text: String
}

struct LibraryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var kind: LibraryKind
    var subject: String
    var author: String
    var summary: String
    var url: String = ""
    var durationMinutes: Int = 0
    var captions: [CaptionSegment] = []
    var textAlternative: String = ""
    var tags: [String] = []
    var forTeachers = false
    var isTeacherAcademy = false
    var views: Int = 0

    var format: ContentFormat {
        switch kind {
        case .video: return .video
        case .presentation: return .interactive
        default: return .text
        }
    }
}

// MARK: - Тестирование (задачи 29, 30, 31, 41)

enum QuestionKind: String, Codable, CaseIterable, Identifiable {
    case single, multiple, number, text
    var id: String { rawValue }
    var title: String {
        switch self {
        case .single: return "Один ответ"
        case .multiple: return "Несколько ответов"
        case .number: return "Число"
        case .text: return "Короткий текст"
        }
    }
}

struct TestQuestion: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var kind: QuestionKind = .single
    var options: [String] = []
    var correctIndices: [Int] = []
    var correctText: String = ""
    var points: Int = 1
    var explanation: String = ""
}

struct KKSUTest: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var subject: String
    var authorID: UUID?
    var questions: [TestQuestion]
    var timeLimitMinutes: Int = 20
    var passingPercent: Int = 60
    var audience: AssignmentAudience = .students
    var courseID: UUID?
    var isPublished = true

    var maxScore: Int { questions.reduce(0) { $0 + $1.points } }
}

struct TestAnswer: Codable, Hashable {
    var questionID: UUID
    var selected: [Int] = []
    var text: String = ""
}

struct TestAttempt: Identifiable, Codable, Hashable {
    var id = UUID()
    var testID: UUID
    var userID: UUID
    var date = Date()
    var answers: [TestAnswer]
    var score: Int
    var maxScore: Int
    var passed: Bool

    var percent: Int { maxScore == 0 ? 0 : Int((Double(score) / Double(maxScore) * 100).rounded()) }
}

// MARK: - Коммуникации (задачи 34, 35)

struct ChatThread: Identifiable, Codable, Hashable {
    var id = UUID()
    var participantIDs: [UUID]
    var title: String
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id = UUID()
    var threadID: UUID
    var senderID: UUID
    var text: String
    var date = Date()
    var readBy: [UUID] = []
}

enum NotificationKind: String, Codable {
    case info, deadline, grade, message, event, system, ai
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .deadline: return "clock.badge.exclamationmark.fill"
        case .grade: return "star.circle.fill"
        case .message: return "bubble.left.fill"
        case .event: return "calendar.badge.plus"
        case .system: return "gearshape.fill"
        case .ai: return "sparkles"
        }
    }
}

struct KKSUNotification: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var title: String
    var body: String
    var kind: NotificationKind = .info
    var date = Date()
    var isRead = false
}

// MARK: - Teacher Academy (задачи 37–46)

struct TeacherAcademyProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var specialization: String
    var experienceYears: Int
    var organization: String
    var date = Date()
}

struct TeacherCourse: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var hours: Int
    var level: String
    var summary: String
    var modules: [String]
    var enrolledIDs: [UUID] = []
    var completedModules: [String: [String]] = [:]   // userID -> завершённые модули
    var completedIDs: [UUID] = []
}

enum MethodologyStatus: String, Codable, CaseIterable, Identifiable {
    case draft, piloting, reviewed, approved
    var id: String { rawValue }
    var title: String {
        switch self {
        case .draft: return "Черновик"
        case .piloting: return "Апробация"
        case .reviewed: return "Экспертиза"
        case .approved: return "Утверждена"
        }
    }
}

struct Methodology: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var author: String
    var subject: String
    var ageGroup: String
    var summary: String
    var status: MethodologyStatus = .draft
    var documents: [Attachment] = []
}

struct MethodologyPilot: Identifiable, Codable, Hashable {
    var id = UUID()
    var methodologyID: UUID
    var site: String
    var teacherName: String
    var startDate: Date
    var endDate: Date
    var participants: Int
    var baselineScore: Double
    var finalScore: Double
    var summary: String

    var growthPercent: Double {
        baselineScore == 0 ? 0 : (finalScore - baselineScore) / baselineScore * 100
    }
}

enum ReviewTarget: String, Codable {
    case methodology, project, youngInventors
}

enum ReviewDecision: String, Codable, CaseIterable, Identifiable {
    case approve, revise, reject
    var id: String { rawValue }
    var title: String {
        switch self {
        case .approve: return "Рекомендовать"
        case .revise: return "На доработку"
        case .reject: return "Отклонить"
        }
    }
}

struct ReviewScore: Codable, Hashable {
    var criterion: String
    var score: Int
}

struct ExpertReview: Identifiable, Codable, Hashable {
    var id = UUID()
    var targetID: UUID
    var target: ReviewTarget
    var expertID: UUID
    var date = Date()
    var scores: [ReviewScore]
    var comment: String
    var decision: ReviewDecision

    var average: Double {
        scores.isEmpty ? 0 : Double(scores.reduce(0) { $0 + $1.score }) / Double(scores.count)
    }

    static let methodologyCriteria = ["Научная обоснованность", "Практическая применимость", "Инклюзивность", "Воспроизводимость", "Результативность"]
    static let projectCriteria = ["Новизна", "Техническая проработка", "Социальная значимость", "Качество прототипа", "Презентация"]
}

// MARK: - Изобретения и проекты (задачи 47–59, 64–72)

enum ProjectStage: String, Codable, CaseIterable, Identifiable, Comparable {
    case idea, research, prototype, testing, result
    var id: String { rawValue }
    var title: String {
        switch self {
        case .idea: return "Idea"
        case .research: return "Research"
        case .prototype: return "Prototype"
        case .testing: return "Testing"
        case .result: return "Result"
        }
    }
    var subtitle: String {
        switch self {
        case .idea: return "Идея"
        case .research: return "Исследование"
        case .prototype: return "Прототип"
        case .testing: return "Испытания"
        case .result: return "Результат"
        }
    }
    var icon: String {
        switch self {
        case .idea: return "lightbulb.fill"
        case .research: return "magnifyingglass"
        case .prototype: return "hammer.fill"
        case .testing: return "testtube.2"
        case .result: return "flag.checkered"
        }
    }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    var next: ProjectStage? {
        let all = Self.allCases
        return index + 1 < all.count ? all[index + 1] : nil
    }
    static func < (lhs: ProjectStage, rhs: ProjectStage) -> Bool { lhs.index < rhs.index }
}

enum ProjectTrack: String, Codable, CaseIterable, Identifiable {
    case inventions, futureEngineers, mashstroy, araiAI, iken, ataMura, inclusiveEngineering, global
    var id: String { rawValue }
    var title: String {
        switch self {
        case .inventions: return "KKSU Inventions"
        case .futureEngineers: return "Future Engineers"
        case .mashstroy: return "MASHSTROY"
        case .araiAI: return "ARAI AI"
        case .iken: return "IKEN"
        case .ataMura: return "ATA MURA"
        case .inclusiveEngineering: return "Inclusive Engineering"
        case .global: return "Global Classroom"
        }
    }
    var icon: String {
        switch self {
        case .inventions: return "lightbulb.max.fill"
        case .futureEngineers: return "wrench.and.screwdriver.fill"
        case .mashstroy: return "gearshape.2.fill"
        case .araiAI: return "brain.head.profile"
        case .iken: return "leaf.fill"
        case .ataMura: return "building.columns.fill"
        case .inclusiveEngineering: return "figure.roll"
        case .global: return "globe"
        }
    }
    var summary: String {
        switch self {
        case .inventions: return "Изобретения и прототипы учеников KKSU."
        case .futureEngineers: return "Инженерная школа: курсы, виртуальные задания, кейсы."
        case .mashstroy: return "Проектные кейсы машиностроения от индустриальных партнёров."
        case .araiAI: return "Интеграция AI-решений ARAI в учебные и инженерные проекты."
        case .iken: return "Проекты IKEN: экология, энергия и устойчивое развитие."
        case .ataMura: return "Проекты ATA MURA: культурное наследие и история в цифровом формате."
        case .inclusiveEngineering: return "Инженерные разработки для людей с особыми потребностями."
        case .global: return "Совместные международные проекты."
        }
    }
}

struct InventionProject: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var summary: String
    var problem: String = ""
    var solution: String = ""
    var stage: ProjectStage = .idea
    var track: ProjectTrack = .inventions
    var teamID: UUID?
    var mentorID: UUID?
    var authorIDs: [UUID] = []
    var media: [Attachment] = []
    var createdAt = Date()
    var stageHistory: [StageChange] = []
    var isPrototype = false
    var prototypeSpecs: String = ""
    var inclusiveTarget: String = ""
    var showInExhibition = false
    var likes: Int = 0
    var tags: [String] = []
}

struct StageChange: Codable, Hashable {
    var stage: ProjectStage
    var date: Date
    var note: String
}

struct ProjectTeam: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var memberIDs: [UUID]
    var captainID: UUID?
}

struct ExperimentEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var projectID: UUID
    var authorID: UUID
    var date = Date()
    var hypothesis: String
    var method: String
    var result: String
    var conclusion: String
    var success: Bool
}

struct LabMeasurement: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var value: Double
    var unit: String
}

struct LabNotebookPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var projectID: UUID
    var authorID: UUID
    var date = Date()
    var title: String
    var content: String
    var measurements: [LabMeasurement] = []
    var signedByMentor = false
}

enum YIStatus: String, Codable, CaseIterable, Identifiable {
    case submitted, underReview, finalist, winner, rejected
    var id: String { rawValue }
    var title: String {
        switch self {
        case .submitted: return "Подана"
        case .underReview: return "Экспертиза"
        case .finalist: return "Финалист"
        case .winner: return "Победитель"
        case .rejected: return "Не прошла"
        }
    }
}

struct YoungInventorsApplication: Identifiable, Codable, Hashable {
    var id = UUID()
    var projectID: UUID
    var applicantID: UUID
    var season: String
    var nomination: String
    var motivation: String
    var date = Date()
    var status: YIStatus = .submitted
}

// MARK: - Международная деятельность и инженерия (задачи 60–67)

struct GlobalClass: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var country: String
    var language: String
    var partnerSchool: String
    var teacherName: String
    var start: Date
    var summary: String
    var meetingURL: String = ""
    var participantIDs: [UUID] = []
}

struct InternationalProject: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var countries: [String]
    var partners: String
    var summary: String
    var participantIDs: [UUID] = []
    var isActive = true
}

struct InternationalExpert: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var country: String
    var expertise: String
    var bio: String
    var email: String
    var isTeacher: Bool
}

struct EngineeringCourse: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var track: ProjectTrack
    var level: String
    var summary: String
    var lessons: [String]
    var enrolledIDs: [UUID] = []
}

struct EngineeringChallenge: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var track: ProjectTrack
    var summary: String
    var steps: [String]
    var difficulty: Int
    var points: Int
    var isIndustryCase = false
    var company: String = ""
    var completedIDs: [UUID] = []
}

// MARK: - Партнёры, стажировки, мероприятия (задачи 93–99)

enum PartnerKind: String, Codable, CaseIterable, Identifiable {
    case company, university, school, ngo, government, international
    var id: String { rawValue }
    var title: String {
        switch self {
        case .company: return "Компания"
        case .university: return "Университет"
        case .school: return "Школа"
        case .ngo: return "НКО"
        case .government: return "Гос. организация"
        case .international: return "Международная организация"
        }
    }
}

struct Partner: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var kind: PartnerKind
    var country: String
    var summary: String
    var email: String
    var website: String
    var since: Date
    var isInternational: Bool { country != "Казахстан" }
}

struct Internship: Identifiable, Codable, Hashable {
    var id = UUID()
    var partnerID: UUID
    var title: String
    var summary: String
    var requirements: String
    var start: Date
    var durationWeeks: Int
    var seats: Int
    var isOpen = true
}

enum InternshipStatus: String, Codable, CaseIterable, Identifiable {
    case submitted, interview, accepted, rejected, completed
    var id: String { rawValue }
    var title: String {
        switch self {
        case .submitted: return "Подана"
        case .interview: return "Собеседование"
        case .accepted: return "Принят"
        case .rejected: return "Отказ"
        case .completed: return "Завершена"
        }
    }
}

struct InternshipApplication: Identifiable, Codable, Hashable {
    var id = UUID()
    var internshipID: UUID
    var studentID: UUID
    var motivation: String
    var date = Date()
    var status: InternshipStatus = .submitted
}

enum EventKind: String, Codable, CaseIterable, Identifiable {
    case conference, webinar, exhibition, hackathon, olympiad
    var id: String { rawValue }
    var title: String {
        switch self {
        case .conference: return "Конференция"
        case .webinar: return "Вебинар"
        case .exhibition: return "Выставка"
        case .hackathon: return "Хакатон"
        case .olympiad: return "Олимпиада"
        }
    }
}

struct KKSUEvent: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var kind: EventKind
    var date: Date
    var location: String
    var isOnline: Bool
    var meetingURL: String = ""
    var summary: String
    var capacity: Int
    var isInternational = false
    var hours: Int = 4
}

enum EventRole: String, Codable, CaseIterable, Identifiable {
    case listener, participant, speaker
    var id: String { rawValue }
    var title: String {
        switch self {
        case .listener: return "Слушатель"
        case .participant: return "Участник"
        case .speaker: return "Докладчик"
        }
    }
}

struct EventRegistration: Identifiable, Codable, Hashable {
    var id = UUID()
    var eventID: UUID
    var userID: UUID
    var role: EventRole
    var talkTitle: String = ""
    var date = Date()
    var attended = false
    var certificateID: UUID?
}

// MARK: - Доступность и персонализация (задачи 73, 74, 77)

struct AccessibilitySettings: Codable, Hashable {
    var textScale: Double = 1.0
    var highContrast = false
    var boldText = false
    var dyslexiaFriendlyFont = false
    var reduceMotion = false
    var simplifiedInterface = false
    var largeButtons = false
    var captionsEnabled = true
    var showTextAlternatives = false
    var darkMode: DarkModePreference = .system
}

enum DarkModePreference: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Как в системе"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

enum LearningPace: String, Codable, CaseIterable, Identifiable {
    case gentle, normal, intensive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .gentle: return "Спокойный"
        case .normal: return "Обычный"
        case .intensive: return "Интенсивный"
        }
    }
}

struct LearningPreferences: Codable, Hashable {
    var pace: LearningPace = .normal
    var formats: [ContentFormat] = [.video, .text]
    var sessionMinutes: Int = 25
    var breakReminders = true
    var dailyGoalMinutes: Int = 40
    var interests: [String] = []
    var aiHintsEnabled = true
}

// MARK: - AI (задачи 79–83)

struct AIChatMessage: Identifiable, Codable, Hashable {
    var id = UUID()
    var isUser: Bool
    var text: String
    var date = Date()
}
