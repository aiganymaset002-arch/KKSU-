# KKSU Online — 100 технических задач

Все 100 задач реализованы в iOS-приложении (SwiftUI). В самом приложении их список открывается в разделе **Профиль → Карта 100 задач** (`FeatureMapView`): каждая строка ведёт в соответствующий модуль.

| № | Задача | Экран / тип | Файл |
|---|---|---|---|
| 1 | Главная страница KKSU Online | `KKSULandingView` | `KKSU/Features/KKSURootViews.swift` |
| 2 | Регистрация пользователей | `RegistrationView` | `RegistrationView.swift` |
| 3 | Вход и восстановление пароля | `LoginView, ForgotPasswordView` | `LoginView.swift`, `ForgotPasswordView.swift` |
| 4 | Роли: ученик, родитель, педагог, психолог, эксперт, наставник, партнёр, администратор | `KKSURole, UserManagementView` | `User.swift`, `KKSU/Features/KKSUCabinets.swift` |
| 5 | Личный кабинет ученика | `StudentCabinetView` | `KKSU/Features/KKSUCabinets.swift` |
| 6 | Кабинет родителя | `ParentHomeView` | `ParentHomeView.swift` |
| 7 | Кабинет преподавателя | `TeacherHomeView` | `TeacherHomeView.swift` |
| 8 | Кабинет эксперта/наставника | `ExpertCabinetView` | `KKSU/Features/KKSUCabinets.swift` |
| 9 | Административная панель | `AdminPanelView` | `KKSU/Features/KKSUCabinets.swift` |
| 10 | Профиль ученика | `StudentProfileEditorView` | `KKSU/Features/KKSUStudentModules.swift` |
| 11 | Цифровая анкета первичного поступления | `IntakeQuestionnaireView` | `KKSU/Features/KKSUStudentModules.swift` |
| 12 | Онлайн-заявка на обучение | `EnrollmentApplicationView` | `KKSU/Features/KKSUStudentModules.swift` |
| 13 | Система согласий родителей | `ConsentsView` | `KKSU/Features/KKSUStudentModules.swift` |
| 14 | Каталог образовательных программ | `ProgramCatalogView` | `KKSU/Features/KKSUStudentModules.swift` |
| 15 | Индивидуальная образовательная траектория | `TrajectoryView` | `KKSU/Features/KKSUStudentModules.swift` |
| 16 | Индивидуальный учебный план | `StudyPlanView` | `KKSU/Features/KKSUStudentModules.swift` |
| 17 | Расписание занятий | `LessonsView` | `LessonsView.swift` |
| 18 | Календарь ученика | `StudentCalendarView` | `KKSU/Features/KKSUStudentModules.swift` |
| 19 | Система домашних заданий | `HomeworkListView` | `KKSU/Features/KKSUStudentModules.swift` |
| 20 | Загрузка выполненных работ | `HomeworkListView` — Фото, видео, документы | `KKSU/Features/KKSUStudentModules.swift` |
| 21 | Оценки и обратная связь преподавателя | `GradingQueueView` | `KKSU/Features/KKSUStudentModules.swift` |
| 22 | Электронное портфолио ученика | `PortfolioView` | `KKSU/Features/KKSUStudentModules.swift` |
| 23 | Система достижений и сертификатов | `AchievementsView` | `KKSU/Features/KKSUStudentModules.swift` |
| 24 | Дашборд прогресса | `ProgressDashboardView` | `KKSU/Features/KKSUStudentModules.swift` |
| 25 | История обучения | `LearningHistoryView` | `KKSU/Features/KKSUStudentModules.swift` |
| 26 | Библиотека видеоуроков | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 27 | Библиотека методических материалов | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 28 | База PDF, презентаций, инструкций и учебников | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 29 | Онлайн-тестирование | `TestListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 30 | Автоматическая проверка тестов | `TestListView` — Один/несколько ответов, число, текст | `KKSU/Features/KKSULibraryAndTests.swift` |
| 31 | Конструктор тестов для преподавателей | `TestBuilderView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 32 | Модуль онлайн-занятий | `LessonsView` | `LessonsView.swift` |
| 33 | Ссылки/интеграция видеоконференций | `LessonsView` — Jitsi (автокомната), Zoom, Meet, Teams | `LessonsView.swift` |
| 34 | Внутренний чат ученик–преподаватель | `ChatListView` | `KKSU/Features/KKSUCommunication.swift` |
| 35 | Уведомления | `NotificationsView` — В приложении + системные | `KKSU/Features/KKSUCommunication.swift` |
| 36 | Система дедлайнов | `DeadlinesView` | `KKSU/Features/KKSUStudentModules.swift` |
| 37 | KKSU Teacher Academy | `TeacherAcademyView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 38 | Регистрация педагогов в Teacher Academy | `AcademyRegistrationView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 39 | Курсы повышения квалификации | `AcademyCoursesView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 40 | Методическая библиотека Teacher Academy | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 41 | Задания и тестирование педагогов | `AcademyTasksView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 42 | Электронные сертификаты Teacher Academy | `CertificatesView` — Автовыдача после курса, PDF | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 43 | Каталог авторских методик KKSU | `MethodologyCatalogView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 44 | Раздел апробации методик | `PilotsView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 45 | Форма экспертной оценки методик | `MethodologyReviewQueueView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 46 | Реестр результатов апробации | `PilotRegistryView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 47 | KKSU Inventions | `InventionsView` | `KKSU/Features/KKSUInventions.swift` |
| 48 | Карточка изобретения/проекта | `InventionsView` — ProjectDetailView | `KKSU/Features/KKSUInventions.swift` |
| 49 | Фото, видео, чертежи и документы проекта | `InventionsView` — Вкладка «Материалы» в карточке | `KKSU/Features/KKSUInventions.swift` |
| 50 | Проектные команды учеников | `TeamsView` | `KKSU/Features/KKSUInventions.swift` |
| 51 | Назначение наставника на проект | `InventionsView` — В карточке проекта | `KKSU/Features/KKSUInventions.swift` |
| 52 | Стадии проекта Idea → Research → Prototype → Testing → Result | `InventionsView` | `KKSU/Features/KKSUInventions.swift` |
| 53 | Журнал экспериментов | `InventionsView` — Вкладка в карточке проекта | `KKSU/Features/KKSUInventions.swift` |
| 54 | Электронная лабораторная тетрадь | `InventionsView` — Вкладка в карточке проекта | `KKSU/Features/KKSUInventions.swift` |
| 55 | Каталог прототипов KKSU | `PrototypeCatalogView` | `KKSU/Features/KKSUInventions.swift` |
| 56 | Young Inventors 30 | `YoungInventorsView` | `KKSU/Features/KKSUInventions.swift` |
| 57 | Подача заявок в Young Inventors | `YoungInventorsApplyView` | `KKSU/Features/KKSUInventions.swift` |
| 58 | Экспертное рассмотрение проектов | `YoungInventorsReviewView` | `KKSU/Features/KKSUInventions.swift` |
| 59 | Виртуальная выставка изобретений | `VirtualExhibitionView` | `KKSU/Features/KKSUInventions.swift` |
| 60 | Global Classroom | `GlobalClassroomView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 61 | Международные онлайн-классы | `GlobalClassesView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 62 | Совместные международные проекты | `InternationalProjectsView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 63 | Международные преподаватели и эксперты | `InternationalExpertsView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 64 | Future Engineers | `FutureEngineersView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 65 | Инженерные онлайн-курсы | `EngineeringCoursesView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 66 | Виртуальные инженерные задания | `ChallengesView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 67 | Проектные кейсы MASHSTROY | `ChallengesView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 68 | Интеграционный раздел ARAI AI | `TrackHubView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 69 | Проекты IKEN | `TrackHubView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 70 | Проекты ATA MURA | `TrackHubView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 71 | Раздел Inclusive Engineering | `TrackHubView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 72 | Каталог инклюзивных инженерных разработок | `InclusiveCatalogView` | `KKSU/Features/KKSUGlobalAndEngineering.swift` |
| 73 | Адаптивный интерфейс платформы | `AccessibilitySettingsView` — iPhone/iPad, Dynamic Type, VoiceOver | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 74 | Размер текста, контраст и интерфейс | `AccessibilitySettingsView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 75 | Субтитры к видео | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 76 | Текстовые альтернативы материалам | `LibraryListView` | `KKSU/Features/KKSULibraryAndTests.swift` |
| 77 | Индивидуальные настройки обучения | `LearningSettingsView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 78 | Рекомендации образовательного контента | `RecommendationsView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 79 | AI-помощник KKSU | `AIAssistantView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 80 | AI-помощник преподавателя | `AIAssistantView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 81 | Генерация индивидуальных заданий с проверкой педагогом | `AITaskGeneratorView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 82 | Анализ учебного прогресса | `ProgressAnalysisView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 83 | Рекомендации преподавателю на основе данных | `TeacherRecommendationsView` | `KKSU/Features/KKSUAIAndPersonalization.swift` |
| 84 | Impact Dashboard | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 85 | Автоподсчёт учеников, занятий, проектов и результатов | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 86 | Показатели образовательного прогресса | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 87 | Показатели проектов и изобретений | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 88 | Показатели партнёрств | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 89 | Показатели международной деятельности | `ImpactDashboardView` | `KKSU/Features/KKSUImpact.swift` |
| 90 | Генератор KKSU Impact Report | `ImpactReportView` | `KKSU/Features/KKSUImpact.swift` |
| 91 | Impact Report в PDF | `ImpactReportView` | `KKSU/Features/KKSUImpact.swift` |
| 92 | Публичная страница Impact | `ImpactPublicView` | `KKSU/Features/KKSUImpact.swift` |
| 93 | Каталог партнёров KKSU | `PartnersView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
| 94 | Кабинет организации-партнёра | `PartnerCabinetView` | `KKSU/Features/KKSUCabinets.swift` |
| 95 | Раздел стажировок | `InternshipsView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
| 96 | Заявки учеников на стажировки | `InternshipsView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
| 97 | Конференции и мероприятия | `EventsView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
| 98 | Регистрация на конференции | `EventsView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
| 99 | Электронные сертификаты участников | `CertificatesView` | `KKSU/Features/KKSUTeacherAcademy.swift` |
| 100 | Единая административная аналитика KKSU | `AnalyticsView` | `KKSU/Features/KKSUPartnersEventsAnalytics.swift` |
