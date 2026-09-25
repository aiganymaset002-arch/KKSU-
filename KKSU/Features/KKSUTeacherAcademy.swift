//
//  KKSUTeacherAcademy.swift
//  KKSU Online
//
//  KKSU Teacher Academy (37), регистрация педагогов (38), курсы ПК (39),
//  задания и тесты педагогов (41), электронные сертификаты (42, 99),
//  каталог авторских методик (43), апробация (44), экспертная оценка (45),
//  реестр результатов апробации (46).
//

import SwiftUI
import Charts

// MARK: - Главная Teacher Academy (задача 37)

struct TeacherAcademyView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        let registered = store.db.academyProfiles.contains { $0.userID == me }
        let myCourses = store.db.teacherCourses.filter { course in me.map { course.enrolledIDs.contains($0) } ?? false }
        KPage("KKSU Teacher Academy") {
            KCard {
                Label("Академия педагогов KKSU", systemImage: "building.columns.fill").font(.title3.bold()).foregroundStyle(.tint)
                Text("Повышение квалификации, методическая библиотека, авторские методики KKSU, их апробация и экспертиза.")
                    .font(.callout)
                if !registered {
                    NavigationLink(value: KKSURoute.academyRegistration) {
                        Label("Зарегистрироваться в Academy", systemImage: "person.badge.plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    KBadge(text: "Вы слушатель Academy", color: KKSUTheme.success)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Курсов", value: "\(store.db.teacherCourses.count)", icon: "person.crop.rectangle.stack.fill")
                KStatTile(title: "Слушателей", value: "\(store.db.academyProfiles.count)", icon: "person.3.fill", color: KKSUTheme.accent)
                KStatTile(title: "Авторских методик", value: "\(store.db.methodologies.count)", icon: "lightbulb.2.fill", color: KKSUTheme.success)
                KStatTile(title: "Сертификатов выдано", value: "\(store.db.certificates.filter { $0.issuer == .teacherAcademy }.count)", icon: "doc.badge.ellipsis", color: .purple)
            }
            if !myCourses.isEmpty {
                KSectionHeader(title: "Мои курсы", icon: "book.fill")
                ForEach(myCourses) { TeacherCourseCard(course: $0) }
            }
            RouteRow(route: .teacherCertification, subtitle: "Платная сертификация преподавателя KKSU")
            RouteRow(route: .teacherMarketplace, subtitle: "Разместите свой курс в каталоге KKSU")
            KSectionHeader(title: "Разделы", icon: "square.grid.2x2")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach([KKSURoute.academyCourses, .academyLibrary, .academyTasks, .certificates, .methodologies, .pilots, .methodologyReview, .pilotRegistry], id: \.self) {
                    RouteTile(route: $0)
                }
            }
        }
    }
}

// MARK: - Регистрация педагога (задача 38)

struct AcademyRegistrationView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var specialization = ""
    @State private var experience = 3
    @State private var organization = "KKSU"
    @State private var done = false

    var body: some View {
        let me = store.currentUser?.id
        let existing = store.db.academyProfiles.first { $0.userID == me }
        Form {
            if let existing {
                Section("Вы зарегистрированы") {
                    KInfoRow(label: "Специализация", value: existing.specialization)
                    KInfoRow(label: "Стаж", value: "\(existing.experienceYears) лет")
                    KInfoRow(label: "Организация", value: existing.organization)
                    KInfoRow(label: "Дата регистрации", value: existing.date.kksuShort)
                }
                Section { RouteRow(route: .academyCourses) }
            } else {
                Section("Анкета педагога") {
                    TextField("Специализация (предметы)", text: $specialization)
                    Stepper("Педагогический стаж: \(experience) лет", value: $experience, in: 0...50)
                    TextField("Организация", text: $organization)
                }
                Section {
                    Button("Зарегистрироваться") {
                        guard let me else { return }
                        store.db.academyProfiles.append(TeacherAcademyProfile(userID: me, specialization: specialization, experienceYears: experience, organization: organization))
                        store.notify(me, "Добро пожаловать в Teacher Academy", "Выберите курс повышения квалификации.", kind: .system)
                        store.log(me, "Регистрация в Teacher Academy", icon: "building.columns")
                        done = true
                    }
                    .disabled(specialization.isEmpty)
                }
            }
        }
        .navigationTitle("Регистрация в Academy")
    }
}

