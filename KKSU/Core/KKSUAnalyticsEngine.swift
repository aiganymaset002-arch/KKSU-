//
//  KKSUAnalyticsEngine.swift
//  KKSU Online
//
//  Анализ учебного прогресса (82), рекомендации педагогу (83),
//  рекомендации контента (78) и автоматический подсчёт Impact-показателей (84–89).
//

import SwiftUI

// MARK: - Анализ прогресса ученика (задача 82)

enum RiskLevel: String {
    case low, medium, high
    var title: String {
        switch self {
        case .low: return "Стабильно"
        case .medium: return "Требует внимания"
        case .high: return "Нужна поддержка"
        }
    }
    var color: Color {
        switch self {
        case .low: return KKSUTheme.success
        case .medium: return KKSUTheme.warning
        case .high: return KKSUTheme.danger
        }
    }
}

struct SubjectStat: Identifiable {
    var id: String { subject }
    let subject: String
    let average: Double      // 0...1
    let count: Int
    let trend: Double        // изменение среднего второй половины к первой
}

struct StudentAnalysis: Identifiable {
    var id: UUID { studentID }
    let studentID: UUID
    let subjects: [SubjectStat]
    let completionRate: Double
    let overdue: [Assignment]
    let testAverage: Double?
    let attendanceRate: Double?
    let overall: Double
    let risk: RiskLevel
    let weeklyActivity: [(day: Date, count: Int)]

    var strongest: SubjectStat? { subjects.max { $0.average < $1.average } }
    var weakest: SubjectStat? { subjects.min { $0.average < $1.average } }
}

@MainActor
enum ProgressAnalyzer {

    static func analyze(_ studentID: UUID, db: KKSUDatabase, store: KKSUStore) -> StudentAnalysis {
        let now = Date()
        let assignments = store.assignments(for: studentID)
        let subs = db.submissions.filter { $0.studentID == studentID }

        // Оценки по предметам
        var bySubject: [String: [(Date, Double)]] = [:]
        for sub in subs {
            guard let score = sub.score, let a = assignments.first(where: { $0.id == sub.assignmentID }) else { continue }
            bySubject[a.subject, default: []].append((sub.gradedAt ?? sub.submittedAt, Double(score) / Double(max(a.maxScore, 1))))
        }
        let attempts = db.attempts.filter { $0.userID == studentID }
        for attempt in attempts {
            guard let test = db.tests.first(where: { $0.id == attempt.testID }) else { continue }
            bySubject[test.subject, default: []].append((attempt.date, Double(attempt.percent) / 100))
        }
        let subjects = bySubject.map { subject, values -> SubjectStat in
            let sorted = values.sorted { $0.0 < $1.0 }.map(\.1)
            let avg = sorted.reduce(0, +) / Double(sorted.count)
            var trend = 0.0
            if sorted.count >= 2 {
                let half = sorted.count / 2
                let first = sorted.prefix(half).reduce(0, +) / Double(half)
                let second = sorted.suffix(sorted.count - half).reduce(0, +) / Double(sorted.count - half)
                trend = second - first
            }
            return SubjectStat(subject: subject, average: avg, count: sorted.count, trend: trend)
        }.sorted { $0.subject < $1.subject }

        // Выполнение и просрочки
        let due = assignments.filter { $0.dueDate < now || store.submission(for: $0.id, studentID: studentID) != nil }
        let submitted = due.filter { store.submission(for: $0.id, studentID: studentID) != nil }
        let completion = due.isEmpty ? 1 : Double(submitted.count) / Double(due.count)
        let overdue = assignments.filter { $0.dueDate < now && store.submission(for: $0.id, studentID: studentID) == nil }

        // Посещаемость
        let past = db.sessions.filter { $0.start < now && $0.participantIDs.contains(studentID) }
        let attendance: Double? = past.isEmpty ? nil : Double(past.filter { $0.attendedIDs.contains(studentID) }.count) / Double(past.count)

        let testAvg: Double? = attempts.isEmpty ? nil : attempts.map { Double($0.percent) / 100 }.reduce(0, +) / Double(attempts.count)
        let gradeValues = subjects.map(\.average)
        let gradeAvg: Double? = gradeValues.isEmpty ? nil : gradeValues.reduce(0, +) / Double(gradeValues.count)

        var weighted = 0.0, weights = 0.0
        if let gradeAvg { weighted += gradeAvg * 0.5; weights += 0.5 }
        weighted += completion * 0.3; weights += 0.3
        if let attendance { weighted += attendance * 0.2; weights += 0.2 }
        let overall = weights > 0 ? weighted / weights : 0

        let risk: RiskLevel
        if overall < 0.5 || overdue.count >= 2 { risk = .high }
        else if overall < 0.7 || overdue.count == 1 || subjects.contains(where: { $0.trend < -0.15 }) { risk = .medium }
        else { risk = .low }

        // Активность за 7 дней
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let activity: [(day: Date, count: Int)] = (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = db.history.filter { $0.userID == studentID && cal.isDate($0.date, inSameDayAs: day) }.count
            return (day, count)
        }

        return StudentAnalysis(studentID: studentID, subjects: subjects, completionRate: completion, overdue: overdue,
                               testAverage: testAvg, attendanceRate: attendance, overall: overall, risk: risk, weeklyActivity: activity)
    }
}

