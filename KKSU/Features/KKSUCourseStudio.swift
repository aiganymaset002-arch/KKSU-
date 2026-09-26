//
//  KKSUCourseStudio.swift
//  KKSU Online
//
//  Конструктор курсов для педагога и просмотр курсов для ученика:
//  онлайн-уроки по ссылке, записи на YouTube, конспекты, файлы, ссылки,
//  тесты и домашние задания к урокам, прогресс учеников.
//

import SwiftUI
#if canImport(WebKit) && canImport(UIKit)
import WebKit
#endif

// MARK: - YouTube-плеер

struct YouTubePlayer: View {
    let url: String

    var body: some View {
        if let id = YouTubeLink.videoID(from: url) {
            VStack(alignment: .leading, spacing: 6) {
                #if canImport(WebKit) && canImport(UIKit)
                YouTubeWebView(videoID: id)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                #endif
                if let link = URL(string: "https://www.youtube.com/watch?v=\(id)") {
                    Link(destination: link) { Label("Открыть в YouTube", systemImage: "play.rectangle.fill") }
                        .font(.caption)
                }
            }
        } else if let link = URL(string: url), !url.isEmpty {
            Link(destination: link) { Label("Открыть видео", systemImage: "play.rectangle.fill") }
        }
    }
}

#if canImport(WebKit) && canImport(UIKit)
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let view = WKWebView(frame: .zero, configuration: config)
        view.scrollView.isScrollEnabled = false
        view.isOpaque = false
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.loadedID != videoID else { return }
        context.coordinator.loadedID = videoID
        // YouTube требует источник (origin) у встроенного плеера, поэтому страница загружается с baseURL.
        let html = """
        <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;padding:0;background:#000;height:100%}iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe src="https://www.youtube-nocookie.com/embed/\(videoID)?playsinline=1&rel=0&modestbranding=1&origin=https://kksu.kz"
        allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        </body></html>
        """
        view.loadHTMLString(html, baseURL: URL(string: "https://kksu.kz"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedID: String?
    }
}
#endif

// MARK: - Конспект с разметкой

struct LessonNotesText: View {
    let text: String

    var body: some View {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: text, options: options) {
            Text(attributed).textSelection(.enabled)
        } else {
            Text(text).textSelection(.enabled)
        }
    }
}

// MARK: - Студия курсов педагога