// MARK: - Курсы повышения квалификации (задача 39)

struct AcademyCoursesView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false

    var body: some View {
        KPage("Курсы повышения квалификации") {
            ForEach(store.db.teacherCourses) { TeacherCourseCard(course: $0) }
            if store.role == .admin || store.role == .expert {
                PrimaryButton(title: "Добавить курс", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { TeacherCourseEditorView() } }
    }
}

struct TeacherCourseCard: View {
    @EnvironmentObject private var store: KKSUStore
    let course: TeacherCourse

    var body: some View {
        let me = store.currentUser?.id
        let enrolled = me.map { course.enrolledIDs.contains($0) } ?? false
        let done = me.flatMap { course.completedModules[$0.uuidString] } ?? []
        KCard {
            HStack {
                Text(course.title).font(.headline)
                Spacer()
                PriceBadge(product: store.product(forRef: course.id))
                KBadge(text: "\(course.hours) ч")
            }
            Text("\(course.level) · модулей: \(course.modules.count) · слушателей: \(course.enrolledIDs.count)").font(.caption).foregroundStyle(.secondary)
            Text(course.summary).font(.callout)
            if enrolled {
                KProgressBar(value: course.modules.isEmpty ? 0 : Double(done.count) / Double(course.modules.count), color: KKSUTheme.success)
                NavigationLink("Продолжить обучение") { TeacherCourseDetailView(courseID: course.id) }
            } else {
                PaywallGate(product: store.product(forRef: course.id), message: "Платная программа Teacher Academy. Запись откроется после подтверждения оплаты.") {
                    Button("Записаться на курс") { store.enroll(inTeacherCourse: course.id) }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct TeacherCourseDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let courseID: UUID

    var body: some View {
        if let course = store.db.teacherCourses.first(where: { $0.id == courseID }) {
            let me = store.currentUser?.id
            let done = me.flatMap { course.completedModules[$0.uuidString] } ?? []
            let completed = me.map { course.completedIDs.contains($0) } ?? false
            KPage(course.title) {
                KCard {
                    Text(course.summary)
                    KProgressBar(value: course.modules.isEmpty ? 0 : Double(done.count) / Double(course.modules.count), color: KKSUTheme.success)
                    Text("Пройдено модулей: \(done.count) из \(course.modules.count)").font(.caption)
                    if completed {
                        Label("Курс завершён — сертификат выдан", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                    }
                }
                KSectionHeader(title: "Модули", icon: "list.number")
                ForEach(course.modules, id: \.self) { module in
                    Button {
                        store.toggleModule(module, courseID: course.id)
                    } label: {
                        HStack {
                            Image(systemName: done.contains(module) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(done.contains(module) ? KKSUTheme.success : .secondary)
                            Text(module)
                            Spacer()
                        }
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                KSectionHeader(title: "Задания и тесты курса", icon: "pencil.and.list.clipboard")
                ForEach(store.db.assignments.filter { $0.courseID == course.id }) { TeacherTaskCard(assignment: $0) }
                ForEach(store.db.tests.filter { $0.courseID == course.id }) { TestCard(test: $0) }
            }
        }
    }
}

struct TeacherCourseEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var course = TeacherCourse(title: "", hours: 36, level: "Базовый", summary: "", modules: [])
    @State private var modules = ""

    var body: some View {
        Form {
            TextField("Название", text: $course.title)
            Stepper("Часов: \(course.hours)", value: $course.hours, in: 4...300, step: 4)
            Picker("Уровень", selection: $course.level) {
                ForEach(["Базовый", "Средний", "Продвинутый"], id: \.self) { Text($0) }
            }
            TextField("Описание", text: $course.summary, axis: .vertical)
            TextField("Модули (каждый с новой строки)", text: $modules, axis: .vertical)
        }
        .navigationTitle("Новый курс")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    course.modules = modules.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    store.db.teacherCourses.append(course)
                    dismiss()
                }
                .disabled(course.title.isEmpty || modules.isEmpty)
            }
        }
    }
}

// MARK: - Задания и тестирование педагогов (задача 41)

struct AcademyTasksView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false

    var body: some View {
        KPage("Задания и тесты педагогов") {
            KSectionHeader(title: "Практические задания", icon: "pencil.and.list.clipboard")
            ForEach(store.db.assignments.filter { $0.audience == .teachers }) { TeacherTaskCard(assignment: $0) }
            if store.role == .admin || store.role == .expert {
                Button { showEditor = true } label: { Label("Добавить задание для педагогов", systemImage: "plus") }
            }
            KSectionHeader(title: "Тесты", icon: "checklist")
            ForEach(store.db.tests.filter { $0.audience == .teachers }) { TestCard(test: $0) }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { TeacherTaskEditorView() } }
    }
}

struct TeacherTaskCard: View {
    @EnvironmentObject private var store: KKSUStore
    let assignment: Assignment

    var body: some View {
        let me = store.currentUser?.id
        let submission = me.flatMap { store.submission(for: assignment.id, studentID: $0) }
        KCard {
            Text(assignment.title).font(.headline)
            Text(assignment.details).font(.callout)
            Text("Срок: \(assignment.dueDate.kksuShort)").font(.caption).foregroundStyle(.secondary)
            if let submission {
                SubmissionSummaryRow(submission: submission)
            } else if let me, store.role == .teacher || store.role == .psychologist {
                NavigationLink("Выполнить задание") { AssignmentDetailView(assignment: assignment, studentID: me) }
            }
            if store.role == .expert || store.role == .admin {
                NavigationLink("Работы слушателей: \(store.db.submissions.filter { $0.assignmentID == assignment.id }.count)") {
                    SubmissionsForAssignmentView(assignmentID: assignment.id)
                }
            }
        }
    }
}

struct TeacherTaskEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var assignment = Assignment(title: "", subject: "Teacher Academy", details: "", dueDate: Date().addingTimeInterval(14 * 86400), audience: .teachers)

    var body: some View {
        Form {
            TextField("Название", text: $assignment.title)
            TextField("Описание", text: $assignment.details, axis: .vertical)
            DatePicker("Срок", selection: $assignment.dueDate)
            Picker("Курс", selection: $assignment.courseID) {
                Text("Без курса").tag(UUID?.none)
                ForEach(store.db.teacherCourses) { Text($0.title).tag(UUID?.some($0.id)) }
            }
        }
        .navigationTitle("Задание для педагогов")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    assignment.teacherID = store.currentUser?.id
                    store.db.assignments.append(assignment)
                    for teacher in store.users(with: .teacher) {
                        store.notify(teacher.id, "Новое задание Teacher Academy", assignment.title, kind: .deadline)
                    }
                    dismiss()
                }
                .disabled(assignment.title.isEmpty)
            }
        }
    }
}

