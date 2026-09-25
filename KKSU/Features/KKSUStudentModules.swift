//
//  KKSUStudentModules.swift
//  KKSU Online
//
//  Профиль (10), анкета (11), заявка (12), согласия (13), каталог (14),
//  траектория (15), учебный план (16), календарь (18), домашние задания (19),
//  загрузка работ (20), оценки (21), портфолио (22), достижения (23),
//  дашборд прогресса (24), история (25), дедлайны (36).
//

import SwiftUI
import Charts

// MARK: - Выбор ученика (для родителя, педагога и др.)

struct StudentScoped<Content: View>: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var selected: UUID?
    let content: (UUID) -> Content

    init(@ViewBuilder content: @escaping (UUID) -> Content) {
        self.content = content
    }

    var body: some View {
        let options = store.visibleStudents
        let current = selected ?? options.first?.id
        VStack(alignment: .leading, spacing: 16) {
            if options.count > 1 {
                Picker("Ученик", selection: Binding(get: { current }, set: { selected = $0 })) {
                    ForEach(options) { Text($0.fullName).tag(UUID?.some($0.id)) }
                }
                .pickerStyle(.menu)
            }
            if let current {
                content(current)
            } else {
                KEmptyState(text: "Нет доступных учеников", icon: "person.crop.circle.badge.questionmark")
            }
        }
    }
}

// MARK: - Профиль ученика (задача 10)

struct StudentProfileEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var newInterest = ""

    var body: some View {
        KPage("Профиль ученика") {
            StudentScoped { studentID in
                if let index = store.db.studentProfiles.firstIndex(where: { $0.userID == studentID }) {
                    KCard {
                        HStack(spacing: 14) {
                            KAvatar(name: store.userName(studentID), size: 64)
                            VStack(alignment: .leading) {
                                Text(store.userName(studentID)).font(.title3.bold())
                                Text("\(store.db.studentProfiles[index].age) лет · \(store.db.studentProfiles[index].grade) класс").foregroundStyle(.secondary)
                                KBadge(text: "\(store.db.studentProfiles[index].xp) XP", color: KKSUTheme.accent)
                            }
                        }
                    }
                    KCard {
                        Text("Основное").font(.headline)
                        DatePicker("Дата рождения", selection: $store.db.studentProfiles[index].birthDate, displayedComponents: .date)
                        TextField("Класс", text: $store.db.studentProfiles[index].grade).textFieldStyle(.roundedBorder)
                        TextField("Школа", text: $store.db.studentProfiles[index].school).textFieldStyle(.roundedBorder)
                        TextField("Город", text: $store.db.studentProfiles[index].city).textFieldStyle(.roundedBorder)
                    }
                    KCard {
                        Text("Интересы").font(.headline)
                        FlowTags(tags: store.db.studentProfiles[index].interests) { tag in
                            store.db.studentProfiles[index].interests.removeAll { $0 == tag }
                        }
                        HStack {
                            TextField("Добавить интерес", text: $newInterest).textFieldStyle(.roundedBorder)
                            Button("Добавить") {
                                let value = newInterest.trimmingCharacters(in: .whitespaces)
                                guard !value.isEmpty else { return }
                                store.db.studentProfiles[index].interests.append(value)
                                newInterest = ""
                            }
                        }
                    }
                    KCard {
                        Text("Цели и поддержка").font(.headline)
                        TextField("Мои цели", text: $store.db.studentProfiles[index].goals, axis: .vertical).textFieldStyle(.roundedBorder)
                        TextField("Особые образовательные потребности", text: $store.db.studentProfiles[index].specialNeeds, axis: .vertical).textFieldStyle(.roundedBorder)
                        Text("Эти данные видят только педагоги, психолог и родитель ученика.").font(.caption).foregroundStyle(.secondary)
                    }
                    RouteRow(route: .portfolio)
                    RouteRow(route: .achievements)
                } else {
                    KEmptyState(text: "Профиль ученика не создан")
                }
            }
        }
    }
}

struct FlowTags: View {
    let tags: [String]
    var onRemove: ((String) -> Void)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text(tag).lineLimit(1)
                    if let onRemove {
                        Button { onRemove(tag) } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Удалить \(tag)")
                    }
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(KKSUTheme.softBlue, in: Capsule())
            }
        }
    }
}

// MARK: - Анкета первичного поступления (задача 11)

struct IntakeQuestionnaireView: View {
    var body: some View {
        KPage("Анкета поступления") {
            StudentScoped { studentID in
                IntakeForm(studentID: studentID)
            }
        }
    }
}