// MARK: - Рекомендации педагогу (задача 83)

struct TeacherInsight: Identifiable {
    let id = UUID()
    let studentID: UUID
    let icon: String
    let title: String
    let action: String
    let priority: RiskLevel
}

@MainActor
enum TeacherInsightEngine {
    static func insights(for analyses: [StudentAnalysis], store: KKSUStore) -> [TeacherInsight] {
        var result: [TeacherInsight] = []
        for a in analyses {
            let name = store.userName(a.studentID)
            if !a.overdue.isEmpty {
                result.append(TeacherInsight(studentID: a.studentID, icon: "clock.badge.exclamationmark", title: "\(name): просрочено заданий — \(a.overdue.count)",
                                             action: "Напишите ученику в чат, продлите срок или разбейте задание на короткие шаги.", priority: a.overdue.count >= 2 ? .high : .medium))
            }
            if let weak = a.weakest, weak.average < 0.6 {
                result.append(TeacherInsight(studentID: a.studentID, icon: "arrow.down.right", title: "\(name): низкий результат по предмету «\(weak.subject)» (\(Int(weak.average * 100))%)",
                                             action: "Сгенерируйте адаптированное задание через AI и проверьте его перед отправкой.", priority: .high))
            }
            for subject in a.subjects where subject.trend < -0.15 {
                result.append(TeacherInsight(studentID: a.studentID, icon: "chart.line.downtrend.xyaxis", title: "\(name): снижение по «\(subject.subject)»",
                                             action: "Проведите короткую индивидуальную консультацию, уточните трудности.", priority: .medium))
            }
            if let attendance = a.attendanceRate, attendance < 0.7 {
                result.append(TeacherInsight(studentID: a.studentID, icon: "person.crop.circle.badge.xmark", title: "\(name): посещаемость \(Int(attendance * 100))%",
                                             action: "Свяжитесь с родителем; предложите запись занятия с субтитрами.", priority: .medium))
            }
            if let strong = a.strongest, strong.average >= 0.9 {
                result.append(TeacherInsight(studentID: a.studentID, icon: "star.fill", title: "\(name): отличные результаты по «\(strong.subject)»",
                                             action: "Предложите олимпиадное задание, проект в KKSU Inventions или Young Inventors 30.", priority: .low))
            }
            let profile = store.profile(for: a.studentID)
            if let needs = profile?.specialNeeds, !needs.isEmpty {
                result.append(TeacherInsight(studentID: a.studentID, icon: "figure.roll", title: "\(name): особые образовательные потребности",
                                             action: "Учитывайте: \(needs). \(profile?.supportNotes ?? "")", priority: .low))
            }
        }
        let order: [RiskLevel] = [.high, .medium, .low]
        return result.sorted { (order.firstIndex(of: $0.priority) ?? 0) < (order.firstIndex(of: $1.priority) ?? 0) }
    }
}

// MARK: - Рекомендации контента (задача 78)