// MARK: - Электронные сертификаты (задачи 23, 42, 99)

struct CertificatesView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var verifyCode = ""

    var body: some View {
        let me = store.currentUser?.id
        let mine = store.db.certificates.filter { $0.userID == me }
        let all = store.role == .admin ? store.db.certificates : mine
        KPage("Электронные сертификаты") {
            if all.isEmpty { KEmptyState(text: "Сертификатов пока нет. Они выдаются автоматически после курсов, мероприятий и конкурсов.", icon: "doc.badge.ellipsis") }
            ForEach(all.sorted { $0.date > $1.date }) { CertificateCard(certificate: $0) }
            KCard {
                Text("Проверка подлинности").font(.headline)
                TextField("Код сертификата (KKSU-...)", text: $verifyCode).textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                if !verifyCode.isEmpty {
                    if let found = store.db.certificates.first(where: { $0.verificationCode.caseInsensitiveCompare(verifyCode.trimmingCharacters(in: .whitespaces)) == .orderedSame }) {
                        Label("Действителен: \(found.recipientName) — \(found.title)", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                    } else {
                        Label("Сертификат не найден", systemImage: "xmark.seal").foregroundStyle(KKSUTheme.danger)
                    }
                }
            }
        }
    }
}

struct CertificateCard: View {
    let certificate: Certificate
    @State private var pdfURL: URL?