struct IntakeForm: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID
    @State private var saved = false

    private let assistiveOptions = ["Субтитры", "Озвучивание текста", "Крупный шрифт", "FM-система", "Альтернативная коммуникация", "Коляска / пандус"]

    var body: some View {
        if let index = store.db.questionnaires.firstIndex(where: { $0.studentID == studentID }) {
            VStack(alignment: .leading, spacing: 14) {
                KCard {
                    Text("Формат обучения").font(.headline)
                    Picker("Формат", selection: $store.db.questionnaires[index].learningFormat) {
                        ForEach(LearningFormat.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                KCard {
                    Text("Об ученике").font(.headline)
                    TextField("Сильные стороны, увлечения", text: $store.db.questionnaires[index].strengths, axis: .vertical).textFieldStyle(.roundedBorder)
                    TextField("Трудности в обучении", text: $store.db.questionnaires[index].difficulties, axis: .vertical).textFieldStyle(.roundedBorder)
                    TextField("Особенности здоровья (по желанию)", text: $store.db.questionnaires[index].healthNotes, axis: .vertical).textFieldStyle(.roundedBorder)
                    TextField("Как удобнее общаться с ребёнком", text: $store.db.questionnaires[index].communication, axis: .vertical).textFieldStyle(.roundedBorder)
                }
                KCard {
                    Text("Вспомогательные технологии").font(.headline)
                    ForEach(assistiveOptions, id: \.self) { option in
                        Toggle(option, isOn: Binding(
                            get: { store.db.questionnaires[index].assistiveTech.contains(option) },
                            set: { on in
                                if on { store.db.questionnaires[index].assistiveTech.append(option) }
                                else { store.db.questionnaires[index].assistiveTech.removeAll { $0 == option } }
                            }))
                    }
                }
                KCard {
                    Text("Ожидания семьи").font(.headline)
                    TextField("Чего вы ждёте от обучения в KKSU", text: $store.db.questionnaires[index].parentExpectations, axis: .vertical).textFieldStyle(.roundedBorder)
                    Toggle("Нужна консультация психолога", isOn: $store.db.questionnaires[index].needsPsychologist)
                }
                PrimaryButton(title: "Отправить анкету", icon: "paperplane.fill") { submit(index: index) }
                if saved {
                    Label("Анкета сохранена и передана педагогам", systemImage: "checkmark.circle.fill").foregroundStyle(KKSUTheme.success)
                }
            }
        } else {
            SwiftUI.ProgressView()
                .onAppear {
                    if !store.db.questionnaires.contains(where: { $0.studentID == studentID }) {
                        store.db.questionnaires.append(IntakeQuestionnaire(studentID: studentID))
                    }
                }
        }
    }

    private func submit(index: Int) {
        store.db.questionnaires[index].date = Date()
        saved = true
        let needsPsychologist = store.db.questionnaires[index].needsPsychologist
        for staff in store.db.users where staff.role == .teacher || (staff.role == .psychologist && needsPsychologist) {
            store.notify(staff.id, "Заполнена анкета поступления", store.userName(studentID), kind: .info)
        }
        store.log(studentID, "Заполнена анкета поступления", icon: "list.clipboard")
    }
}

// MARK: - Онлайн-заявка на обучение (задача 12)

struct EnrollmentApplicationView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var app = EnrollmentApplication(childName: "", childAge: 10, parentName: "", email: "", phone: "")
    @State private var sent = false
    @State private var error: String?

    var body: some View {
        Form {
            if sent {
                Section {
                    Label("Заявка отправлена! Мы свяжемся с вами в течение 3 рабочих дней.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(KKSUTheme.success)
                    Button("Подать ещё одну заявку") {
                        app = EnrollmentApplication(childName: "", childAge: 10, parentName: "", email: "", phone: "")
                        sent = false
                    }
                }
            } else {
                Section("Ребёнок") {
                    TextField("ФИО ребёнка", text: $app.childName)
                    Stepper("Возраст: \(app.childAge)", value: $app.childAge, in: 5...18)
                }
                Section("Родитель / законный представитель") {
                    TextField("ФИО", text: $app.parentName)
                    TextField("Email", text: $app.email)
                        .autocorrectionDisabled()
                    TextField("Телефон", text: $app.phone)
                }
                Section("Обучение") {
                    Picker("Программа", selection: $app.programID) {
                        Text("Выберите программу").tag(UUID?.none)
                        ForEach(store.db.programs) { Text($0.title).tag(UUID?.some($0.id)) }
                    }
                    Picker("Формат", selection: $app.format) {
                        ForEach(LearningFormat.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Комментарий (особые потребности, пожелания)", text: $app.comment, axis: .vertical)
                }
                if let error {
                    Section { Text(error).foregroundStyle(KKSUTheme.danger) }
                }
                Section {
                    Button("Отправить заявку") { submit() }
                }
                if let user = store.currentUser {
                    let mine = store.db.applications.filter { $0.applicantUserID == user.id }
                    if !mine.isEmpty {
                        Section("Мои заявки") {
                            ForEach(mine) { item in
                                KInfoRow(label: item.childName, value: item.status.title)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Заявка на обучение")
        .onAppear {
            if let user = store.currentUser, app.parentName.isEmpty {
                app.parentName = user.fullName
                app.email = user.email
                app.phone = user.phone
            }
        }
    }

    private func submit() {
        guard !app.childName.isEmpty, !app.parentName.isEmpty, KKSUStore.isValidEmail(app.email), !app.phone.isEmpty else {
            error = "Заполните ФИО, телефон и корректный email."
            return
        }
        app.applicantUserID = store.currentUser?.id
        app.date = Date()
        store.db.applications.append(app)
        for admin in store.users(with: .admin) {
            store.notify(admin.id, "Новая заявка на обучение", "\(app.childName), \(app.childAge) лет", kind: .system)
        }
        error = nil
        sent = true
    }
}

// MARK: - Согласия родителей (задача 13)

struct ConsentsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Согласия родителей") {
            Text("Согласия подписываются электронно и могут быть отозваны в любой момент. Без согласия на обработку персональных данных обучение невозможно.")
                .font(.callout).foregroundStyle(.secondary)
            StudentScoped { studentID in
                ForEach(ConsentType.allCases) { type in
                    ConsentRow(studentID: studentID, type: type)
                }
            }
        }
    }
}

struct ConsentRow: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID
    let type: ConsentType

    var body: some View {
        let consent = store.db.consents.last { $0.studentID == studentID && $0.type == type }
        let granted = consent?.granted ?? false
        KCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title).font(.headline)
                    if type.isRequired { KBadge(text: "Обязательное", color: KKSUTheme.danger) }
                    if let consent {
                        Text("\(consent.granted ? "Подписано" : "Отозвано"): \(consent.signatureName), \(consent.date.kksuDateTime)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if store.role == .parent || store.role == .admin {
                    Button(granted ? "Отозвать" : "Подписать") { toggle(!granted) }
                        .buttonStyle(.borderedProminent)
                        .tint(granted ? KKSUTheme.danger : KKSUTheme.success)
                } else {
                    Image(systemName: granted ? "checkmark.seal.fill" : "xmark.seal")
                        .foregroundStyle(granted ? KKSUTheme.success : .secondary)
                }
            }
        }
    }

    private func toggle(_ grant: Bool) {
        guard let user = store.currentUser else { return }
        store.db.consents.append(ParentConsent(studentID: studentID, parentID: user.id, type: type, granted: grant, signatureName: user.fullName))
        store.log(studentID, grant ? "Подписано согласие" : "Отозвано согласие", details: type.title, icon: "signature")
    }
}

// MARK: - Каталог образовательных программ (задача 14)

struct ProgramCatalogView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var direction: ProgramDirection?
    @State private var editing: EducationProgram?

    var body: some View {
        KPage("Каталог программ") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все", selected: direction == nil) { direction = nil }
                    ForEach(ProgramDirection.allCases) { item in
                        FilterChip(title: item.title, selected: direction == item) { direction = item }
                    }
                }
            }
            ForEach(store.db.programs.filter { direction == nil || $0.direction == direction }) { program in
                KCard {
                    HStack {
                        Label(program.title, systemImage: program.direction.icon).font(.headline)
                        Spacer()
                        KBadge(text: program.direction.title)
                    }
                    Text(program.summary).font(.callout)
                    Text("Возраст: \(program.ageRange) · \(program.durationWeeks) недель · \(program.format.title) · мест: \(program.seats)")
                        .font(.caption).foregroundStyle(.secondary)
                    FlowTags(tags: program.subjects)
                    HStack {
                        NavigationLink("Подать заявку") { EnrollmentApplicationView() }
                        Spacer()
                        if store.role == .admin {
                            Button("Изменить") { editing = program }
                        }
                    }
                }
            }
            if store.role == .admin {
                Button {
                    editing = EducationProgram(title: "", direction: .school, ageRange: "7–18", durationWeeks: 12, format: .mixed, summary: "", subjects: [])
                } label: { Label("Добавить программу", systemImage: "plus") }
            }
        }
        .sheet(item: $editing) { program in
            NavigationStack { ProgramEditorView(program: program) }
        }
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.gray.opacity(0.15)), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ProgramEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State var program: EducationProgram
    @State private var subjects = ""

    var body: some View {
        Form {
            TextField("Название", text: $program.title)
            Picker("Направление", selection: $program.direction) {
                ForEach(ProgramDirection.allCases) { Text($0.title).tag($0) }
            }
            TextField("Возраст", text: $program.ageRange)
            Stepper("Недель: \(program.durationWeeks)", value: $program.durationWeeks, in: 1...104)
            Stepper("Мест: \(program.seats)", value: $program.seats, in: 1...500)
            Picker("Формат", selection: $program.format) {
                ForEach(LearningFormat.allCases) { Text($0.title).tag($0) }
            }
            TextField("Описание", text: $program.summary, axis: .vertical)
            TextField("Предметы через запятую", text: $subjects)
        }
        .navigationTitle(program.title.isEmpty ? "Новая программа" : program.title)
        .onAppear { subjects = program.subjects.joined(separator: ", ") }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    program.subjects = subjects.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    if let index = store.db.programs.firstIndex(where: { $0.id == program.id }) {
                        store.db.programs[index] = program
                    } else {
                        store.db.programs.append(program)
                    }
                    dismiss()
                }
                .disabled(program.title.isEmpty)
            }
        }
    }
}

