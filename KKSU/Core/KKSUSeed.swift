//
//  KKSUSeed.swift
//  KKSU Online
//
//  Демонстрационные данные: по одному аккаунту на каждую роль и
//  наполнение всех модулей, чтобы платформу можно было показать сразу.
//  Пароль всех демо-аккаунтов: kksu2026
//

import Foundation

enum KKSUSeed {

    static let demoPassword = "kksu2026"

    static let demoAccounts: [(email: String, role: KKSURole)] = [
        ("student@kksu.kz", .student),
        ("parent@kksu.kz", .parent),
        ("teacher@kksu.kz", .teacher),
        ("psychologist@kksu.kz", .psychologist),
        ("expert@kksu.kz", .expert),
        ("mentor@kksu.kz", .mentor),
        ("partner@kksu.kz", .partner),
        ("admin@kksu.kz", .admin)
    ]

    private static func date(_ days: Int, _ hour: Int = 10, _ minute: Int = 0) -> Date {
        let cal = Calendar.current
        let day = cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: Date())) ?? Date()
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func makeUser(_ name: String, _ email: String, _ role: KKSURole) -> KKSUUser {
        let salt = UUID().uuidString
        return KKSUUser(fullName: name, email: email, phone: "+7 700 000 00 00", role: role,
                        passwordHash: KKSUStore.hash(demoPassword, salt: salt), salt: salt)
    }

    static func makeDatabase() -> KKSUDatabase {
        var db = KKSUDatabase()

        // MARK: Пользователи
        let aliya = makeUser("Алия Сарсенова", "student@kksu.kz", .student)
        let timur = makeUser("Тимур Ахметов", "timur@kksu.kz", .student)
        let dana = makeUser("Дана Нурланова", "dana@kksu.kz", .student)
        var parent = makeUser("Гульшат Сарсенова", "parent@kksu.kz", .parent)
        parent.linkedStudentIDs = [aliya.id]
        let teacher = makeUser("Марат Касымов", "teacher@kksu.kz", .teacher)
        let teacher2 = makeUser("Айгерим Беккали", "aigerim@kksu.kz", .teacher)
        let psychologist = makeUser("Жанна Омарова", "psychologist@kksu.kz", .psychologist)
        let expert = makeUser("Ерлан Жумабаев", "expert@kksu.kz", .expert)
        var mentor = makeUser("Санжар Исаев", "mentor@kksu.kz", .mentor)
        mentor.linkedStudentIDs = [aliya.id, timur.id]
        var partnerUser = makeUser("Асель Каримова", "partner@kksu.kz", .partner)
        let admin = makeUser("Администратор KKSU", "admin@kksu.kz", .admin)

        // MARK: Партнёры (93)
        let mashstroy = Partner(name: "MASHSTROY", kind: .company, country: "Казахстан", summary: "Машиностроительный холдинг, партнёр инженерных кейсов и стажировок.", email: "edu@mashstroy.kz", website: "https://mashstroy.kz", since: date(-400))
        let arai = Partner(name: "ARAI AI", kind: .company, country: "Казахстан", summary: "Разработчик AI-решений, партнёр направления искусственного интеллекта.", email: "hello@arai.ai", website: "https://arai.ai", since: date(-300))
        let iken = Partner(name: "IKEN", kind: .ngo, country: "Казахстан", summary: "Экологические и энергетические проекты для школьников.", email: "info@iken.kz", website: "https://iken.kz", since: date(-250))
        let ataMura = Partner(name: "ATA MURA", kind: .ngo, country: "Казахстан", summary: "Культурное наследие в цифровом формате.", email: "info@atamura.kz", website: "https://atamura.kz", since: date(-200))
        let kaist = Partner(name: "Seoul STEM Academy", kind: .international, country: "Южная Корея", summary: "Партнёр Global Classroom по робототехнике.", email: "global@stem.kr", website: "https://example.org", since: date(-150))
        let tum = Partner(name: "Munich Tech School", kind: .university, country: "Германия", summary: "Совместные инженерные проекты и лекции экспертов.", email: "intl@mts.de", website: "https://example.org", since: date(-120))
        db.partners = [mashstroy, arai, iken, ataMura, kaist, tum]
        partnerUser.partnerID = mashstroy.id

        db.users = [aliya, timur, dana, parent, teacher, teacher2, psychologist, expert, mentor, partnerUser, admin]

        db.studentProfiles = [
            StudentProfile(userID: aliya.id, grade: "7", interests: ["Робототехника", "Математика", "Экология"], specialNeeds: "Нарушение слуха (слуховой аппарат)", supportNotes: "Нужны субтитры и письменные инструкции", goals: "Собрать своего робота и выступить на Young Inventors", xp: 1240),
            StudentProfile(userID: timur.id, grade: "8", interests: ["Программирование", "AI"], specialNeeds: "СДВГ", supportNotes: "Короткие задания, частые перерывы", goals: "Поступить в IT-лицей", xp: 860),
            StudentProfile(userID: dana.id, grade: "6", interests: ["Дизайн", "История"], specialNeeds: "", goals: "Проект по ATA MURA", xp: 540)
        ]

        db.questionnaires = [
            IntakeQuestionnaire(studentID: aliya.id, date: date(-120), learningFormat: .mixed, strengths: "Логика, конструирование", difficulties: "Восприятие устной речи в шуме", healthNotes: "Слуховой аппарат", communication: "Письменно и с субтитрами", parentExpectations: "Развитие инженерных навыков", assistiveTech: ["Субтитры", "FM-система"], needsPsychologist: false)
        ]

        // MARK: Программы (14)
        let math = EducationProgram(title: "Математика 5–9", direction: .school, ageRange: "10–15", durationWeeks: 36, format: .mixed, summary: "Базовая и углублённая математика с адаптацией под темп ученика.", subjects: ["Математика", "Логика"])
        let robotics = EducationProgram(title: "Робототехника и Arduino", direction: .engineering, ageRange: "11–17", durationWeeks: 24, format: .mixed, summary: "Сборка и программирование роботов, подготовка к соревнованиям.", subjects: ["Робототехника", "Программирование"])
        let inventors = EducationProgram(title: "Школа изобретателя", direction: .inventions, ageRange: "10–18", durationWeeks: 20, format: .offline, summary: "От идеи до прототипа: ТРИЗ, исследование, испытания.", subjects: ["ТРИЗ", "Проектирование"])
        let ai = EducationProgram(title: "AI для школьников", direction: .digital, ageRange: "12–18", durationWeeks: 16, format: .online, summary: "Основы машинного обучения и этичного использования AI.", subjects: ["AI", "Python"])
        let global = EducationProgram(title: "Global Classroom English", direction: .global, ageRange: "10–18", durationWeeks: 30, format: .online, summary: "Международные онлайн-классы с носителями языка.", subjects: ["Английский"])
        let inclusive = EducationProgram(title: "Инклюзивная инженерия", direction: .inclusive, ageRange: "12–18", durationWeeks: 18, format: .mixed, summary: "Проектирование устройств для людей с особыми потребностями.", subjects: ["Инженерия", "Эмпатия-дизайн"])
        db.programs = [math, robotics, inventors, ai, global, inclusive]

        db.applications = [
            EnrollmentApplication(childName: "Арман Сеитов", childAge: 11, parentName: "Сеитова Мадина", email: "madina@mail.kz", phone: "+7 701 111 22 33", programID: robotics.id, comment: "Интересуется роботами", status: .submitted, date: date(-2)),
            EnrollmentApplication(childName: "Лейла Абенова", childAge: 13, parentName: "Абенов Ержан", email: "erzhan@mail.kz", phone: "+7 702 222 33 44", programID: ai.id, format: .online, status: .review, date: date(-5))
        ]

        db.consents = ConsentType.allCases.map {
            ParentConsent(studentID: aliya.id, parentID: parent.id, type: $0, granted: $0 != .international, signatureName: parent.fullName, date: date(-110))
        }

        // MARK: Траектория и план (15, 16)
        db.trajectory = [
            TrajectoryStep(studentID: aliya.id, title: "Освоить базовую робототехнику", programID: robotics.id, targetDate: date(-30), status: .done),
            TrajectoryStep(studentID: aliya.id, title: "Математика: уровень «Продвинутый»", programID: math.id, targetDate: date(45), status: .inProgress, note: "Сейчас 65%, цель — 80%"),
            TrajectoryStep(studentID: aliya.id, title: "Прототип «Умная трость»", programID: inclusive.id, targetDate: date(60), status: .inProgress),
            TrajectoryStep(studentID: aliya.id, title: "Заявка на Young Inventors 30", programID: inventors.id, targetDate: date(90), status: .planned)
        ]
        db.studyPlan = [
            StudyPlanItem(studentID: aliya.id, subject: "Математика", hoursPerWeek: 4, goal: "Дроби и уравнения", term: "1 четверть", adaptation: "Письменные инструкции"),
            StudyPlanItem(studentID: aliya.id, subject: "Робототехника", hoursPerWeek: 3, goal: "Датчики и моторы", term: "1 четверть"),
            StudyPlanItem(studentID: aliya.id, subject: "Английский", hoursPerWeek: 2, goal: "Уровень A2", term: "1 четверть", adaptation: "Видео с субтитрами"),
            StudyPlanItem(studentID: aliya.id, subject: "Русский язык", hoursPerWeek: 3, goal: "Чтение и пересказ", term: "1 четверть")
        ]

        // MARK: Расписание (17, 32, 33)
        let everyone = [aliya.id, timur.id, dana.id]
        db.sessions = [
            ScheduleSession(title: "Умножение дробей", subject: "Математика", teacherID: teacher.id, start: date(0, 10), participantIDs: everyone, attendedIDs: []),
            ScheduleSession(title: "Датчики расстояния", subject: "Робототехника", teacherID: teacher.id, start: date(0, 14), room: "Лаборатория 2", isOnline: false, participantIDs: [aliya.id, timur.id]),
            ScheduleSession(title: "Speaking Club с Сеулом", subject: "Английский", teacherID: teacher2.id, start: date(1, 11), platform: .zoom, meetingURL: "https://zoom.us/j/1234567890", participantIDs: everyone),
            ScheduleSession(title: "Уравнения", subject: "Математика", teacherID: teacher.id, start: date(2, 10), participantIDs: everyone),
            ScheduleSession(title: "Сложение дробей", subject: "Математика", teacherID: teacher.id, start: date(-2, 10), participantIDs: everyone, attendedIDs: [aliya.id, timur.id]),
            ScheduleSession(title: "Сборка шасси", subject: "Робототехника", teacherID: teacher.id, start: date(-3, 14), isOnline: false, participantIDs: [aliya.id, timur.id], attendedIDs: [aliya.id, timur.id]),
            ScheduleSession(title: "Введение в нейросети", subject: "AI", teacherID: teacher2.id, start: date(-5, 16), participantIDs: [timur.id, aliya.id], attendedIDs: [timur.id])
        ]

        // MARK: Задания и работы (19–21)
        let hw1 = Assignment(title: "Решить 10 задач на дроби", subject: "Математика", details: "Решите задачи из карточки №3. Запишите решение по шагам.", teacherID: teacher.id, createdAt: date(-4), dueDate: date(2, 18), textAlternative: "Карточка: 10 задач на сложение и умножение дробей.")
        let hw2 = Assignment(title: "Схема робота", subject: "Робототехника", details: "Нарисуйте схему подключения датчика расстояния к Arduino и загрузите фото.", teacherID: teacher.id, createdAt: date(-6), dueDate: date(-1, 18))
        let hw3 = Assignment(title: "Эссе «Мой город через 30 лет»", subject: "Английский", details: "120–150 слов на английском.", teacherID: teacher2.id, createdAt: date(-3), dueDate: date(5, 18))
        let hwAI = Assignment(title: "Адаптированная задача: площадь комнаты", subject: "Математика", details: "Измерь свою комнату шагами и вычисли площадь. Опиши каждый шаг.", teacherID: teacher.id, createdAt: date(0), dueDate: date(4, 18), assignedIDs: [aliya.id], isAIGenerated: true, approvedByTeacher: false)
        db.assignments = [hw1, hw2, hw3, hwAI]
        db.submissions = [
            Submission(assignmentID: hw2.id, studentID: aliya.id, submittedAt: date(-2, 17), text: "Схема во вложении. Датчик HC-SR04 подключён к пинам 9 и 10.", attachments: [Attachment(fileName: "schema.jpg", kind: .photo, sizeBytes: 240_000, altText: "Схема: Arduino Uno, датчик HC-SR04, провода к пинам 9 и 10")], score: 9, feedback: "Отличная схема! Подпиши номиналы резисторов.", gradedAt: date(-1, 12), gradedBy: teacher.id, status: .graded),
            Submission(assignmentID: hw2.id, studentID: timur.id, submittedAt: date(-1, 20), text: "Готово", score: 6, feedback: "Не хватает питания датчика.", gradedAt: date(-1, 21), gradedBy: teacher.id, status: .returned),
            Submission(assignmentID: hw1.id, studentID: timur.id, submittedAt: date(0, 9), text: "Решил 8 задач из 10.")
        ]

        // MARK: Портфолио, достижения, сертификаты, история (22–25)
        db.portfolio = [
            PortfolioItem(studentID: aliya.id, title: "Робот-сортировщик", category: "Проект", date: date(-40), summary: "Робот сортирует детали по цвету. 2 место на школьной выставке.", verifiedBy: teacher.id),
            PortfolioItem(studentID: aliya.id, title: "Олимпиада по математике", category: "Олимпиада", date: date(-70), summary: "Призёр городского этапа.")
        ]
        db.achievements = [
            Achievement(userID: aliya.id, title: "Первая сданная работа", icon: "tray.and.arrow.up.fill", points: 10, date: date(-60)),
            Achievement(userID: aliya.id, title: "7 дней обучения подряд", icon: "flame.fill", points: 20, date: date(-20)),
            Achievement(userID: aliya.id, title: "Первый прототип", icon: "hammer.fill", points: 50, date: date(-10))
        ]
        db.certificates = [
            Certificate(userID: aliya.id, recipientName: aliya.fullName, title: "Робототехника: базовый уровень", issuer: .school, date: date(-30), serial: "2026-00001-A1B2", hours: 48)
        ]
        db.history = [
            HistoryEntry(userID: aliya.id, date: date(-120), action: "Зачисление в KKSU", details: "Смешанный формат", icon: "person.badge.plus"),
            HistoryEntry(userID: aliya.id, date: date(-30), action: "Завершён модуль", details: "Робототехника: базовый уровень", icon: "checkmark.seal"),
            HistoryEntry(userID: aliya.id, date: date(-2, 17), action: "Сдана работа", details: "Схема робота", icon: "tray.and.arrow.up.fill"),
            HistoryEntry(userID: aliya.id, date: date(-1, 12), action: "Получена оценка", details: "Схема робота: 9", icon: "star.fill")
        ]

        // MARK: Библиотеки (26–28, 40, 75, 76)
        let sampleVideo = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
        db.library = [
            LibraryItem(title: "Что такое дробь", kind: .video, subject: "Математика", author: "Марат Касымов", summary: "Объяснение дробей на примере пиццы.", url: sampleVideo, durationMinutes: 8,
                        captions: [CaptionSegment(start: 0, end: 4, text: "Привет! Сегодня разберём, что такое дробь."),
                                   CaptionSegment(start: 4, end: 9, text: "Представь пиццу, разрезанную на 8 частей."),
                                   CaptionSegment(start: 9, end: 15, text: "Если ты съел 3 куска — это 3/8 пиццы."),
                                   CaptionSegment(start: 15, end: 22, text: "Верхнее число — числитель, нижнее — знаменатель.")],
                        textAlternative: "Дробь показывает часть целого. Пицца из 8 кусков: 3 куска = 3/8. Числитель (3) — сколько частей взяли, знаменатель (8) — на сколько частей разделили целое.", tags: ["дроби", "5 класс"]),
            LibraryItem(title: "Arduino: первый проект", kind: .video, subject: "Робототехника", author: "Марат Касымов", summary: "Мигающий светодиод за 10 минут.", url: sampleVideo, durationMinutes: 10,
                        captions: [CaptionSegment(start: 0, end: 5, text: "Подключим светодиод к пину 13."),
                                   CaptionSegment(start: 5, end: 12, text: "Длинная ножка — плюс, короткая — минус через резистор.")],
                        textAlternative: "Светодиод подключается к пину 13 через резистор 220 Ом. Код: pinMode(13, OUTPUT); в цикле digitalWrite HIGH/LOW с задержкой 500 мс.", tags: ["arduino"]),
            LibraryItem(title: "Present Simple с субтитрами", kind: .video, subject: "Английский", author: "Айгерим Беккали", summary: "Грамматика через примеры.", url: sampleVideo, durationMinutes: 7,
                        captions: [CaptionSegment(start: 0, end: 6, text: "I go to school every day. — Я хожу в школу каждый день.")],
                        textAlternative: "Present Simple используется для регулярных действий: I go, she goes.", tags: ["grammar"]),
            LibraryItem(title: "Адаптация заданий для детей с нарушением слуха", kind: .methodical, subject: "Инклюзия", author: "Жанна Омарова", summary: "Рекомендации педагогу: визуальные опоры, субтитры, письменные инструкции.", textAlternative: "1. Всегда дублируйте устные инструкции письменно. 2. Используйте субтитры. 3. Садите ученика ближе к доске.", forTeachers: true, isTeacherAcademy: true),
            LibraryItem(title: "Методика «Перевёрнутый класс»", kind: .methodical, subject: "Педагогика", author: "KKSU Teacher Academy", summary: "Как организовать урок, где теория изучается дома.", textAlternative: "Ученики смотрят видео дома, а на уроке решают задачи в группах.", forTeachers: true, isTeacherAcademy: true),
            LibraryItem(title: "Учебник «Математика 6»", kind: .textbook, subject: "Математика", author: "Издательство «Атамура»", summary: "Электронная версия учебника.", url: "https://example.org/math6.pdf", textAlternative: "Оглавление: 1. Делимость чисел. 2. Дроби. 3. Пропорции.", tags: ["учебник"]),
            LibraryItem(title: "Инструкция по технике безопасности в лаборатории", kind: .instruction, subject: "Робототехника", author: "KKSU", summary: "Правила работы с паяльником и инструментами.", textAlternative: "Работайте в очках. Не оставляйте паяльник включённым. Отключайте питание перед сборкой."),
            LibraryItem(title: "Презентация «Этапы изобретения»", kind: .presentation, subject: "ТРИЗ", author: "Санжар Исаев", summary: "Idea → Research → Prototype → Testing → Result.", url: "https://example.org/stages.pptx", textAlternative: "5 слайдов: идея, исследование, прототип, испытания, результат."),
            LibraryItem(title: "Положение Young Inventors 30", kind: .pdf, subject: "Изобретательство", author: "KKSU", summary: "Правила подачи заявок и критерии оценки.", url: "https://example.org/yi30.pdf", textAlternative: "Критерии: новизна, техническая проработка, социальная значимость, прототип, презентация.")
        ]

        // MARK: Тесты (29–31, 41)
        let mathTest = KKSUTest(title: "Дроби: проверь себя", subject: "Математика", authorID: teacher.id, questions: [
            TestQuestion(text: "Сколько будет 1/2 + 1/4?", kind: .single, options: ["2/6", "3/4", "1/6", "2/4"], correctIndices: [1], explanation: "1/2 = 2/4, 2/4 + 1/4 = 3/4"),
            TestQuestion(text: "Выберите дроби, равные 1/2", kind: .multiple, options: ["2/4", "3/5", "4/8", "5/9"], correctIndices: [0, 2], points: 2),
            TestQuestion(text: "Вычислите 3/4 × 8", kind: .number, correctText: "6"),
            TestQuestion(text: "Как называется верхнее число дроби?", kind: .text, correctText: "числитель")
        ], timeLimitMinutes: 15)
        let roboTest = KKSUTest(title: "Основы Arduino", subject: "Робототехника", authorID: teacher.id, questions: [
            TestQuestion(text: "Какая функция выполняется один раз при запуске?", kind: .single, options: ["loop()", "setup()", "main()"], correctIndices: [1]),
            TestQuestion(text: "Сколько вольт на выходе 5V?", kind: .number, correctText: "5")
        ])
        let teacherTest = KKSUTest(title: "Итоговый тест: инклюзивный урок", subject: "Педагогика", questions: [
            TestQuestion(text: "Что обязательно при работе с учеником с нарушением слуха?", kind: .multiple, options: ["Субтитры", "Письменные инструкции", "Громкая музыка", "Визуальные опоры"], correctIndices: [0, 1, 3], points: 3),
            TestQuestion(text: "Индивидуальный учебный план сокращённо", kind: .text, correctText: "ИУП")
        ], audience: .teachers)
        db.tests = [mathTest, roboTest, teacherTest]
        db.attempts = [
            TestAttempt(testID: roboTest.id, userID: aliya.id, date: date(-7), answers: [], score: 2, maxScore: 2, passed: true),
            TestAttempt(testID: mathTest.id, userID: timur.id, date: date(-3), answers: [], score: 3, maxScore: 5, passed: true)
        ]

        // MARK: Курс педагога из конструктора (126–130)
        let fractionsIntro = CourseLesson(title: "Что такое дробь", summary: "Числитель, знаменатель и доли на примерах.",
                                          notes: "**Дробь** — это часть целого.\n\nВерхнее число — *числитель*, нижнее — *знаменатель*.\n\nПример: 3/4 — взяли 3 части из 4.",
                                          links: [LessonLink(title: "Тренажёр дробей", url: "https://www.mathsisfun.com/fractions.html")])
        let fractionsLive = CourseLesson(title: "Сложение дробей (онлайн)", summary: "Разбираем задачи вместе на онлайн-уроке.",
                                         liveStart: date(2, 16), testID: mathTest.id)
        db.schoolCourses = [
            SchoolCourse(title: "Дроби за 2 недели", subject: "Математика", summary: "Короткий курс: видео, конспекты и онлайн-урок с педагогом.",
                         teacherID: teacher.id, icon: "function", isPublished: true, createdAt: date(-5),
                         lessons: [fractionsIntro, fractionsLive])
        ]

        // MARK: Чат и уведомления (34, 35)
        let thread = ChatThread(participantIDs: [aliya.id, teacher.id], title: "")
        db.threads = [thread, ChatThread(participantIDs: [parent.id, teacher.id], title: "")]
        db.messages = [
            ChatMessage(threadID: thread.id, senderID: teacher.id, text: "Алия, отличная схема! Не забудь подписать резисторы.", date: date(-1, 12), readBy: [teacher.id, aliya.id]),
            ChatMessage(threadID: thread.id, senderID: aliya.id, text: "Спасибо! Исправлю до пятницы.", date: date(-1, 13), readBy: [aliya.id, teacher.id])
        ]
        db.notifications = [
            KKSUNotification(userID: aliya.id, title: "Работа оценена", body: "Схема робота: 9 баллов", kind: .grade, date: date(-1, 12)),
            KKSUNotification(userID: aliya.id, title: "Скоро дедлайн", body: "«Решить 10 задач на дроби» — через 2 дня", kind: .deadline, date: date(0, 8)),
            KKSUNotification(userID: teacher.id, title: "AI подготовил задание", body: "Проверьте и утвердите задание для Алии", kind: .ai, date: date(0, 8))
        ]

        // MARK: Teacher Academy (37–46)
        db.academyProfiles = [TeacherAcademyProfile(userID: teacher.id, specialization: "Математика, робототехника", experienceYears: 9, organization: "KKSU")]
        db.teacherCourses = [
            TeacherCourse(title: "Инклюзивное образование: практика", hours: 72, level: "Базовый", summary: "Адаптация материалов, ИУП, работа с родителями.", modules: ["Нормативная база", "Адаптация заданий", "ИУП", "Работа с семьёй", "Итоговый проект"], enrolledIDs: [teacher.id], completedModules: [teacher.id.uuidString: ["Нормативная база", "Адаптация заданий"]]),
            TeacherCourse(title: "AI в работе педагога", hours: 36, level: "Средний", summary: "Генерация заданий, проверка, этика AI.", modules: ["Возможности AI", "Промпты для урока", "Проверка AI-контента", "Этика"]),
            TeacherCourse(title: "Проектное обучение и изобретательство", hours: 48, level: "Продвинутый", summary: "Как вести проект от идеи до прототипа.", modules: ["ТРИЗ", "Командная работа", "Прототипирование", "Экспертиза проектов"])
        ]
        let academyTask = Assignment(title: "Разработать адаптированный урок", subject: "Teacher Academy", details: "Подготовьте план урока с адаптацией для ученика с нарушением слуха.", dueDate: date(10, 18), audience: .teachers, courseID: db.teacherCourses[0].id)
        db.assignments.append(academyTask)
        db.tests[2].courseID = db.teacherCourses[0].id

        let method1 = Methodology(title: "Визуальная математика KKSU", author: "Марат Касымов", subject: "Математика", ageGroup: "10–13", summary: "Обучение дробям через визуальные модели и конструктор.", status: .piloting)
        let method2 = Methodology(title: "Инженерный дневник", author: "Санжар Исаев", subject: "Инженерия", ageGroup: "12–17", summary: "Ведение лабораторной тетради как инструмент рефлексии.", status: .approved)
        let method3 = Methodology(title: "Тихий класс", author: "Жанна Омарова", subject: "Инклюзия", ageGroup: "7–12", summary: "Сенсорно-щадящая организация урока.", status: .draft)
        db.methodologies = [method1, method2, method3]
        db.pilots = [
            MethodologyPilot(methodologyID: method1.id, site: "KKSU, 6 класс", teacherName: "Марат Касымов", startDate: date(-90), endDate: date(-10), participants: 24, baselineScore: 58, finalScore: 74, summary: "Рост понимания дробей, снижение тревожности."),
            MethodologyPilot(methodologyID: method2.id, site: "Школа №12, Алматы", teacherName: "Санжар Исаев", startDate: date(-200), endDate: date(-100), participants: 18, baselineScore: 62, finalScore: 79, summary: "Улучшение навыков документирования экспериментов.")
        ]

        // MARK: Проекты (47–59, 64–72)
        let team = ProjectTeam(name: "SmartCane Team", memberIDs: [aliya.id, timur.id], captainID: aliya.id)
        let team2 = ProjectTeam(name: "EcoBots", memberIDs: [dana.id, timur.id], captainID: dana.id)
        db.teams = [team, team2]
        let cane = InventionProject(title: "Умная трость", summary: "Трость с ультразвуковым датчиком и вибросигналом для незрячих людей.", problem: "Незрячие люди не замечают препятствия на уровне головы.", solution: "Датчик HC-SR04 + вибромотор + Arduino Nano.", stage: .prototype, track: .inclusiveEngineering, teamID: team.id, mentorID: mentor.id, authorIDs: [aliya.id, timur.id],
                                    media: [Attachment(fileName: "prototype_v1.jpg", kind: .photo, altText: "Белая трость с чёрным датчиком у рукоятки"), Attachment(fileName: "circuit.dwg", kind: .drawing, altText: "Электрическая схема подключения"), Attachment(fileName: "test_video.mp4", kind: .video, altText: "Видео испытаний в коридоре школы")],
                                    createdAt: date(-80), stageHistory: [StageChange(stage: .idea, date: date(-80), note: "Идея после встречи с обществом незрячих"), StageChange(stage: .research, date: date(-60), note: "Интервью с 5 пользователями"), StageChange(stage: .prototype, date: date(-20), note: "Собран прототип v1")],
                                    isPrototype: true, prototypeSpecs: "Arduino Nano, HC-SR04, вибромотор 3V, аккумулятор 18650", inclusiveTarget: "Люди с нарушением зрения", showInExhibition: true, likes: 42, tags: ["инклюзия", "arduino"])
        let ecobot = InventionProject(title: "EcoBot — сортировщик мусора", summary: "Робот, сортирующий пластик и бумагу с помощью камеры.", problem: "Низкий уровень сортировки отходов в школах.", solution: "Камера + нейросеть ARAI AI + сервоприводы.", stage: .testing, track: .araiAI, teamID: team2.id, mentorID: mentor.id, authorIDs: [dana.id, timur.id], createdAt: date(-100), stageHistory: [StageChange(stage: .testing, date: date(-5), note: "Точность 87%")], isPrototype: true, prototypeSpecs: "Raspberry Pi 4, камера, 2 сервопривода", showInExhibition: true, likes: 31, tags: ["AI", "экология"])
        let solar = InventionProject(title: "Солнечная зарядка для школы", summary: "Станция зарядки гаджетов от солнечной панели.", stage: .research, track: .iken, authorIDs: [dana.id], createdAt: date(-40), tags: ["энергия"])
        let museum = InventionProject(title: "AR-музей «Великий шёлковый путь»", summary: "Дополненная реальность для школьного музея.", stage: .idea, track: .ataMura, authorIDs: [dana.id], createdAt: date(-15))
        let gear = InventionProject(title: "Редуктор для конвейера", summary: "Кейс MASHSTROY: расчёт и 3D-модель редуктора.", stage: .result, track: .mashstroy, mentorID: mentor.id, authorIDs: [timur.id], createdAt: date(-150), isPrototype: true, showInExhibition: true, likes: 18)
        let global1 = InventionProject(title: "Clean Water Sensor (KZ–KR)", summary: "Совместный с Сеулом датчик качества воды.", stage: .prototype, track: .global, authorIDs: [aliya.id, dana.id], createdAt: date(-50), isPrototype: true, showInExhibition: true, likes: 25)
        db.projects = [cane, ecobot, solar, museum, gear, global1]
        db.experiments = [
            ExperimentEntry(projectID: cane.id, authorID: aliya.id, date: date(-15), hypothesis: "Датчик видит препятствие на 2 м", method: "Замер 20 раз на разных расстояниях", result: "Стабильно до 1,8 м", conclusion: "Ограничить порог 1,5 м", success: true),
            ExperimentEntry(projectID: cane.id, authorID: timur.id, date: date(-8), hypothesis: "Вибрация ощущается через перчатку", method: "Тест с 5 участниками", result: "3 из 5 почувствовали", conclusion: "Нужен более мощный мотор", success: false)
        ]
        db.notebook = [
            LabNotebookPage(projectID: cane.id, authorID: aliya.id, date: date(-15), title: "Калибровка датчика", content: "Провели 20 замеров. Погрешность растёт после 1,5 м.", measurements: [LabMeasurement(name: "Дальность", value: 1.8, unit: "м"), LabMeasurement(name: "Погрешность", value: 4, unit: "см")], signedByMentor: true)
        ]
        db.yiApplications = [
            YoungInventorsApplication(projectID: cane.id, applicantID: aliya.id, season: "2026", nomination: "Инклюзивные технологии", motivation: "Хотим помочь незрячим людям безопасно передвигаться.", date: date(-6), status: .underReview)
        ]
        db.reviews = [
            ExpertReview(targetID: method1.id, target: .methodology, expertID: expert.id, date: date(-8), scores: ExpertReview.methodologyCriteria.map { ReviewScore(criterion: $0, score: 8) }, comment: "Методика эффективна, нужна версия для 5 класса.", decision: .revise)
        ]

        // MARK: Global Classroom (60–63)
        db.globalClasses = [
            GlobalClass(title: "Robotics Exchange", country: "Южная Корея", language: "English", partnerSchool: "Seoul STEM Academy", teacherName: "Ms. Kim", start: date(3, 9), summary: "Совместная сборка роботов по видеосвязи.", participantIDs: [aliya.id]),
            GlobalClass(title: "Engineering Talks", country: "Германия", language: "English", partnerSchool: "Munich Tech School", teacherName: "Dr. Weber", start: date(6, 15), summary: "Лекции инженеров о машиностроении.")
        ]
        db.internationalProjects = [
            InternationalProject(title: "Clean Water Sensor", countries: ["Казахстан", "Южная Корея"], partners: "Seoul STEM Academy", summary: "Дешёвый датчик качества воды для сёл.", participantIDs: [aliya.id, dana.id]),
            InternationalProject(title: "Inclusive Playground", countries: ["Казахстан", "Германия", "Турция"], partners: "Munich Tech School", summary: "Проект инклюзивной игровой площадки.")
        ]
        db.internationalExperts = [
            InternationalExpert(name: "Dr. Hans Weber", country: "Германия", expertise: "Машиностроение", bio: "Профессор, 20 лет в индустрии.", email: "weber@example.org", isTeacher: false),
            InternationalExpert(name: "Ms. Ji-woo Kim", country: "Южная Корея", expertise: "Робототехника, STEM", bio: "Учитель года Сеула 2024.", email: "kim@example.org", isTeacher: true),
            InternationalExpert(name: "Dr. Ayşe Demir", country: "Турция", expertise: "Инклюзивный дизайн", bio: "Исследователь универсального дизайна.", email: "demir@example.org", isTeacher: false)
        ]

        // MARK: Future Engineers (64–72)
        db.engineeringCourses = [
            EngineeringCourse(title: "Введение в инженерию", track: .futureEngineers, level: "Начальный", summary: "Как думает инженер.", lessons: ["Инженерное мышление", "Чертёж", "Материалы", "Первый механизм"], enrolledIDs: [aliya.id]),
            EngineeringCourse(title: "3D-моделирование в Fusion", track: .futureEngineers, level: "Средний", summary: "Создание 3D-моделей деталей.", lessons: ["Интерфейс", "Эскиз", "Выдавливание", "Сборка"]),
            EngineeringCourse(title: "Детали машин", track: .mashstroy, level: "Продвинутый", summary: "Курс от инженеров MASHSTROY.", lessons: ["Передачи", "Подшипники", "Редукторы"]),
            EngineeringCourse(title: "Компьютерное зрение", track: .araiAI, level: "Средний", summary: "Распознавание объектов с ARAI AI.", lessons: ["Изображения", "Датасеты", "Обучение модели", "Внедрение"]),
            EngineeringCourse(title: "Энергия будущего", track: .iken, level: "Начальный", summary: "Солнце, ветер, аккумуляторы.", lessons: ["Солнечные панели", "Ветряки", "Хранение энергии"]),
            EngineeringCourse(title: "Цифровое наследие", track: .ataMura, level: "Начальный", summary: "3D-сканирование артефактов.", lessons: ["Фотограмметрия", "AR", "Цифровой музей"])
        ]
        db.challenges = [
            EngineeringChallenge(title: "Мост из спагетти", track: .futureEngineers, summary: "Спроектируйте мост, выдерживающий 2 кг.", steps: ["Расчёт нагрузки", "Эскиз", "Сборка", "Испытание"], difficulty: 2, points: 50, completedIDs: [aliya.id]),
            EngineeringChallenge(title: "Виртуальная сборка манипулятора", track: .futureEngineers, summary: "Соберите манипулятор в симуляторе.", steps: ["Выбор приводов", "Кинематика", "Проверка"], difficulty: 3, points: 80),
            EngineeringChallenge(title: "Оптимизация конвейера", track: .mashstroy, summary: "Сократите простой линии на 15%.", steps: ["Анализ данных", "Узкие места", "Предложение", "Экономический эффект"], difficulty: 4, points: 120, isIndustryCase: true, company: "MASHSTROY"),
            EngineeringChallenge(title: "Контроль качества сварки", track: .mashstroy, summary: "Предложите способ выявления дефектов сварки.", steps: ["Виды дефектов", "Методы контроля", "Решение"], difficulty: 3, points: 100, isIndustryCase: true, company: "MASHSTROY"),
            EngineeringChallenge(title: "Чат-бот для библиотеки", track: .araiAI, summary: "Бот на базе ARAI AI отвечает на вопросы о книгах.", steps: ["Сценарии", "Данные", "Тест"], difficulty: 2, points: 60),
            EngineeringChallenge(title: "Пандус-трансформер", track: .inclusiveEngineering, summary: "Складной пандус для крыльца школы.", steps: ["Нормы уклона", "Конструкция", "Макет"], difficulty: 3, points: 90)
        ]

        // MARK: Стажировки и мероприятия (95–99)
        db.internships = [
            Internship(partnerID: mashstroy.id, title: "Юный инженер-конструктор", summary: "2 недели в конструкторском бюро.", requirements: "14+, базовое черчение", start: date(30), durationWeeks: 2, seats: 5),
            Internship(partnerID: arai.id, title: "AI-лаборатория", summary: "Разметка данных и обучение моделей.", requirements: "Python, 15+", start: date(45), durationWeeks: 3, seats: 3),
            Internship(partnerID: iken.id, title: "Эко-исследователь", summary: "Полевые замеры качества воздуха.", requirements: "12+", start: date(20), durationWeeks: 1, seats: 10)
        ]
        db.internshipApplications = [
            InternshipApplication(internshipID: db.internships[0].id, studentID: timur.id, motivation: "Хочу стать конструктором.", date: date(-3), status: .interview)
        ]
        let conf = KKSUEvent(title: "KKSU Inclusive Tech Conference 2026", kind: .conference, date: date(14, 10), location: "Алматы, KKSU", isOnline: false, summary: "Конференция об инклюзивных технологиях в образовании.", capacity: 200, isInternational: true, hours: 8)
        let webinar = KKSUEvent(title: "Вебинар: AI и дети", kind: .webinar, date: date(4, 17), location: "Онлайн", isOnline: true, meetingURL: "https://meet.jit.si/KKSU-AI-webinar", summary: "Безопасное использование AI.", capacity: 500, hours: 2)
        let pastExpo = KKSUEvent(title: "Выставка изобретений KKSU", kind: .exhibition, date: date(-20, 11), location: "KKSU", isOnline: false, summary: "Показ прототипов учеников.", capacity: 150, hours: 4)
        db.events = [conf, webinar, pastExpo]
        db.eventRegistrations = [
            EventRegistration(eventID: conf.id, userID: teacher.id, role: .speaker, talkTitle: "Визуальная математика", date: date(-4)),
            EventRegistration(eventID: pastExpo.id, userID: aliya.id, role: .participant, date: date(-30), attended: true)
        ]

        db.accessibility[aliya.id] = AccessibilitySettings(textScale: 1.1, captionsEnabled: true, showTextAlternatives: true)
        db.preferences[aliya.id] = LearningPreferences(pace: .normal, formats: [.video, .interactive], sessionMinutes: 25, interests: ["Робототехника", "Математика"])
        db.preferences[timur.id] = LearningPreferences(pace: .gentle, formats: [.interactive], sessionMinutes: 15)
        return db
    }
}