    var body: some View {
        KCard {
            HStack(alignment: .top) {
                Image(systemName: "rosette").font(.largeTitle).foregroundStyle(KKSUTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.title).font(.headline)
                    Text(certificate.issuer.title).font(.caption).foregroundStyle(.secondary)
                    Text("\(certificate.recipientName) · \(certificate.date.kksuShort)\(certificate.hours.map { " · \($0) ч" } ?? "")").font(.caption)
                    Text(certificate.verificationCode).font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
            }
            if let pdfURL {
                ShareLink(item: pdfURL) { Label("Скачать PDF", systemImage: "arrow.down.doc.fill") }
            } else {
                Button { pdfURL = KKSUPDF.certificate(certificate) } label: { Label("Сформировать PDF", systemImage: "doc.richtext") }
            }
        }
    }
}

/// Макет сертификата для PDF (A4, альбомная ориентация).
struct CertificatePDFPage: View {
    let certificate: Certificate

    var body: some View {
        ZStack {
            Color.white
            RoundedRectangle(cornerRadius: 12).stroke(KKSUTheme.primary, lineWidth: 6).padding(24)
            RoundedRectangle(cornerRadius: 8).stroke(KKSUTheme.accent, lineWidth: 2).padding(40)
            VStack(spacing: 18) {
                Text("KKSU ONLINE").font(.system(size: 20, weight: .heavy)).foregroundColor(KKSUTheme.primary).tracking(6)
                Text("СЕРТИФИКАТ").font(.system(size: 48, weight: .bold)).foregroundColor(KKSUTheme.primary)
                Text("подтверждает, что").font(.system(size: 16)).foregroundColor(.gray)
                Text(certificate.recipientName).font(.system(size: 34, weight: .semibold)).foregroundColor(.black)
                Text(certificate.title).font(.system(size: 20)).multilineTextAlignment(.center).foregroundColor(.black).padding(.horizontal, 80)
                if let hours = certificate.hours {
                    Text("Объём: \(hours) академических часов").font(.system(size: 14)).foregroundColor(.black)
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text(certificate.issuer.title).font(.system(size: 14, weight: .semibold))
                        Text("Дата выдачи: \(certificate.date.kksuShort)").font(.system(size: 12))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Код проверки").font(.system(size: 11)).foregroundColor(.gray)
                        Text(certificate.verificationCode).font(.system(size: 13, design: .monospaced))
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 80)
                .padding(.top, 20)
            }
        }
        .frame(width: 842, height: 595)
    }
}

// MARK: - Авторские методики (задача 43)

struct MethodologyCatalogView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var status: MethodologyStatus?
    @State private var showEditor = false

    var body: some View {
        KPage("Авторские методики KKSU") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все", selected: status == nil) { status = nil }
                    ForEach(MethodologyStatus.allCases) { item in
                        FilterChip(title: item.title, selected: status == item) { status = item }
                    }
                }
            }
            ForEach(store.db.methodologies.filter { status == nil || $0.status == status }) { method in
                NavigationLink { MethodologyDetailView(methodologyID: method.id) } label: { MethodologyCard(methodology: method) }
                    .buttonStyle(.plain)
            }
            if store.role == .teacher || store.role == .psychologist || store.role == .admin {
                PrimaryButton(title: "Предложить методику", icon: "plus", style: .outlined) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { MethodologyEditorView() } }
    }
}

struct MethodologyCard: View {
    @EnvironmentObject private var store: KKSUStore
    let methodology: Methodology

    var body: some View {
        let reviews = store.reviews(for: methodology.id)
        let avg = reviews.isEmpty ? nil : reviews.map(\.average).reduce(0, +) / Double(reviews.count)
        KCard {
            HStack {
                Text(methodology.title).font(.headline)
                Spacer()
                KBadge(text: methodology.status.title, color: methodology.status == .approved ? KKSUTheme.success : KKSUTheme.primary)
            }
            Text("\(methodology.author) · \(methodology.subject) · \(methodology.ageGroup) лет").font(.caption).foregroundStyle(.secondary)
            Text(methodology.summary).font(.callout).lineLimit(3)
            HStack {
                Label("\(store.db.pilots.filter { $0.methodologyID == methodology.id }.count) апробаций", systemImage: "testtube.2")
                if let avg { Label(String(format: "%.1f / 10", avg), systemImage: "star.fill") }
            }
            .font(.caption)
        }
    }
}