struct ContentRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
    let icon: String
    let score: Double
    let libraryItem: LibraryItem?
    let route: KKSURoute?
}

@MainActor
enum RecommendationEngine {
    static func recommendations(for userID: UUID, store: KKSUStore) -> [ContentRecommendation] {
        let db = store.db
        let prefs = store.preferences(for: userID)
        let profile = store.profile(for: userID)
        let interests = Set((prefs.interests + (profile?.interests ?? [])).map { $0.lowercased() })
        let analysis = ProgressAnalyzer.analyze(userID, db: db, store: store)
        let weakSubjects = Set(analysis.subjects.filter { $0.average < 0.75 }.map { $0.subject.lowercased() })
        let viewed = Set(db.viewedLibraryIDs[userID] ?? [])

        var result: [ContentRecommendation] = []
        for item in db.library where !item.forTeachers {
            var score = 0.0
            var reasons: [String] = []
            let subject = item.subject.lowercased()
            if weakSubjects.contains(subject) { score += 3; reasons.append("поможет подтянуть «\(item.subject)»") }
            if interests.contains(subject) || !interests.isDisjoint(with: item.tags.map { $0.lowercased() }) {
                score += 2; reasons.append("совпадает с интересами")
            }
            if prefs.formats.contains(item.format) { score += 1; reasons.append("удобный формат: \(item.format.title.lowercased())") }
            if !viewed.contains(item.id) { score += 0.5 } else { score -= 2 }
            if prefs.pace == .gentle && item.durationMinutes > 0 && item.durationMinutes <= prefs.sessionMinutes { score += 0.5 }
            if score > 1 {
                result.append(ContentRecommendation(title: item.title, reason: reasons.joined(separator: ", ").capitalizedFirst, icon: item.kind.icon, score: score, libraryItem: item, route: nil))
            }
        }
        for program in db.programs where !interests.isDisjoint(with: program.subjects.map { $0.lowercased() }) {
            result.append(ContentRecommendation(title: "Программа «\(program.title)»", reason: "Соответствует интересам ученика", icon: program.direction.icon, score: 1.5, libraryItem: nil, route: .programs))
        }
        if let challenge = db.challenges.first(where: { !$0.completedIDs.contains(userID) && $0.difficulty <= 3 }) {
            result.append(ContentRecommendation(title: "Инженерное задание «\(challenge.title)»", reason: "+\(challenge.points) баллов, сложность \(challenge.difficulty)/5", icon: "puzzlepiece.extension.fill", score: 1.2, libraryItem: nil, route: .challenges))
        }
        if let event = db.events.filter({ $0.date > Date() }).min(by: { $0.date < $1.date }) {
            result.append(ContentRecommendation(title: event.title, reason: "Ближайшее мероприятие: \(event.date.kksuShort)", icon: "calendar", score: 1, libraryItem: nil, route: .events))
        }
        return result.sorted { $0.score > $1.score }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - Impact-показатели (задачи 84–89)

struct ImpactMetrics {
    // 85: автоматический подсчёт
    let students: Int
    let teachers: Int
    let lessonsHeld: Int
    let lessonsPlanned: Int
    let projects: Int
    let results: Int
    // 86: образовательный прогресс
    let averageScore: Double
    let completionRate: Double
    let attendanceRate: Double
    let testsPassed: Int
    let certificates: Int
    let achievements: Int
    let academyGraduates: Int
    // 87: проекты и изобретения
    let projectsByStage: [(ProjectStage, Int)]
    let prototypes: Int
    let yiApplications: Int
    let yiFinalists: Int
    let exhibitionItems: Int
    let inclusiveProjects: Int
    let experiments: Int
    // 88: партнёрства
    let partners: Int
    let partnersByKind: [(PartnerKind, Int)]
    let internships: Int
    let internshipApplications: Int
    let internshipAccepted: Int
    // 89: международная деятельность
    let countries: Int
    let globalClasses: Int
    let internationalProjects: Int
    let internationalExperts: Int
    let internationalEvents: Int
    let internationalPartners: Int
    // мероприятия
    let events: Int
    let eventParticipants: Int

    @MainActor
    init(db: KKSUDatabase, from: Date = .distantPast, to: Date = .distantFuture) {
        let now = Date()
        let inRange: (Date) -> Bool = { $0 >= from && $0 <= to }
        students = db.users.filter { $0.role == .student }.count
        teachers = db.users.filter { $0.role == .teacher }.count
        let sessions = db.sessions.filter { inRange($0.start) }
        lessonsHeld = sessions.filter { $0.start < now }.count
        lessonsPlanned = sessions.filter { $0.start >= now }.count
        let projectsInRange = db.projects.filter { inRange($0.createdAt) }
        projects = projectsInRange.count
        results = projectsInRange.filter { $0.stage == .result }.count + db.certificates.filter { inRange($0.date) }.count

        let graded = db.submissions.filter { inRange($0.submittedAt) }.compactMap { sub -> Double? in
            guard let score = sub.score, let a = db.assignments.first(where: { $0.id == sub.assignmentID }) else { return nil }
            return Double(score) / Double(max(a.maxScore, 1))
        }
        averageScore = graded.isEmpty ? 0 : graded.reduce(0, +) / Double(graded.count)
        let dueAssignments = db.assignments.filter { $0.audience == .students && $0.approvedByTeacher && $0.dueDate < now && inRange($0.dueDate) }
        let studentCount = max(students, 1)
        let expected = dueAssignments.reduce(0) { total, a in total + (a.assignedIDs.isEmpty ? studentCount : a.assignedIDs.count) }
        let delivered = dueAssignments.reduce(0) { total, a in total + Set(db.submissions.filter { $0.assignmentID == a.id }.map(\.studentID)).count }
        completionRate = expected == 0 ? 1 : min(Double(delivered) / Double(expected), 1)
        let pastSessions = sessions.filter { $0.start < now }
        let seats = pastSessions.reduce(0) { $0 + $1.participantIDs.count }
        let attended = pastSessions.reduce(0) { $0 + $1.attendedIDs.count }
        attendanceRate = seats == 0 ? 0 : Double(attended) / Double(seats)
        testsPassed = db.attempts.filter { $0.passed && inRange($0.date) }.count
        certificates = db.certificates.filter { inRange($0.date) }.count
        achievements = db.achievements.filter { inRange($0.date) }.count
        academyGraduates = Set(db.teacherCourses.flatMap(\.completedIDs)).count

        projectsByStage = ProjectStage.allCases.map { stage in (stage, projectsInRange.filter { $0.stage == stage }.count) }
        prototypes = projectsInRange.filter(\.isPrototype).count
        yiApplications = db.yiApplications.filter { inRange($0.date) }.count
        yiFinalists = db.yiApplications.filter { $0.status == .finalist || $0.status == .winner }.count
        exhibitionItems = db.projects.filter(\.showInExhibition).count
        inclusiveProjects = projectsInRange.filter { $0.track == .inclusiveEngineering || !$0.inclusiveTarget.isEmpty }.count
        experiments = db.experiments.filter { inRange($0.date) }.count

        partners = db.partners.count
        partnersByKind = PartnerKind.allCases.map { kind in (kind, db.partners.filter { $0.kind == kind }.count) }.filter { $0.1 > 0 }
        internships = db.internships.count
        internshipApplications = db.internshipApplications.filter { inRange($0.date) }.count
        internshipAccepted = db.internshipApplications.filter { $0.status == .accepted || $0.status == .completed }.count

        var countrySet = Set(db.partners.map(\.country))
        db.globalClasses.forEach { countrySet.insert($0.country) }
        db.internationalProjects.forEach { $0.countries.forEach { countrySet.insert($0) } }
        db.internationalExperts.forEach { countrySet.insert($0.country) }
        countries = countrySet.count
        globalClasses = db.globalClasses.count
        internationalProjects = db.internationalProjects.count
        internationalExperts = db.internationalExperts.count
        internationalEvents = db.events.filter(\.isInternational).count
        internationalPartners = db.partners.filter(\.isInternational).count

        events = db.events.filter { inRange($0.date) }.count
        eventParticipants = db.eventRegistrations.filter { inRange($0.date) }.count
    }
}