// MARK: - Индивидуальная образовательная траектория (задача 15)

struct TrajectoryView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var newTitle = ""
    @State private var newDate = Date().addingTimeInterval(30 * 86400)
    @State private var newProgram: UUID?

    var body: some View {
        KPage("Образовательная траектория") {
            StudentScoped { studentID in
                let steps = store.db.trajectory.filter { $0.studentID == studentID }.sorted { $0.targetDate < $1.targetDate }
                let done = steps.filter { $0.status == .done }.count
                KCard {
                    Text("Пройдено шагов: \(done) из \(steps.count)").font(.headline)
                    KProgressBar(value: steps.isEmpty ? 0 : Double(done) / Double(steps.count))
                }
                ForEach(steps) { step in
                    if let index = store.db.trajectory.firstIndex(where: { $0.id == step.id }) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Image(systemName: step.status.icon)
                                    .font(.title2)
                                    .foregroundStyle(step.status == .done ? KKSUTheme.success : KKSUTheme.primary)
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity)
                            }
                            KCard {
                                Text(step.title).font(.headline)
                                if let program = store.program(step.programID) {
                                    Text(program.title).font(.caption).foregroundStyle(.secondary)
                                }
                                Text("Цель к \(step.targetDate.kksuShort)").font(.caption)
                                if !step.note.isEmpty { Text(step.note).font(.callout) }
                                Picker("Статус", selection: $store.db.trajectory[index].status) {
                                    ForEach(StepStatus.allCases) { Text($0.title).tag($0) }
                                }
                                .pickerStyle(.segmented)
                                .disabled(store.role == .parent)
                            }
                        }
                    }
                }
                if store.role != .parent {
                    KCard {
                        Text("Новый шаг траектории").font(.headline)
                        TextField("Цель", text: $newTitle).textFieldStyle(.roundedBorder)
                        DatePicker("Срок", selection: $newDate, displayedComponents: .date)
                        Picker("Программа", selection: $newProgram) {
                            Text("Без программы").tag(UUID?.none)
                            ForEach(store.db.programs) { Text($0.title).tag(UUID?.some($0.id)) }
                        }
                        Button("Добавить шаг") {
                            store.db.trajectory.append(TrajectoryStep(studentID: studentID, title: newTitle, programID: newProgram, targetDate: newDate))
                            store.log(studentID, "Новый шаг траектории", details: newTitle, icon: "point.topleft.down.to.point.bottomright.curvepath")
                            newTitle = ""
                        }
                        .disabled(newTitle.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Индивидуальный учебный план (задача 16)

struct StudyPlanView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var subject = ""
    @State private var hours = 2
    @State private var goal = ""
    @State private var adaptation = ""

    var body: some View {
        KPage("Индивидуальный учебный план") {
            StudentScoped { studentID in
                let items = store.db.studyPlan.filter { $0.studentID == studentID }
                KCard {
                    Text("Нагрузка: \(items.reduce(0) { $0 + $1.hoursPerWeek }) ч/нед").font(.headline)
                    Chart(items) { item in
                        BarMark(x: .value("Часы", item.hoursPerWeek), y: .value("Предмет", item.subject))
                            .foregroundStyle(KKSUTheme.primary)
                    }
                    .frame(height: CGFloat(max(items.count, 1)) * 36)
                }
                ForEach(items) { item in
                    KCard {
                        HStack {
                            Text(item.subject).font(.headline)
                            Spacer()
                            KBadge(text: "\(item.hoursPerWeek) ч/нед")
                        }
                        KInfoRow(label: "Цель", value: item.goal)
                        KInfoRow(label: "Период", value: item.term)
                        if !item.adaptation.isEmpty { KInfoRow(label: "Адаптация", value: item.adaptation) }
                        if store.role.canTeach {
                            Button("Удалить", role: .destructive) { store.db.studyPlan.removeAll { $0.id == item.id } }
                                .font(.caption)
                        }
                    }
                }
                if store.role.canTeach || store.role == .psychologist {
                    KCard {
                        Text("Добавить предмет в ИУП").font(.headline)
                        TextField("Предмет", text: $subject).textFieldStyle(.roundedBorder)
                        Stepper("Часов в неделю: \(hours)", value: $hours, in: 1...12)
                        TextField("Цель", text: $goal).textFieldStyle(.roundedBorder)
                        TextField("Адаптация (субтитры, короткие задания…)", text: $adaptation).textFieldStyle(.roundedBorder)
                        Button("Добавить") {
                            store.db.studyPlan.append(StudyPlanItem(studentID: studentID, subject: subject, hoursPerWeek: hours, goal: goal, term: "Текущая четверть", adaptation: adaptation))
                            subject = ""; goal = ""; adaptation = ""
                        }
                        .disabled(subject.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Календарь ученика (задача 18)

struct CalendarItem: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let icon: String
    let color: Color
}

struct StudentCalendarView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var day = Date()
    @State private var note = ""

    var body: some View {
        KPage("Календарь") {
            StudentScoped { studentID in
                DatePicker("Дата", selection: $day, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                let dayItems = calendarItems(for: studentID, on: day)
                KSectionHeader(title: day.formatted(date: .complete, time: .omitted), icon: "calendar")
                if dayItems.isEmpty { KEmptyState(text: "На этот день ничего не запланировано", icon: "calendar.badge.checkmark") }
                ForEach(dayItems) { item in
                    HStack {
                        Image(systemName: item.icon).foregroundStyle(item.color).frame(width: 28)
                        Text(item.title)
                        Spacer()
                        Text(item.date.kksuTime).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                HStack {
                    TextField("Личная заметка на этот день", text: $note).textFieldStyle(.roundedBorder)
                    Button("Добавить") {
                        store.db.calendarNotes.append(CalendarNote(userID: studentID, title: note, date: day))
                        note = ""
                    }
                    .disabled(note.isEmpty)
                }
            }
        }
    }

    private func calendarItems(for studentID: UUID, on day: Date) -> [CalendarItem] {
        let cal = Calendar.current
        var result: [CalendarItem] = []
        for s in store.db.sessions where s.participantIDs.contains(studentID) && cal.isDate(s.start, inSameDayAs: day) {
            result.append(CalendarItem(date: s.start, title: "\(s.subject): \(s.title)", icon: s.isOnline ? "video.fill" : "person.3.fill", color: KKSUTheme.primary))
        }
        for a in store.assignments(for: studentID) where cal.isDate(a.dueDate, inSameDayAs: day) {
            result.append(CalendarItem(date: a.dueDate, title: "Дедлайн: \(a.title)", icon: "clock.badge.exclamationmark.fill", color: KKSUTheme.danger))
        }
        for e in store.db.events where cal.isDate(e.date, inSameDayAs: day) {
            result.append(CalendarItem(date: e.date, title: e.title, icon: "star.circle.fill", color: KKSUTheme.accent))
        }
        for g in store.db.globalClasses where cal.isDate(g.start, inSameDayAs: day) {
            result.append(CalendarItem(date: g.start, title: "Global Classroom: \(g.title)", icon: "globe", color: .purple))
        }
        for n in store.db.calendarNotes where n.userID == studentID && cal.isDate(n.date, inSameDayAs: day) {
            result.append(CalendarItem(date: n.date, title: n.title, icon: "note.text", color: .secondary))
        }
        return result.sorted { $0.date < $1.date }
    }
}

// MARK: - Домашние задания (задачи 19, 20)

struct HomeworkListView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false

    var body: some View {
        KPage("Домашние задания") {
            if store.role.canTeach {
                PrimaryButton(title: "Новое задание", icon: "plus") { showEditor = true }
                ForEach(store.db.assignments.filter { $0.audience == .students }.sorted { $0.dueDate > $1.dueDate }) { assignment in
                    NavigationLink { SubmissionsForAssignmentView(assignmentID: assignment.id) } label: {
                        KCard {
                            HStack {
                                Text(assignment.title).font(.headline)
                                Spacer()
                                if !assignment.approvedByTeacher { KBadge(text: "AI · ждёт проверки", color: .purple) }
                            }
                            Text("\(assignment.subject) · до \(assignment.dueDate.kksuDateTime)").font(.caption).foregroundStyle(.secondary)
                            Text("Сдано работ: \(store.db.submissions.filter { $0.assignmentID == assignment.id }.count)").font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                StudentScoped { studentID in
                    let all = store.assignments(for: studentID)
                    let active = all.filter { store.submission(for: $0.id, studentID: studentID) == nil }
                    let done = all.filter { store.submission(for: $0.id, studentID: studentID) != nil }
                    KSectionHeader(title: "Нужно сделать · \(active.count)", icon: "circle.dashed")
                    if active.isEmpty { KEmptyState(text: "Все задания выполнены!", icon: "party.popper") }
                    ForEach(active) { assignment in
                        NavigationLink { AssignmentDetailView(assignment: assignment, studentID: studentID) } label: { DeadlineRow(assignment: assignment) }
                            .buttonStyle(.plain)
                    }
                    KSectionHeader(title: "Сдано · \(done.count)", icon: "checkmark.circle")
                    ForEach(done) { assignment in
                        NavigationLink { AssignmentDetailView(assignment: assignment, studentID: studentID) } label: {
                            if let sub = store.submission(for: assignment.id, studentID: studentID) {
                                SubmissionSummaryRow(submission: sub)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { AssignmentEditorView() }
        }
    }
}

struct AssignmentDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.kksuAccessibility) private var a11y
    let assignment: Assignment
    let studentID: UUID
    @State private var answer = ""
    @State private var attachments: [Attachment] = []
    @State private var showAlt = false

    var body: some View {
        KPage(assignment.title) {
            KCard {
                KBadge(text: assignment.subject)
                Text(assignment.details).font(.body)
                KInfoRow(label: "Срок сдачи", value: assignment.dueDate.kksuDateTime)
                KInfoRow(label: "Максимальный балл", value: "\(assignment.maxScore)")
                KInfoRow(label: "Педагог", value: store.userName(assignment.teacherID))
                if !assignment.textAlternative.isEmpty {
                    DisclosureGroup("Текстовая версия материала", isExpanded: Binding(get: { showAlt || a11y.showTextAlternatives }, set: { showAlt = $0 })) {
                        Text(assignment.textAlternative).font(.callout)
                    }
                }
            }
            if let sub = store.submission(for: assignment.id, studentID: studentID) {
                SubmissionSummaryRow(submission: sub)
                ForEach(sub.attachments) { AttachmentRow(attachment: $0) }
            }
            let existing = store.submission(for: assignment.id, studentID: studentID)
            if store.currentUser?.id == studentID && (existing == nil || existing?.status == .returned) {
                KCard {
                    Text(existing == nil ? "Сдать работу" : "Отправить исправленную работу").font(.headline)
                    TextField("Ответ или комментарий", text: $answer, axis: .vertical)
                        .lineLimit(3...10)
                        .textFieldStyle(.roundedBorder)
                    AttachmentPicker(attachments: $attachments)
                    PrimaryButton(title: "Отправить на проверку", icon: "paperplane.fill") {
                        store.submitWork(assignmentID: assignment.id, studentID: studentID, text: answer, attachments: attachments)
                        answer = ""
                        attachments = []
                    }
                    .disabled(answer.isEmpty && attachments.isEmpty)
                }
            }
        }
    }
}

struct AssignmentEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var assignment = Assignment(title: "", subject: "", details: "", dueDate: Date().addingTimeInterval(3 * 86400))
    @State private var forAll = true

    var body: some View {
        Form {
            Section("Задание") {
                TextField("Название", text: $assignment.title)
                TextField("Предмет", text: $assignment.subject)
                TextField("Описание", text: $assignment.details, axis: .vertical)
                TextField("Текстовая альтернатива материалов", text: $assignment.textAlternative, axis: .vertical)
            }
            Section("Сроки и оценивание") {
                DatePicker("Дедлайн", selection: $assignment.dueDate)
                Stepper("Максимальный балл: \(assignment.maxScore)", value: $assignment.maxScore, in: 1...100)
            }
            Section("Кому") {
                Toggle("Всем ученикам", isOn: $forAll)
                if !forAll {
                    ForEach(store.students) { student in
                        Toggle(student.fullName, isOn: Binding(
                            get: { assignment.assignedIDs.contains(student.id) },
                            set: { on in
                                if on { assignment.assignedIDs.append(student.id) } else { assignment.assignedIDs.removeAll { $0 == student.id } }
                            }))
                    }
                }
            }
        }
        .navigationTitle("Новое задание")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Опубликовать") {
                    assignment.teacherID = store.currentUser?.id
                    if forAll { assignment.assignedIDs = [] }
                    store.publish(assignment)
                    dismiss()
                }
                .disabled(assignment.title.isEmpty || assignment.subject.isEmpty)
            }
        }
    }
}

// MARK: - Оценки и обратная связь (задача 21)

struct SubmissionSummaryRow: View {
    @EnvironmentObject private var store: KKSUStore
    let submission: Submission

    var body: some View {
        let assignment = store.db.assignments.first { $0.id == submission.assignmentID }
        KCard {
            HStack {
                Text(assignment?.title ?? "Работа").font(.headline)
                Spacer()
                if let score = submission.score {
                    Text("\(score)/\(assignment?.maxScore ?? 10)")
                        .font(.title3.bold())
                        .foregroundStyle(KKSUTheme.primary)
                }
            }
            HStack {
                KBadge(text: submission.status.title, color: submission.status == .graded ? KKSUTheme.success : (submission.status == .returned ? KKSUTheme.warning : KKSUTheme.primary))
                Text("Сдано \(submission.submittedAt.kksuDateTime)").font(.caption).foregroundStyle(.secondary)
            }
            if !submission.feedback.isEmpty {
                Label(submission.feedback, systemImage: "text.bubble.fill")
                    .font(.callout)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KKSUTheme.softBlue.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct GradingQueueView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let pending = store.db.submissions.filter { $0.status == .submitted }.sorted { $0.submittedAt < $1.submittedAt }
        let graded = store.db.submissions.filter { $0.status != .submitted }.sorted { ($0.gradedAt ?? .distantPast) > ($1.gradedAt ?? .distantPast) }
        KPage("Проверка работ") {
            KSectionHeader(title: "Ожидают проверки · \(pending.count)", icon: "tray.full.fill")
            if pending.isEmpty { KEmptyState(text: "Все работы проверены", icon: "checkmark.seal") }
            ForEach(pending) { sub in
                NavigationLink { GradeSubmissionView(submissionID: sub.id) } label: {
                    KCard {
                        Text(store.userName(sub.studentID)).font(.headline)
                        Text(store.db.assignments.first { $0.id == sub.assignmentID }?.title ?? "").font(.callout)
                        Text("Сдано \(sub.submittedAt.kksuDateTime) · вложений: \(sub.attachments.count)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            KSectionHeader(title: "Проверенные", icon: "checkmark.circle")
            ForEach(graded.prefix(20)) { sub in
                NavigationLink { GradeSubmissionView(submissionID: sub.id) } label: {
                    VStack(alignment: .leading) {
                        Text(store.userName(sub.studentID)).font(.caption.bold())
                        SubmissionSummaryRow(submission: sub)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SubmissionsForAssignmentView: View {
    @EnvironmentObject private var store: KKSUStore
    let assignmentID: UUID

    var body: some View {
        let assignment = store.db.assignments.first { $0.id == assignmentID }
        KPage(assignment?.title ?? "Задание") {
            if let assignment, !assignment.approvedByTeacher {
                NavigationLink { AIAssignmentReviewView(assignmentID: assignment.id) } label: {
                    Label("Проверить и утвердить AI-задание", systemImage: "sparkles")
                }
            }
            ForEach(store.db.submissions.filter { $0.assignmentID == assignmentID }) { sub in
                NavigationLink { GradeSubmissionView(submissionID: sub.id) } label: {
                    VStack(alignment: .leading) {
                        Text(store.userName(sub.studentID)).font(.caption.bold())
                        SubmissionSummaryRow(submission: sub)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct GradeSubmissionView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let submissionID: UUID
    @State private var score = 8
    @State private var feedback = ""

    private let quickFeedback = ["Отличная работа!", "Хорошо, но проверь вычисления.", "Добавь пояснения к решению.", "Оформи работу аккуратнее.", "Молодец, виден прогресс!"]

    var body: some View {
        if let sub = store.db.submissions.first(where: { $0.id == submissionID }) {
            let assignment = store.db.assignments.first { $0.id == sub.assignmentID }
            let maxScore = assignment?.maxScore ?? 10
            KPage("Оценивание") {
                KCard {
                    Text(store.userName(sub.studentID)).font(.headline)
                    Text(assignment?.title ?? "").font(.callout)
                    Divider()
                    Text(sub.text.isEmpty ? "Без текстового ответа" : sub.text)
                    ForEach(sub.attachments) { AttachmentRow(attachment: $0) }
                }
                KCard {
                    Text("Оценка").font(.headline)
                    Stepper("\(score) из \(maxScore)", value: $score, in: 0...maxScore)
                    Text("Быстрые комментарии").font(.caption).foregroundStyle(.secondary)
                    FlowButtons(items: quickFeedback) { feedback = feedback.isEmpty ? $0 : feedback + " " + $0 }
                    TextField("Обратная связь ученику", text: $feedback, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("На доработку") {
                            store.grade(submissionID: sub.id, score: score, feedback: feedback, returnForRevision: true)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Поставить оценку") {
                            store.grade(submissionID: sub.id, score: score, feedback: feedback)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .onAppear {
                score = sub.score ?? min(8, maxScore)
                feedback = sub.feedback
            }
        }
    }
}

struct FlowButtons: View {
    let items: [String]
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button(item) { action(item) }
                    .font(.caption)
                    .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Портфолио (задача 22)

struct PortfolioView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var title = ""
    @State private var category = "Проект"
    @State private var summary = ""
    @State private var attachments: [Attachment] = []

    var body: some View {
        KPage("Электронное портфолио") {
            StudentScoped { studentID in
                let items = store.db.portfolio.filter { $0.studentID == studentID }.sorted { $0.date > $1.date }
                let projects = store.db.projects.filter { $0.authorIDs.contains(studentID) }
                let certs = store.db.certificates.filter { $0.userID == studentID }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    KStatTile(title: "Работ в портфолио", value: "\(items.count)", icon: "briefcase.fill")
                    KStatTile(title: "Проектов", value: "\(projects.count)", icon: "lightbulb.fill", color: KKSUTheme.accent)
                    KStatTile(title: "Сертификатов", value: "\(certs.count)", icon: "doc.badge.ellipsis", color: KKSUTheme.success)
                }
                ForEach(items) { item in
                    KCard {
                        HStack {
                            Text(item.title).font(.headline)
                            Spacer()
                            if item.verifiedBy != nil {
                                Label("Подтверждено", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(KKSUTheme.success)
                            } else if store.role.canTeach {
                                Button("Подтвердить") {
                                    if let index = store.db.portfolio.firstIndex(where: { $0.id == item.id }) {
                                        store.db.portfolio[index].verifiedBy = store.currentUser?.id
                                    }
                                }
                                .font(.caption)
                            }
                        }
                        Text("\(item.category) · \(item.date.kksuShort)").font(.caption).foregroundStyle(.secondary)
                        Text(item.summary).font(.callout)
                        ForEach(item.attachments) { AttachmentRow(attachment: $0) }
                    }
                }
                if !projects.isEmpty {
                    KSectionHeader(title: "Проекты", icon: "lightbulb.fill")
                    ForEach(projects) { project in
                        NavigationLink { ProjectDetailView(projectID: project.id) } label: { ProjectCard(project: project) }
                            .buttonStyle(.plain)
                    }
                }
                if store.currentUser?.id == studentID || store.role.canTeach {
                    KCard {
                        Text("Добавить в портфолио").font(.headline)
                        TextField("Название", text: $title).textFieldStyle(.roundedBorder)
                        Picker("Категория", selection: $category) {
                            ForEach(["Проект", "Олимпиада", "Творчество", "Исследование", "Волонтёрство", "Спорт"], id: \.self) { Text($0) }
                        }
                        TextField("Описание", text: $summary, axis: .vertical).textFieldStyle(.roundedBorder)
                        AttachmentPicker(attachments: $attachments)
                        Button("Сохранить") {
                            store.db.portfolio.append(PortfolioItem(studentID: studentID, title: title, category: category, summary: summary, attachments: attachments))
                            store.log(studentID, "Добавлено в портфолио", details: title, icon: "briefcase")
                            title = ""; summary = ""; attachments = []
                        }
                        .disabled(title.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Достижения и сертификаты (задача 23)

struct AchievementsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Достижения и сертификаты") {
            StudentScoped { studentID in
                let achievements = store.db.achievements.filter { $0.userID == studentID }.sorted { $0.date > $1.date }
                let points = achievements.reduce(0) { $0 + $1.points }
                KCard {
                    HStack {
                        Image(systemName: "trophy.fill").font(.largeTitle).foregroundStyle(KKSUTheme.accent)
                        VStack(alignment: .leading) {
                            Text("\(points) очков").font(.title2.bold())
                            Text("Уровень \(points / 100 + 1) · до следующего \(100 - points % 100)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    KProgressBar(value: Double(points % 100) / 100, color: KKSUTheme.accent)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ForEach(achievements) { achievement in
                        KCard {
                            Image(systemName: achievement.icon).font(.largeTitle).foregroundStyle(KKSUTheme.accent)
                            Text(achievement.title).font(.callout.weight(.semibold))
                            Text("+\(achievement.points) · \(achievement.date.kksuShort)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                KSectionHeader(title: "Сертификаты", icon: "doc.badge.ellipsis")
                ForEach(store.db.certificates.filter { $0.userID == studentID }) { CertificateCard(certificate: $0) }
                if store.role.canTeach {
                    Button("Выдать сертификат об окончании модуля") {
                        store.issueCertificate(to: studentID, title: "Успешное завершение модуля", issuer: .school, hours: 24)
                    }
                }
            }
        }
    }
}

// MARK: - Дашборд прогресса (задача 24)

struct ProgressDashboardView: View {
    var body: some View {
        KPage("Дашборд прогресса") {
            StudentScoped { studentID in
                ProgressDashboardContent(studentID: studentID)
            }
        }
    }
}

struct ProgressDashboardContent: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        let analysis = ProgressAnalyzer.analyze(studentID, db: store.db, store: store)
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                KStatTile(title: "Общий прогресс", value: "\(Int(analysis.overall * 100))%", icon: "gauge.with.dots.needle.67percent")
                KStatTile(title: "Выполнение заданий", value: "\(Int(analysis.completionRate * 100))%", icon: "checkmark.circle.fill", color: KKSUTheme.success)
                KStatTile(title: "Средний балл тестов", value: analysis.testAverage.map { "\(Int($0 * 100))%" } ?? "—", icon: "checklist", color: KKSUTheme.accent)
                KStatTile(title: "Посещаемость", value: analysis.attendanceRate.map { "\(Int($0 * 100))%" } ?? "—", icon: "person.fill.checkmark", color: .purple)
            }
            KCard {
                Text("Успеваемость по предметам").font(.headline)
                if analysis.subjects.isEmpty {
                    KEmptyState(text: "Пока нет оценок")
                } else {
                    Chart(analysis.subjects) { stat in
                        BarMark(x: .value("Предмет", stat.subject), y: .value("Результат", stat.average * 100))
                            .foregroundStyle(stat.average >= 0.75 ? KKSUTheme.success : (stat.average >= 0.5 ? KKSUTheme.warning : KKSUTheme.danger))
                            .annotation(position: .top) { Text("\(Int(stat.average * 100))%").font(.caption2) }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 200)
                }
            }
            KCard {
                Text("Активность за неделю").font(.headline)
                Chart(analysis.weeklyActivity, id: \.day) { item in
                    LineMark(x: .value("День", item.day, unit: .day), y: .value("Действий", item.count))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("День", item.day, unit: .day), y: .value("Действий", item.count))
                }
                .frame(height: 160)
            }
            KCard {
                HStack {
                    Text("Статус").font(.headline)
                    Spacer()
                    KBadge(text: analysis.risk.title, color: analysis.risk.color)
                }
                if let strong = analysis.strongest { KInfoRow(label: "Сильная сторона", value: strong.subject) }
                if let weak = analysis.weakest, analysis.subjects.count > 1 { KInfoRow(label: "Зона роста", value: weak.subject) }
                KInfoRow(label: "Просрочено заданий", value: "\(analysis.overdue.count)")
            }
        }
    }
}

// MARK: - История обучения (задача 25)

struct LearningHistoryView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let userID = store.role == .student ? store.currentUser?.id : store.visibleStudents.first?.id
        let entries = store.db.history.filter { $0.userID == (userID ?? store.currentUser?.id) }.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.date) }
        List {
            if entries.isEmpty { KEmptyState(text: "История пока пуста", icon: "clock") }
            ForEach(grouped.keys.sorted(by: >), id: \.self) { day in
                Section(day.formatted(date: .long, time: .omitted)) {
                    ForEach(grouped[day] ?? []) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: entry.icon).foregroundStyle(.tint).frame(width: 26)
                            VStack(alignment: .leading) {
                                Text(entry.action)
                                if !entry.details.isEmpty { Text(entry.details).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text(entry.date.kksuTime).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("История обучения")
    }
}

// MARK: - Дедлайны (задача 36)

struct DeadlinesView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        KPage("Дедлайны") {
            if store.role.canTeach {
                let all = store.db.assignments.filter { $0.approvedByTeacher }.sorted { $0.dueDate < $1.dueDate }
                ForEach(all) { assignment in
                    let submitted = Set(store.db.submissions.filter { $0.assignmentID == assignment.id }.map(\.studentID)).count
                    let expected = assignment.assignedIDs.isEmpty ? store.students.count : assignment.assignedIDs.count
                    VStack(alignment: .leading, spacing: 4) {
                        DeadlineRow(assignment: assignment)
                        if assignment.audience == .students {
                            Text("Сдали: \(submitted) из \(expected)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                StudentScoped { studentID in
                    let pending = store.assignments(for: studentID).filter { store.submission(for: $0.id, studentID: studentID) == nil }
                    let overdue = pending.filter { $0.dueDate < Date() }
                    let soon = pending.filter { $0.dueDate >= Date() && $0.dueDate < Date().addingTimeInterval(3 * 86400) }
                    let later = pending.filter { $0.dueDate >= Date().addingTimeInterval(3 * 86400) }
                    DeadlineGroup(title: "Просрочено", icon: "exclamationmark.triangle.fill", items: overdue, studentID: studentID)
                    DeadlineGroup(title: "Ближайшие 3 дня", icon: "clock.fill", items: soon, studentID: studentID)
                    DeadlineGroup(title: "Позже", icon: "calendar", items: later, studentID: studentID)
                    Button {
                        pending.forEach { store.scheduleDeadlineReminder(for: $0) }
                        store.requestNotificationPermission()
                    } label: {
                        Label("Напоминать за сутки до дедлайна", systemImage: "bell.badge")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct DeadlineGroup: View {
    let title: String
    let icon: String
    let items: [Assignment]
    let studentID: UUID

    var body: some View {
        if !items.isEmpty {
            KSectionHeader(title: "\(title) · \(items.count)", icon: icon)
            ForEach(items) { assignment in
                NavigationLink { AssignmentDetailView(assignment: assignment, studentID: studentID) } label: { DeadlineRow(assignment: assignment) }
                    .buttonStyle(.plain)
            }
        }
    }
}