struct MethodologyDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let methodologyID: UUID
    @State private var attachments: [Attachment] = []

    var body: some View {
        if let index = store.db.methodologies.firstIndex(where: { $0.id == methodologyID }) {
            let method = store.db.methodologies[index]
            KPage(method.title) {
                MethodologyCard(methodology: method)
                KCard {
                    Text("Материалы методики").font(.headline)
                    ForEach(method.documents) { AttachmentRow(attachment: $0) }
                    if store.role == .teacher || store.role == .admin {
                        AttachmentPicker(attachments: $attachments)
                        if !attachments.isEmpty {
                            Button("Прикрепить файлы") {
                                store.db.methodologies[index].documents += attachments
                                attachments = []
                            }
                        }
                    }
                }
                if store.role == .admin {
                    Picker("Статус", selection: $store.db.methodologies[index].status) {
                        ForEach(MethodologyStatus.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                KSectionHeader(title: "Апробация", icon: "testtube.2")
                ForEach(store.db.pilots.filter { $0.methodologyID == method.id }) { PilotCard(pilot: $0) }
                NavigationLink { PilotEditorView(methodologyID: method.id) } label: { Label("Добавить результаты апробации", systemImage: "plus") }
                KSectionHeader(title: "Экспертные оценки", icon: "star.leadinghalf.filled")
                ForEach(store.reviews(for: method.id)) { ReviewCard(review: $0) }
                if store.role.canReview {
                    NavigationLink { ExpertReviewFormView(targetID: method.id, target: .methodology, criteria: ExpertReview.methodologyCriteria) } label: {
                        Label("Провести экспертную оценку", systemImage: "checkmark.seal")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct MethodologyEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var method = Methodology(title: "", author: "", subject: "", ageGroup: "7–12", summary: "")

    var body: some View {
        Form {
            TextField("Название методики", text: $method.title)
            TextField("Автор(ы)", text: $method.author)
            TextField("Предмет / область", text: $method.subject)
            TextField("Возрастная группа", text: $method.ageGroup)
            TextField("Описание: цель, подход, ожидаемые результаты", text: $method.summary, axis: .vertical)
        }
        .navigationTitle("Новая методика")
        .onAppear { method.author = store.currentUser?.fullName ?? "" }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    store.db.methodologies.append(method)
                    for expert in store.users(with: .expert) {
                        store.notify(expert.id, "Новая методика", method.title, kind: .info)
                    }
                    dismiss()
                }
                .disabled(method.title.isEmpty || method.summary.isEmpty)
            }
        }
    }
}

// MARK: - Апробация методик (задачи 44, 46)

struct PilotsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Апробация методик") {
            Text("Методики в статусе «Апробация» проверяются на площадках KKSU и партнёров. Результаты вносятся в реестр.")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(store.db.methodologies.filter { $0.status == .piloting || $0.status == .reviewed }) { method in
                KCard {
                    Text(method.title).font(.headline)
                    Text("Площадок: \(store.db.pilots.filter { $0.methodologyID == method.id }.count)").font(.caption)
                    NavigationLink { PilotEditorView(methodologyID: method.id) } label: { Label("Внести результаты", systemImage: "plus.circle") }
                    NavigationLink { MethodologyDetailView(methodologyID: method.id) } label: { Label("Карточка методики", systemImage: "doc.text") }
                }
            }
            if store.role == .admin || store.role == .teacher {
                KSectionHeader(title: "Отправить методику на апробацию", icon: "paperplane")
                ForEach(store.db.methodologies.filter { $0.status == .draft }) { method in
                    HStack {
                        Text(method.title)
                        Spacer()
                        Button("На апробацию") {
                            if let index = store.db.methodologies.firstIndex(where: { $0.id == method.id }) {
                                store.db.methodologies[index].status = .piloting
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            RouteRow(route: .pilotRegistry, subtitle: "Все результаты апробации")
        }
    }
}

struct PilotEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let methodologyID: UUID
    @State private var site = ""
    @State private var teacher = ""
    @State private var start = Date().addingTimeInterval(-60 * 86400)
    @State private var end = Date()
    @State private var participants = 20
    @State private var baseline = 55.0
    @State private var finalScore = 70.0
    @State private var summary = ""

    var body: some View {
        Form {
            Section("Площадка") {
                TextField("Школа / класс", text: $site)
                TextField("Педагог", text: $teacher)
                DatePicker("Начало", selection: $start, displayedComponents: .date)
                DatePicker("Окончание", selection: $end, displayedComponents: .date)
                Stepper("Участников: \(participants)", value: $participants, in: 1...1000)
            }
            Section("Результаты (средний балл, 0–100)") {
                VStack(alignment: .leading) {
                    Text("До апробации: \(Int(baseline))")
                    Slider(value: $baseline, in: 0...100, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("После апробации: \(Int(finalScore))")
                    Slider(value: $finalScore, in: 0...100, step: 1)
                }
                Text(String(format: "Прирост: %+.1f%%", baseline == 0 ? 0 : (finalScore - baseline) / baseline * 100)).bold()
                TextField("Выводы", text: $summary, axis: .vertical)
            }
        }
        .navigationTitle("Результаты апробации")
        .onAppear { if teacher.isEmpty { teacher = store.currentUser?.fullName ?? "" } }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    store.db.pilots.append(MethodologyPilot(methodologyID: methodologyID, site: site, teacherName: teacher, startDate: start, endDate: end, participants: participants, baselineScore: baseline, finalScore: finalScore, summary: summary))
                    dismiss()
                }
                .disabled(site.isEmpty)
            }
        }
    }
}

struct PilotCard: View {
    let pilot: MethodologyPilot

    var body: some View {
        KCard {
            HStack {
                Text(pilot.site).font(.headline)
                Spacer()
                KBadge(text: String(format: "%+.0f%%", pilot.growthPercent), color: pilot.growthPercent >= 0 ? KKSUTheme.success : KKSUTheme.danger)
            }
            Text("\(pilot.teacherName) · \(pilot.startDate.kksuShort) – \(pilot.endDate.kksuShort) · \(pilot.participants) уч.").font(.caption).foregroundStyle(.secondary)
            Text("Средний балл: \(Int(pilot.baselineScore)) → \(Int(pilot.finalScore))").font(.callout)
            if !pilot.summary.isEmpty { Text(pilot.summary).font(.callout) }
        }
    }
}

struct PilotRegistryView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let pilots = store.db.pilots.sorted { $0.endDate > $1.endDate }
        KPage("Реестр результатов апробации") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Апробаций", value: "\(pilots.count)", icon: "testtube.2")
                KStatTile(title: "Участников", value: "\(pilots.reduce(0) { $0 + $1.participants })", icon: "person.3.fill", color: KKSUTheme.accent)
                KStatTile(title: "Средний прирост", value: pilots.isEmpty ? "—" : String(format: "%+.0f%%", pilots.map(\.growthPercent).reduce(0, +) / Double(pilots.count)), icon: "chart.line.uptrend.xyaxis", color: KKSUTheme.success)
            }
            if !pilots.isEmpty {
                KCard {
                    Text("Результат до и после").font(.headline)
                    Chart {
                        ForEach(pilots) { pilot in
                            BarMark(x: .value("Площадка", pilot.site), y: .value("Балл", pilot.baselineScore))
                                .foregroundStyle(by: .value("Этап", "До"))
                                .position(by: .value("Этап", "До"))
                            BarMark(x: .value("Площадка", pilot.site), y: .value("Балл", pilot.finalScore))
                                .foregroundStyle(by: .value("Этап", "После"))
                                .position(by: .value("Этап", "После"))
                        }
                    }
                    .frame(height: 220)
                }
            }
            ForEach(pilots) { pilot in
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.db.methodologies.first { $0.id == pilot.methodologyID }?.title ?? "Методика").font(.caption.bold())
                    PilotCard(pilot: pilot)
                }
            }
            if let url = csvURL(pilots) {
                ShareLink(item: url) { Label("Экспорт реестра в CSV", systemImage: "tablecells") }
            }
        }
    }

    private func csvURL(_ pilots: [MethodologyPilot]) -> URL? {
        var csv = "Методика;Площадка;Педагог;Начало;Окончание;Участников;До;После;Прирост %\n"
        for p in pilots {
            let title = store.db.methodologies.first { $0.id == p.methodologyID }?.title ?? ""
            csv += "\(title);\(p.site);\(p.teacherName);\(p.startDate.kksuShort);\(p.endDate.kksuShort);\(p.participants);\(Int(p.baselineScore));\(Int(p.finalScore));\(String(format: "%.1f", p.growthPercent))\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KKSU-pilot-registry.csv")
        return (try? csv.data(using: .utf8)?.write(to: url)) != nil ? url : nil
    }
}

