//
//  KKSUCourseLogic.swift
//  KKSU Online
//
//  Логика конструктора курсов: доступ учеников, прогресс, отметка уроков,
//  добавление онлайн-уроков в расписание, уведомления, сертификат за курс.
//

import Foundation

extension KKSUStore {

    func course(_ id: UUID) -> SchoolCourse? { db.schoolCourses.first { $0.id == id } }

    /// Курсы, которые видит ученик (опубликованные, для него или для всех).
    func courses(for studentID: UUID) -> [SchoolCourse] {
        db.schoolCourses.filter { $0.isPublished && ($0.studentIDs.isEmpty || $0.studentIDs.contains(studentID)) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Курсы педагога (администратор видит все).
    var myTeachingCourses: [SchoolCourse] {
        let me = currentUser?.id
        return db.schoolCourses.filter { role == .admin || $0.teacherID == me }.sorted { $0.createdAt > $1.createdAt }
    }

    func courseStudents(_ course: SchoolCourse) -> [KKSUUser] {
        course.studentIDs.isEmpty ? students : students.filter { course.studentIDs.contains($0.id) }
    }

    func isLessonCompleted(_ lessonID: UUID, studentID: UUID) -> Bool {
        db.lessonProgress.contains { $0.lessonID == lessonID && $0.studentID == studentID }
    }

    func courseProgress(_ course: SchoolCourse, studentID: UUID) -> Double {
        let lessons = course.publishedLessons
        guard !lessons.isEmpty else { return 0 }
        let done = lessons.filter { isLessonCompleted($0.id, studentID: studentID) }.count
        return Double(done) / Double(lessons.count)
    }

    func toggleLessonCompleted(courseID: UUID, lessonID: UUID, studentID: UUID) {
        if let index = db.lessonProgress.firstIndex(where: { $0.lessonID == lessonID && $0.studentID == studentID }) {
            db.lessonProgress.remove(at: index)
            return
        }
        db.lessonProgress.append(LessonProgress(courseID: courseID, lessonID: lessonID, studentID: studentID))
        guard let course = self.course(courseID) else { return }
        let title = course.lessons.first { $0.id == lessonID }?.title ?? ""
        log(studentID, "Пройден урок", details: "\(course.title): \(title)", icon: "checkmark.circle")
        if courseProgress(course, studentID: studentID) >= 1 {
            issueCertificate(to: studentID, title: "Курс «\(course.title)» пройден", issuer: .school, hours: course.publishedLessons.count)
            award(studentID, "Курс пройден: \(course.title)", icon: "graduationcap.fill", points: 50)
            if let teacher = course.teacherID {
                notify(teacher, "Ученик прошёл курс", "\(userName(studentID)) — «\(course.title)»", kind: .info)
            }
        }
    }

    /// Публикация курса: ученики получают уведомление.
    func publishCourse(_ courseID: UUID) {
        guard let index = db.schoolCourses.firstIndex(where: { $0.id == courseID }) else { return }
        db.schoolCourses[index].isPublished = true
        let course = db.schoolCourses[index]
        for student in courseStudents(course) {
            notify(student.id, "Новый курс: \(course.title)", "\(course.subject) · уроков: \(course.publishedLessons.count)", kind: .info)
        }
    }

    /// Добавляет онлайн-урок в расписание учеников курса (или обновляет уже добавленный).
    func scheduleLiveLesson(courseID: UUID, lessonID: UUID) {
        guard let cIndex = db.schoolCourses.firstIndex(where: { $0.id == courseID }),
              let lIndex = db.schoolCourses[cIndex].lessons.firstIndex(where: { $0.id == lessonID }),
              let start = db.schoolCourses[cIndex].lessons[lIndex].liveStart else { return }
        let course = db.schoolCourses[cIndex]
        let lesson = course.lessons[lIndex]
        let participants = courseStudents(course).map(\.id)
        var session = db.sessions.first { $0.id == lesson.sessionID } ?? ScheduleSession(title: lesson.title, subject: course.subject, start: start)
        session.title = lesson.title
        session.subject = course.subject
        session.teacherID = course.teacherID ?? currentUser?.id
        session.start = start
        session.durationMinutes = lesson.liveDurationMinutes
        session.isOnline = true
        session.platform = lesson.livePlatform
        session.meetingURL = lesson.joinURL?.absoluteString ?? ""
        session.participantIDs = participants
        session.recordingURL = lesson.videoURL
        if let index = db.sessions.firstIndex(where: { $0.id == session.id }) {
            db.sessions[index] = session
        } else {
            db.sessions.append(session)
            db.schoolCourses[cIndex].lessons[lIndex].sessionID = session.id
            for student in participants {
                notify(student, "Онлайн-урок: \(lesson.title)", "\(course.title) · \(start.kksuDateTime)", kind: .event)
            }
        }
    }

    /// Ученик задаёт вопрос по уроку — сообщение уходит учителю в чат.
    func askTeacher(course: SchoolCourse, lesson: CourseLesson, question: String) {
        guard let teacher = course.teacherID, !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let thread = self.thread(with: teacher)
        send("Вопрос по уроку «\(lesson.title)» (\(course.title)):\n\(question)", in: thread.id)
    }
}