struct CourseStudioView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var newCourseID: UUID?

    var body: some View {
        KPage("Мои курсы") {
            Text("Создайте курс, добавьте уроки: онлайн-занятие по ссылке, запись с YouTube, конспект, файлы, ссылки, тест и домашнее задание.")
                .font(.callout).foregroundStyle(.secondary)
            PrimaryButton(title: "Новый курс", icon: "plus") { createCourse() }
            if store.myTeachingCourses.isEmpty {
                KEmptyState(text: "У вас пока нет курсов", icon: "book.closed")
            }
            ForEach(store.myTeachingCourses) { course in
                NavigationLink { SchoolCourseEditorView(courseID: course.id) } label: {
                    KCard {
                        HStack {
                            Image(systemName: course.icon).font(.title2).foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.title.isEmpty ? "Без названия" : course.title).font(.headline)
                                Text("\(course.subject) · уроков: \(course.lessons.count) · учеников: \(store.courseStudents(course).count)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            KBadge(text: course.isPublished ? "Опубликован" : "Черновик",
                                   color: course.isPublished ? KKSUTheme.success : KKSUTheme.warning)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(item: $newCourseID) { id in SchoolCourseEditorView(courseID: id) }
    }

    private func createCourse() {
        let course = SchoolCourse(title: "", subject: "", teacherID: store.currentUser?.id)
        store.db.schoolCourses.append(course)
        newCourseID = course.id
    }
}

// MARK: - Редактор курса

struct SchoolCourseEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let courseID: UUID
    @State private var openLessonID: UUID?
    @State private var confirmDelete = false
    @State private var price = 0.0

    private let icons = ["book.closed.fill", "function", "atom", "globe.europe.africa.fill", "paintpalette.fill", "music.note",
                         "cpu.fill", "wrench.and.screwdriver.fill", "leaf.fill", "text.book.closed.fill", "character.book.closed.fill"]

    var body: some View {
        if let index = store.db.schoolCourses.firstIndex(where: { $0.id == courseID }) {
            let course = store.db.schoolCourses[index]
            Form {
                Section("Курс") {
                    TextField("Название курса", text: $store.db.schoolCourses[index].title)
                    TextField("Предмет", text: $store.db.schoolCourses[index].subject)
                    TextField("Описание", text: $store.db.schoolCourses[index].summary, axis: .vertical)
                    Picker("Иконка", selection: $store.db.schoolCourses[index].icon) {
                        ForEach(icons, id: \.self) { Image(systemName: $0).tag($0) }
                    }
                }

                Section {
                    ForEach(course.lessons) { lesson in
                        NavigationLink { LessonEditorView(courseID: courseID, lessonID: lesson.id) } label: {
                            LessonRow(lesson: lesson, index: (course.lessons.firstIndex(of: lesson) ?? 0) + 1)
                        }
                    }
                    .onMove { store.db.schoolCourses[index].lessons.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { store.db.schoolCourses[index].lessons.remove(atOffsets: $0) }
                    Button {
                        let lesson = CourseLesson(title: "Урок \(course.lessons.count + 1)")
                        store.db.schoolCourses[index].lessons.append(lesson)
                        openLessonID = lesson.id
                    } label: {
                        Label("Добавить урок", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Уроки · \(course.lessons.count)")
                        Spacer()
                        EditButton().font(.caption)
                    }
                }

                Section {
                    Toggle("Для всех учеников школы", isOn: Binding(
                        get: { store.db.schoolCourses[index].studentIDs.isEmpty },
                        set: { all in store.db.schoolCourses[index].studentIDs = all ? [] : store.students.prefix(1).map(\.id) }))
                    if !course.studentIDs.isEmpty {
                        ForEach(store.students) { student in
                            Toggle(student.fullName, isOn: Binding(
                                get: { store.db.schoolCourses[index].studentIDs.contains(student.id) },
                                set: { on in
                                    if on { store.db.schoolCourses[index].studentIDs.append(student.id) }
                                    else { store.db.schoolCourses[index].studentIDs.removeAll { $0 == student.id } }
                                }))
                        }
                    }
                } header: {
                    Text("Ученики")
                }

                Section {
                    Stepper(price > 0 ? store.priceText(price) : "Бесплатно", value: $price, in: 0...500, step: 5)
                        .onChange(of: price) { _, value in setPrice(value, course: course) }
                } header: {
                    Text("Цена")
                } footer: {
                    Text("Платный курс ученики покупают через App Store или по подписке KKSU. Бесплатный курс доступен сразу.")
                }

                Section("Прогресс учеников") {
                    let students = store.courseStudents(course)
                    if students.isEmpty || course.publishedLessons.isEmpty {
                        Text("Появится после публикации уроков").foregroundStyle(.secondary)
                    }
                    ForEach(students) { student in
                        let progress = store.courseProgress(course, studentID: student.id)
                        HStack {
                            Text(student.fullName)
                            Spacer()
                            Text("\(Int(progress * 100))%").font(.callout.monospacedDigit()).foregroundStyle(progress >= 1 ? KKSUTheme.success : .secondary)
                        }
                    }
                }

                Section {
                    if course.isPublished {
                        Toggle("Опубликован", isOn: $store.db.schoolCourses[index].isPublished)
                    } else {
                        Button {
                            store.publishCourse(courseID)
                        } label: {
                            Label("Опубликовать курс для учеников", systemImage: "paperplane.fill")
                        }
                        .fontWeight(.semibold)
                        .disabled(course.title.isEmpty || course.lessons.isEmpty)
                    }
                    NavigationLink("Как видит ученик") { SchoolCourseDetailView(courseID: courseID, previewAsTeacher: true) }
                    Button("Удалить курс", role: .destructive) { confirmDelete = true }
                }
            }
            .navigationTitle(course.title.isEmpty ? "Новый курс" : course.title)
            .navigationDestination(item: $openLessonID) { id in LessonEditorView(courseID: courseID, lessonID: id) }
            .onAppear { price = store.product(forRef: courseID)?.priceUSD ?? 0 }
            .confirmationDialog("Удалить курс со всеми уроками?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    store.db.schoolCourses.removeAll { $0.id == courseID }
                    store.db.lessonProgress.removeAll { $0.courseID == courseID }
                    dismiss()
                }
            }
        } else {
            KEmptyState(text: "Курс удалён", icon: "trash")
        }
    }

    private func setPrice(_ value: Double, course: SchoolCourse) {
        if let index = store.billing.products.firstIndex(where: { $0.refID == courseID }) {
            store.billing.products[index].priceUSD = value
            store.billing.products[index].title = "Курс «\(course.title)»"
            store.billing.products[index].isActive = value > 0
        } else if value > 0 {
            store.billing.products.append(Product(title: "Курс «\(course.title)»", kind: .course, priceUSD: value,
                                                  summary: course.summary, refID: courseID, sellerID: course.teacherID))
        }
    }
}

struct LessonRow: View {
    let lesson: CourseLesson
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(index). \(lesson.title)").font(.body.weight(.medium))
                if !lesson.isPublished { KBadge(text: "Скрыт", color: .secondary) }
            }
            HStack(spacing: 10) {
                if lesson.hasLive { Label(lesson.liveStart?.kksuDateTime ?? "онлайн", systemImage: "video.fill") }
                if !lesson.videoURL.isEmpty { Image(systemName: "play.rectangle.fill") }
                if !lesson.notes.isEmpty { Image(systemName: "text.alignleft") }
                if !lesson.attachments.isEmpty { Label("\(lesson.attachments.count)", systemImage: "paperclip") }
                if !lesson.links.isEmpty { Label("\(lesson.links.count)", systemImage: "link") }
                if lesson.testID != nil { Image(systemName: "checklist") }
                if lesson.assignmentID != nil { Image(systemName: "house.and.flag.fill") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Редактор урока

struct LessonEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    let courseID: UUID
    let lessonID: UUID
    @State private var newAttachments: [Attachment] = []
    @State private var linkTitle = ""
    @State private var linkURL = ""
    @State private var homeworkTitle = ""
    @State private var homeworkDue = Date().addingTimeInterval(3 * 86400)
    @State private var previewNotes = false
    @State private var scheduled = false

    var body: some View {
        if let c = store.db.schoolCourses.firstIndex(where: { $0.id == courseID }),
           let l = store.db.schoolCourses[c].lessons.firstIndex(where: { $0.id == lessonID }) {
            let lesson = store.db.schoolCourses[c].lessons[l]
            let course = store.db.schoolCourses[c]
            Form {
                Section("Урок") {
                    TextField("Тема урока", text: $store.db.schoolCourses[c].lessons[l].title)
                    TextField("Краткое описание", text: $store.db.schoolCourses[c].lessons[l].summary, axis: .vertical)
                    Toggle("Показывать ученикам", isOn: $store.db.schoolCourses[c].lessons[l].isPublished)
                }

                // Онлайн-урок
                Section {
                    Toggle("Провести онлайн", isOn: Binding(
                        get: { store.db.schoolCourses[c].lessons[l].liveStart != nil },
                        set: { on in store.db.schoolCourses[c].lessons[l].liveStart = on ? Date().addingTimeInterval(86400) : nil }))
                    if lesson.liveStart != nil {
                        DatePicker("Начало", selection: Binding(
                            get: { store.db.schoolCourses[c].lessons[l].liveStart ?? Date() },
                            set: { store.db.schoolCourses[c].lessons[l].liveStart = $0 }))
                        Stepper("Длительность: \(lesson.liveDurationMinutes) мин", value: $store.db.schoolCourses[c].lessons[l].liveDurationMinutes, in: 15...180, step: 5)
                        Picker("Платформа", selection: $store.db.schoolCourses[c].lessons[l].livePlatform) {
                            ForEach(ConferencePlatform.allCases) { Text($0.title).tag($0) }
                        }
                        TextField(lesson.livePlatform == .jitsi ? "Ссылка (пусто — комната создастся сама)" : "Ссылка на конференцию",
                                  text: $store.db.schoolCourses[c].lessons[l].liveURL)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            #endif
                        if let url = lesson.joinURL {
                            HStack {
                                Link(destination: url) { Label("Начать урок", systemImage: "video.fill") }
                                Spacer()
                                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                            }
                        }
                        Button {
                            store.scheduleLiveLesson(courseID: courseID, lessonID: lessonID)
                            scheduled = true
                        } label: {
                            Label(lesson.sessionID == nil ? "Добавить в расписание учеников" : "Обновить в расписании", systemImage: "calendar.badge.plus")
                        }
                        if scheduled { Text("Урок в расписании, ученики получили уведомление.").font(.caption).foregroundStyle(KKSUTheme.success) }
                    }
                } header: {
                    Text("Онлайн-урок")
                } footer: {
                    Text("Урок можно провести в Jitsi, Zoom, Google Meet или Teams. Запись потом добавьте ниже ссылкой YouTube.")
                }

                // Запись / видео
                Section {
                    TextField("Ссылка YouTube (youtube.com или youtu.be)", text: $store.db.schoolCourses[c].lessons[l].videoURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                    if !lesson.videoURL.isEmpty {
                        if YouTubeLink.videoID(from: lesson.videoURL) == nil && !lesson.videoURL.contains("://") {
                            Text("Не похоже на ссылку. Скопируйте адрес видео из YouTube.").font(.caption).foregroundStyle(KKSUTheme.danger)
                        }
                        YouTubePlayer(url: lesson.videoURL)
                    }
                } header: {
                    Text("Видео / запись урока")
                } footer: {
                    Text("Загрузите видео на YouTube (можно «доступ по ссылке») и вставьте ссылку — ученики посмотрят его прямо в приложении.")
                }

                // Конспект
                Section {
                    Picker("", selection: $previewNotes) {
                        Text("Редактировать").tag(false)
                        Text("Просмотр").tag(true)
                    }
                    .pickerStyle(.segmented)
                    if previewNotes {
                        if lesson.notes.isEmpty { Text("Конспект пуст").foregroundStyle(.secondary) }
                        LessonNotesText(text: lesson.notes)
                    } else {
                        TextEditor(text: $store.db.schoolCourses[c].lessons[l].notes)
                            .frame(minHeight: 180)
                    }
                } header: {
                    Text("Конспект")
                } footer: {
                    Text("Можно выделять: **жирный**, *курсив*, ссылки [текст](https://…).")
                }

                // Файлы
                Section("Файлы") {
                    ForEach(lesson.attachments) { AttachmentRow(attachment: $0) }
                        .onDelete { store.db.schoolCourses[c].lessons[l].attachments.remove(atOffsets: $0) }
                    AttachmentPicker(attachments: $newAttachments)
                    if !newAttachments.isEmpty {
                        Button("Прикрепить к уроку (\(newAttachments.count))") {
                            store.db.schoolCourses[c].lessons[l].attachments += newAttachments
                            newAttachments = []
                        }
                    }
                }

                // Ссылки
                Section("Полезные ссылки") {
                    ForEach(lesson.links) { link in
                        if let url = URL(string: link.url) {
                            Link(destination: url) { Label(link.title, systemImage: "link") }
                        } else {
                            Label(link.title, systemImage: "link")
                        }
                    }
                    .onDelete { store.db.schoolCourses[c].lessons[l].links.remove(atOffsets: $0) }
                    TextField("Название (например, презентация)", text: $linkTitle)
                    TextField("https://…", text: $linkURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                    Button("Добавить ссылку") {
                        var url = linkURL.trimmingCharacters(in: .whitespaces)
                        if !url.contains("://") { url = "https://" + url }
                        store.db.schoolCourses[c].lessons[l].links.append(LessonLink(title: linkTitle.isEmpty ? url : linkTitle, url: url))
                        linkTitle = ""
                        linkURL = ""
                    }
                    .disabled(linkURL.isEmpty)
                }

                // Тест и домашнее задание
                Section {
                    Picker("Тест к уроку", selection: $store.db.schoolCourses[c].lessons[l].testID) {
                        Text("Без теста").tag(UUID?.none)
                        ForEach(store.db.tests.filter { $0.audience == .students }) { Text($0.title).tag(UUID?.some($0.id)) }
                    }
                    NavigationLink(value: KKSURoute.testBuilder) { Label("Создать новый тест", systemImage: "hammer") }
                    if let assignmentID = lesson.assignmentID, let assignment = store.db.assignments.first(where: { $0.id == assignmentID }) {
                        KInfoRow(label: "Домашнее задание", value: "\(assignment.title), до \(assignment.dueDate.kksuShort)")
                        Button("Отвязать задание", role: .destructive) { store.db.schoolCourses[c].lessons[l].assignmentID = nil }
                    } else {
                        TextField("Домашнее задание (что сделать)", text: $homeworkTitle, axis: .vertical)
                        DatePicker("Срок", selection: $homeworkDue)
                        Button("Задать домашнее задание") {
                            let assignment = Assignment(title: lesson.title + ": домашнее задание", subject: course.subject.isEmpty ? course.title : course.subject,
                                                        details: homeworkTitle, teacherID: store.currentUser?.id, dueDate: homeworkDue,
                                                        assignedIDs: course.studentIDs)
                            store.publish(assignment)
                            store.db.schoolCourses[c].lessons[l].assignmentID = assignment.id
                            homeworkTitle = ""
                        }
                        .disabled(homeworkTitle.isEmpty)
                    }
                } header: {
                    Text("Проверка знаний")
                }
            }
            .navigationTitle(lesson.title)
        } else {
            KEmptyState(text: "Урок удалён", icon: "trash")
        }
    }
}

// MARK: - Курсы для ученика

struct SchoolCoursesView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Курсы") {
            if store.role.canTeach {
                NavigationLink(value: KKSURoute.courseStudio) {
                    Label("Мои курсы (конструктор)", systemImage: "square.and.pencil").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            StudentScoped { studentID in
                let courses = store.courses(for: studentID)
                if courses.isEmpty { KEmptyState(text: "Пока нет курсов", icon: "book.closed") }
                ForEach(courses) { course in
                    NavigationLink { SchoolCourseDetailView(courseID: course.id) } label: {
                        KCard {
                            HStack {
                                Image(systemName: course.icon).font(.title2).foregroundStyle(.tint)
                                    .frame(width: 44, height: 44)
                                    .background(KKSUTheme.softBlue, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.title).font(.headline)
                                    Text("\(course.subject) · \(store.userName(course.teacherID)) · уроков: \(course.publishedLessons.count)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                PriceBadge(product: store.product(forRef: course.id))
                            }
                            KProgressBar(value: store.courseProgress(course, studentID: studentID), color: KKSUTheme.success)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SchoolCourseDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let courseID: UUID
    var previewAsTeacher = false

    var body: some View {
        if let course = store.course(courseID) {
            let studentID = store.role == .student ? store.currentUser?.id : store.visibleStudents.first?.id
            KPage(course.title) {
                KCard {
                    Label(course.subject, systemImage: course.icon).font(.caption).foregroundStyle(.tint)
                    Text(course.title).font(.title2.bold())
                    if !course.summary.isEmpty { Text(course.summary) }
                    Text("Педагог: \(store.userName(course.teacherID))").font(.caption).foregroundStyle(.secondary)
                    if let studentID, !previewAsTeacher {
                        let progress = store.courseProgress(course, studentID: studentID)
                        KProgressBar(value: progress, color: KKSUTheme.success)
                        Text("Пройдено \(Int(progress * 100))%").font(.caption)
                    }
                }
                PaywallGate(product: previewAsTeacher ? nil : store.product(forRef: courseID),
                            message: "Платный курс. Уроки откроются после покупки или по подписке KKSU.") {
                    ForEach(Array(course.publishedLessons.enumerated()), id: \.element.id) { index, lesson in
                        NavigationLink { LessonPlayerView(courseID: courseID, lessonID: lesson.id) } label: {
                            KCard {
                                HStack(alignment: .top) {
                                    let done = studentID.map { store.isLessonCompleted(lesson.id, studentID: $0) } ?? false
                                    Image(systemName: done ? "checkmark.circle.fill" : "\(min(index + 1, 50)).circle")
                                        .font(.title2)
                                        .foregroundStyle(done ? KKSUTheme.success : KKSUTheme.primary)
                                    LessonRow(lesson: lesson, index: index + 1)
                                    Spacer()
                                    if let start = lesson.liveStart, start > Date() {
                                        KBadge(text: start.formatted(.relative(presentation: .named)), color: KKSUTheme.accent)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if course.publishedLessons.isEmpty { KEmptyState(text: "Уроки скоро появятся", icon: "hourglass") }
                }
            }
        } else {
            KEmptyState(text: "Курс не найден", icon: "book.closed")
        }
    }
}

// MARK: - Урок для ученика

struct LessonPlayerView: View {
    @EnvironmentObject private var store: KKSUStore
    let courseID: UUID
    let lessonID: UUID
    @State private var question = ""
    @State private var sent = false

    var body: some View {
        if let course = store.course(courseID), let lesson = course.lessons.first(where: { $0.id == lessonID }) {
            let me = store.currentUser
            let isStudent = me?.role == .student
            KPage(lesson.title) {
                if !lesson.summary.isEmpty { Text(lesson.summary).foregroundStyle(.secondary) }

                if lesson.hasLive {
                    LiveLessonCard(lesson: lesson)
                }

                if !lesson.videoURL.isEmpty {
                    KCard {
                        Label("Видео урока", systemImage: "play.rectangle.fill").font(.headline)
                        YouTubePlayer(url: lesson.videoURL)
                    }
                }

                if !lesson.notes.isEmpty {
                    KCard {
                        Label("Конспект", systemImage: "text.alignleft").font(.headline)
                        LessonNotesText(text: lesson.notes)
                    }
                }

                if !lesson.attachments.isEmpty || !lesson.links.isEmpty {
                    KCard {
                        Label("Материалы", systemImage: "paperclip").font(.headline)
                        ForEach(lesson.attachments) { AttachmentRow(attachment: $0) }
                        ForEach(lesson.links) { link in
                            if let url = URL(string: link.url) {
                                Link(destination: url) { Label(link.title, systemImage: "link") }
                            }
                        }
                    }
                }

                if let testID = lesson.testID, let test = store.db.tests.first(where: { $0.id == testID }) {
                    TestCard(test: test)
                }

                if let assignmentID = lesson.assignmentID,
                   let assignment = store.db.assignments.first(where: { $0.id == assignmentID }),
                   let me, isStudent {
                    NavigationLink { AssignmentDetailView(assignment: assignment, studentID: me.id) } label: {
                        DeadlineRow(assignment: assignment)
                    }
                    .buttonStyle(.plain)
                }

                if let me, isStudent {
                    let done = store.isLessonCompleted(lessonID, studentID: me.id)
                    Button {
                        store.toggleLessonCompleted(courseID: courseID, lessonID: lessonID, studentID: me.id)
                    } label: {
                        Label(done ? "Урок пройден" : "Отметить урок пройденным", systemImage: done ? "checkmark.circle.fill" : "circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(done ? KKSUTheme.success : KKSUTheme.primary)

                    if course.teacherID != nil {
                        KCard {
                            Label("Вопрос учителю", systemImage: "questionmark.bubble").font(.headline)
                            TextField("Что непонятно в уроке?", text: $question, axis: .vertical)
                                .lineLimit(2...6)
                                .textFieldStyle(.roundedBorder)
                            Button("Отправить в чат") {
                                store.askTeacher(course: course, lesson: lesson, question: question)
                                question = ""
                                sent = true
                            }
                            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty)
                            if sent { Text("Вопрос отправлен учителю в чат.").font(.caption).foregroundStyle(KKSUTheme.success) }
                        }
                    }
                }
            }
        } else {
            KEmptyState(text: "Урок не найден", icon: "book.closed")
        }
    }
}

struct LiveLessonCard: View {
    let lesson: CourseLesson

    var body: some View {
        let now = Date()
        let isLive = (lesson.liveStart ?? .distantFuture) <= now.addingTimeInterval(10 * 60) && (lesson.liveEnd ?? .distantPast) >= now
        KCard {
            HStack {
                Label("Онлайн-урок", systemImage: "video.fill").font(.headline)
                Spacer()
                if isLive { KBadge(text: "Идёт сейчас", color: KKSUTheme.danger) }
            }
            if let start = lesson.liveStart {
                Text("\(start.kksuDateTime) · \(lesson.liveDurationMinutes) мин · \(lesson.livePlatform.title)").font(.callout)
            }
            if let url = lesson.joinURL {
                Link(destination: url) {
                    Label("Подключиться", systemImage: "video.badge.checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