// MARK: - Экспертная оценка (задачи 45, 58)

struct MethodologyReviewQueueView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        KPage("Экспертная оценка методик") {
            ForEach(store.db.methodologies.filter { $0.status != .draft }) { method in
                let reviewed = store.db.reviews.contains { $0.targetID == method.id && $0.expertID == me }
                KCard {
                    MethodologyCard(methodology: method)
                    if reviewed {
                        Label("Вы уже оценили эту методику", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success).font(.caption)
                    } else {
                        NavigationLink { ExpertReviewFormView(targetID: method.id, target: .methodology, criteria: ExpertReview.methodologyCriteria) } label: {
                            Label("Оценить", systemImage: "star.leadinghalf.filled")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

struct ExpertReviewFormView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let targetID: UUID
    let target: ReviewTarget
    let criteria: [String]
    @State private var scores: [String: Int] = [:]
    @State private var comment = ""
    @State private var decision: ReviewDecision = .approve

    var body: some View {
        Form {
            Section("Критерии (1–10)") {
                ForEach(criteria, id: \.self) { criterion in
                    Stepper("\(criterion): \(scores[criterion] ?? 7)", value: Binding(get: { scores[criterion] ?? 7 }, set: { scores[criterion] = $0 }), in: 1...10)
                }
                let avg = Double(criteria.reduce(0) { $0 + (scores[$1] ?? 7) }) / Double(max(criteria.count, 1))
                Text(String(format: "Средний балл: %.1f", avg)).bold()
            }
            Section("Заключение") {
                Picker("Решение", selection: $decision) {
                    ForEach(ReviewDecision.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField("Комментарий эксперта", text: $comment, axis: .vertical)
            }
            Section {
                Button("Отправить заключение") {
                    guard let me = store.currentUser?.id else { return }
                    let review = ExpertReview(targetID: targetID, target: target, expertID: me,
                                              scores: criteria.map { ReviewScore(criterion: $0, score: scores[$0] ?? 7) },
                                              comment: comment, decision: decision)
                    store.submitReview(review)
                    dismiss()
                }
                .disabled(comment.isEmpty)
            }
        }
        .navigationTitle("Экспертная оценка")
    }
}

struct ReviewCard: View {
    @EnvironmentObject private var store: KKSUStore
    let review: ExpertReview

    var body: some View {
        KCard {
            HStack {
                Text(store.userName(review.expertID)).font(.headline)
                Spacer()
                Text(String(format: "%.1f", review.average)).font(.title3.bold()).foregroundStyle(.tint)
            }
            KBadge(text: review.decision.title, color: review.decision == .approve ? KKSUTheme.success : (review.decision == .revise ? KKSUTheme.warning : KKSUTheme.danger))
            ForEach(review.scores, id: \.criterion) { score in
                HStack {
                    Text(score.criterion).font(.caption)
                    Spacer()
                    KProgressBar(value: Double(score.score) / 10).frame(width: 100)
                    Text("\(score.score)").font(.caption.monospacedDigit())
                }
            }
            Text(review.comment).font(.callout)
            Text(review.date.kksuShort).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
