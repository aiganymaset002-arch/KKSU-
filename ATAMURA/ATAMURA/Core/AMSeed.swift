//
//  AMSeed.swift
//  ATA MURA
//
//  Стартовое наполнение: темы энциклопедии, места карты, забытые идеи,
//  рубрики Creator Studio, курсы и демо-публикации (помечены как демо).
//  Исторические справки краткие — их стоит проверить и дополнить источниками.
//

import Foundation

enum AMSeed {
    static func database() -> AMDatabase {
        var db = AMDatabase()

        // Демо-авторы (без пароля: войти под ними нельзя, они удаляются при подключении сервера).
        var aigerim = AMUser(fullName: "Айгерим Н. (демо)", email: "demo1@atamura.kz")
        aigerim.city = "Астана"; aigerim.region = .astana; aigerim.titles = ["Researcher", "Storyteller"]
        aigerim.points = 420; aigerim.birthYear = 2007
        var dauren = AMUser(fullName: "Даурен С. (демо)", email: "demo2@atamura.kz")
        dauren.city = "Караганда"; dauren.region = .karaganda; dauren.titles = ["Inventor"]
        dauren.skills = ["Arduino", "3D printing"]; dauren.points = 1150; dauren.birthYear = 2010
        var mentor = AMUser(fullName: "Проф. Мария К. (демо)", email: "demo3@atamura.kz")
        mentor.city = "Алматы"; mentor.region = .almaty; mentor.titles = ["Historian", "Mentor"]
        mentor.isMentor = true; mentor.expertise = ["История железных дорог", "Railway Engineering", "Архивы", "History"]
        var engineer = AMUser(fullName: "Ерлан Т. (демо)", email: "demo4@atamura.kz")
        engineer.city = "Жезказган"; engineer.region = .ulytau; engineer.titles = ["Engineer", "Mentor"]
        engineer.isMentor = true; engineer.expertise = ["Горное дело", "Mining", "Электроника", "Arduino", "Inclusive Engineering"]
        db.users = [aigerim, dauren, mentor, engineer]

        // Темы энциклопедии («Связать с историей»).
        let turksib = AMTopic(title: "Турксиб", summary: "Туркестано-Сибирская железная дорога, построенная в 1927–1930 годах. Соединила Сибирь и Среднюю Азию; «серебряное звено» уложено в 1930 году на станции Айнабулак.",
                              region: .jetisu, period: "1927–1931", keywords: ["турксиб", "turksib", "железн", "railway", "темір жол"])
        let silkRoad = AMTopic(title: "Великий Шёлковый путь", summary: "Сеть караванных путей между Китаем и Средиземноморьем. Через Казахстан проходили города Отрар, Тараз, Сайрам, Туркестан.",
                               region: .turkistan, period: "II в. до н. э. — XV в.", keywords: ["шёлков", "шелков", "silk road", "отрар", "караван", "жібек"])
        let baikonur = AMTopic(title: "Байконур", summary: "Космодром в Кызылординской области, основан в 1955 году. Отсюда в 1957 году запущен первый искусственный спутник Земли, а в 1961 году — Юрий Гагарин.",
                               region: .kyzylorda, period: "с 1955", keywords: ["байконур", "baikonur", "космос", "космодром", "ғарыш"])
        let copper = AMTopic(title: "Медь Жезказгана", summary: "Одно из крупнейших месторождений меди. Исследование района связано с именем геолога Каныша Сатпаева.",
                             region: .ulytau, period: "XX век", keywords: ["жезказган", "сатпаев", "медь", "copper", "шахт", "mining"])
        let yasawi = AMTopic(title: "Мавзолей Ходжи Ахмеда Ясави", summary: "Мавзолей в Туркестане, построенный в конце XIV века по приказу Тимура. Объект Всемирного наследия ЮНЕСКО.",
                             region: .turkistan, period: "XIV век", keywords: ["ясави", "yasawi", "туркестан", "мавзолей"])
        let goldenMan = AMTopic(title: "Золотой человек", summary: "Сакское захоронение в кургане Иссык с одеждой, украшенной золотыми пластинами. Один из символов Казахстана.",
                                region: .almatyRegion, period: "V–III вв. до н. э.", keywords: ["золотой человек", "иссык", "сак", "алтын адам", "golden man"])
        let semipalatinsk = AMTopic(title: "Семипалатинский полигон", summary: "Ядерный полигон, действовавший в 1949–1989 годах. Закрыт в 1991 году; движение «Невада — Семей» стало символом борьбы за безъядерный мир.",
                                    region: .abai, period: "1949–1991", keywords: ["полигон", "семей", "невада", "nevada", "semipalatinsk"])
        let botai = AMTopic(title: "Ботай", summary: "Энеолитическое поселение в Северном Казахстане, связанное с ранними свидетельствами использования лошади человеком.",
                            region: .northKazakhstan, period: "IV тыс. до н. э.", keywords: ["ботай", "botai", "лошад", "жылқы"])
        db.topics = [turksib, silkRoad, baikonur, copper, yasawi, goldenMan, semipalatinsk, botai]

        // Карта.
        db.places = [
            AMPlace(title: "Станция Айнабулак — смычка Турксиба", summary: "Место соединения северного и южного участков Турксиба (1930).",
                    kind: .monument, region: .jetisu, latitude: 44.60, longitude: 78.10, period: "1930", topicIds: [turksib.id]),
            AMPlace(title: "Космодром Байконур", summary: "Первый в мире космодром; старт спутника (1957) и полёт Гагарина (1961).",
                    kind: .enterprise, region: .kyzylorda, latitude: 45.965, longitude: 63.305, period: "с 1955", topicIds: [baikonur.id]),
            AMPlace(title: "Городище Отрар", summary: "Средневековый город на Шёлковом пути, место рождения учёного аль-Фараби (по традиции).",
                    kind: .settlement, region: .turkistan, latitude: 42.85, longitude: 68.30, period: "I–XVIII вв.", topicIds: [silkRoad.id]),
            AMPlace(title: "Мавзолей Ходжи Ахмеда Ясави", summary: "Шедевр архитектуры тимуридской эпохи, объект ЮНЕСКО.",
                    kind: .monument, region: .turkistan, latitude: 43.293, longitude: 68.270, period: "XIV век", topicIds: [yasawi.id]),
            AMPlace(title: "Жезказганские рудники", summary: "Медные рудники; здесь работал геолог Каныш Сатпаев.",
                    kind: .mine, region: .ulytau, latitude: 47.80, longitude: 67.71, period: "XX век", topicIds: [copper.id]),
            AMPlace(title: "Каныш Сатпаев", summary: "Геолог, первый президент Академии наук Казахской ССР. Исследовал Жезказганский район.",
                    kind: .person, region: .ulytau, latitude: 47.78, longitude: 67.76, period: "1899–1964", topicIds: [copper.id]),
            AMPlace(title: "Курган Иссык", summary: "Место находки «Золотого человека» (1969).",
                    kind: .settlement, region: .almatyRegion, latitude: 43.36, longitude: 77.45, period: "V–III вв. до н. э.", topicIds: [goldenMan.id]),
            AMPlace(title: "Петроглифы Тамгалы", summary: "Наскальные рисунки бронзового века, объект Всемирного наследия ЮНЕСКО.",
                    kind: .legend, region: .almatyRegion, latitude: 43.80, longitude: 75.53, period: "Бронзовый век"),
            AMPlace(title: "Монумент «Сильнее смерти»", summary: "Памятник жертвам ядерных испытаний в Семее.",
                    kind: .monument, region: .abai, latitude: 50.41, longitude: 80.25, period: "2002", topicIds: [semipalatinsk.id]),
            AMPlace(title: "Мавзолей Козы Корпеш — Баян сулу", summary: "Памятник, связанный с лиро-эпической легендой о Козы Корпеше и Баян сулу.",
                    kind: .legend, region: .abai, latitude: 47.90, longitude: 80.40, period: "X–XI вв. (по преданию)"),
            AMPlace(title: "Байтерек", summary: "Символ столицы, монумент «Астана — Байтерек».",
                    kind: .monument, region: .astana, latitude: 51.128, longitude: 71.430, period: "2002"),
            AMPlace(title: "Карагандинский угольный бассейн", summary: "Крупный угольный бассейн и центр горной инженерии.",
                    kind: .mine, region: .karaganda, latitude: 49.80, longitude: 73.10, period: "с XIX века"),
            AMPlace(title: "Городище Сарайшык", summary: "Средневековый город на реке Урал (Жайык).",
                    kind: .settlement, region: .atyrau, latitude: 47.50, longitude: 51.75, period: "X–XVI вв."),
            AMPlace(title: "Поселение Ботай", summary: "Энеолитическое поселение древних коневодов.",
                    kind: .settlement, region: .northKazakhstan, latitude: 53.30, longitude: 67.60, period: "IV тыс. до н. э.", topicIds: [botai.id]),
            AMPlace(title: "Демо: школьный проект «Умная юрта»", summary: "Пример школьного проекта на карте: юрта с датчиками температуры и солнечной панелью.",
                    kind: .schoolProject, region: .karaganda, latitude: 49.82, longitude: 73.08, period: "2026")
        ]

        // Forgotten Ideas of Kazakhstan.
        db.forgottenIdeas = [
            AMForgottenIdea(title: "Переброска части стока сибирских рек в Среднюю Азию", year: "1970–1980-е",
                            author: "Советские научные институты", region: .kostanay,
                            summary: "Проект канала, который должен был направить часть воды сибирских рек в Казахстан и Среднюю Азию для орошения и спасения Аральского моря.",
                            whyNotRealized: "Работы остановлены в 1986 году из-за экологических рисков и стоимости.",
                            source: "Постановление ЦК КПСС и Совета Министров СССР, 1986"),
            AMForgottenIdea(title: "Демо: ветровая станция у Джунгарских ворот", year: "1980-е (пример)", author: "Пример для заполнения",
                            region: .jetisu, summary: "Пример карточки: идея использовать сильные ветра Джунгарских ворот для выработки энергии.",
                            whyNotRealized: "Добавьте реальные данные и источник.", source: ""),
            AMForgottenIdea(title: "Демо: солнечный опреснитель для Мангистау", year: "Пример", author: "Пример для заполнения",
                            region: .mangystau, summary: "Пример карточки: опреснение морской воды Каспия с помощью солнечной энергии для посёлков.",
                            whyNotRealized: "Добавьте реальные данные и источник.", source: "")
        ]

        // Публикации (демо).
        var post1 = AMPost(authorId: mentor.id, authorName: mentor.fullName, type: .history, evidence: .scientific, region: .jetisu,
                           title: "Как строился Турксиб",
                           body: "Туркестано-Сибирская магистраль строилась с 1927 по 1930 год. Строители шли навстречу друг другу с севера и с юга, а соединение участков произошло на станции Айнабулак. Дорога связала хлеб и лес Сибири с хлопком Средней Азии и дала толчок развитию городов вдоль линии.",
                           sources: [AMSource(kind: .book, title: "История Казахстана с древнейших времён до наших дней", detail: "Т. 4")],
                           topicIds: [turksib.id], status: .approved, verification: .sourceConfirmed)
        post1.createdAt = Date().addingTimeInterval(-86_400 * 2)
        var post2 = AMPost(authorId: aigerim.id, authorName: aigerim.fullName, type: .familyStory, evidence: .oralHistory, region: .jetisu,
                           title: "Мой дед строил Турксиб (демо)",
                           body: "Пример семейной истории: рассказ бабушки о том, как дед работал на строительстве Турксиба, жил в палатке и получил грамоту. Добавьте фото, документы и аудио интервью.",
                           topicIds: [turksib.id], status: .approved, verification: .authorOpinion, heroName: "Дед (демо)", heroYears: "1905–1979")
        post2.createdAt = Date().addingTimeInterval(-86_400)
        let post3 = AMPost(authorId: aigerim.id, authorName: aigerim.fullName, type: .hypothesis, evidence: .hypothesis, region: .turkistan,
                           title: "Почему древние поселения строились у рек и предгорий? (демо)",
                           body: "Гипотеза: города Шёлкового пути возникали там, где сходились вода, пастбища и караванные пути. Предлагаю сравнить карты рек и городищ Туркестанской области.",
                           sources: [AMSource(kind: .map, title: "Археологическая карта Казахстана", detail: "")],
                           topicIds: [silkRoad.id], status: .approved, verification: .hypothesis)
        db.posts = [post1, post2, post3]

        // Inventors Lab (демо).
        var smartDombra = AMProject(ownerId: dauren.id, ownerName: dauren.fullName, authorAge: 14, title: "Smart Dombra",
                                    region: .astana, city: "Astana", direction: .inclusiveEngineering, stage: .prototype)
        smartDombra.problem = "Слабослышащие дети не чувствуют музыку домбры."
        smartDombra.idea = "Браслет, который превращает звук домбры в вибрацию разной силы."
        smartDombra.prototype = "ESP32 + микрофон + 3 вибромотора на браслете."
        smartDombra.helpNeeded = ["Arduino", "3D printing"]
        smartDombra.lookingForTeam = true
        smartDombra.teamNeeds = "Ищем инженера-электронщика"
        smartDombra.status = .approved
        db.projects = [smartDombra]

        // История глазами ребёнка.
        db.kidsThemes = [
            AMKidsTheme(title: "Как выглядел бы Шёлковый путь сегодня?", prompt: "Нарисуй или собери модель каравана будущего: на чём едут, что везут, где отдыхают."),
            AMKidsTheme(title: "Технологии для древнего кочевого города", prompt: "Как современные технологии могли бы помочь жителям древнего города или кочевникам?"),
            AMKidsTheme(title: "Юрта будущего", prompt: "Придумай юрту XXI века: энергия, свет, тепло, связь."),
            AMKidsTheme(title: "Турксиб глазами детей", prompt: "Покажи, как строили железную дорогу: рисунок, LEGO-поезд или комикс.")
        ]

        // Новости, журнал, курсы, Marketplace.
        db.news = [
            AMNews(title: LocalizedText(ru: "ATA MURA v1.0 открыта", en: "ATA MURA v1.0 is live", kk: "ATA MURA v1.0 ашылды"),
                   body: LocalizedText(ru: "Платформа, где наследие сохраняют, историю исследуют, знания публикуют, а идеи превращают в будущее. Публикуйте истории, проекты и исследования!",
                                       en: "A platform where heritage is preserved, history is researched, knowledge is published and ideas become the future. Share your stories, projects and research!",
                                       kk: "Мұра сақталатын, тарих зерттелетін, білім жарияланатын және идеялар болашаққа айналатын платформа. Әңгімелеріңізді, жобаларыңызды және зерттеулеріңізді жариялаңыз!"),
                   pinned: true, authorName: "ATA MURA"),
            AMNews(title: LocalizedText(ru: "Открыт набор в Kids Inventors Lab", en: "Kids Inventors Lab enrolment is open", kk: "Kids Inventors Lab-қа қабылдау ашылды"),
                   body: LocalizedText(ru: "Приглашаем школьников 10–17 лет создать своё первое изобретение вместе с наставниками ATA MURA.",
                                       en: "Students aged 10–17 are invited to build their first invention with ATA MURA mentors.",
                                       kk: "10–17 жастағы оқушыларды ATA MURA тәлімгерлерімен бірге алғашқы өнертабысын жасауға шақырамыз."),
                   publishAt: Date().addingTimeInterval(-3600), authorName: "ATA MURA")
        ]
        db.magazines = [
            AMMagazineIssue(number: 1, title: LocalizedText(ru: "Heritage & Innovation", en: "Heritage & Innovation", kk: "Heritage & Innovation"),
                            summary: LocalizedText(ru: "Первый выпуск: Турксиб, юные изобретатели и инклюзивная инженерия.",
                                                   en: "First issue: Turksib, young inventors and inclusive engineering.",
                                                   kk: "Бірінші шығарылым: Түрксіб, жас өнертапқыштар және инклюзивті инженерия."),
                            authors: "Редакция ATA MURA", editorialBoard: "Главный редактор — ATA MURA", price: 0, published: true)
        ]
        db.courses = [
            AMCourse(title: LocalizedText(ru: "История Казахстана через технологии", en: "Kazakhstan's History Through Technology", kk: "Қазақстан тарихы технологиялар арқылы"),
                     summary: LocalizedText(ru: "От Ботая до Байконура: как инженерные решения меняли жизнь на нашей земле.",
                                            en: "From Botai to Baikonur: how engineering changed life on our land.",
                                            kk: "Ботайдан Байқоңырға дейін: инженерлік шешімдер өмірді қалай өзгертті."),
                     teacher: "ATA MURA Academy",
                     lessons: [AMLesson(title: "Ботай: первые коневоды", text: "Урок о поселении Ботай и одомашнивании лошади."),
                               AMLesson(title: "Шёлковый путь: инженерия караванов", text: "Караван-сараи, колодцы, навигация."),
                               AMLesson(title: "Турксиб: железная дорога через степь", text: "Как строили магистраль и что она изменила."),
                               AMLesson(title: "Байконур: дорога в космос", text: "Почему космодром построили в Казахстане.")],
                     access: .paid, price: 12_000, published: true),
            AMCourse(title: LocalizedText(ru: "Arduino для юных изобретателей", en: "Arduino for Young Inventors", kk: "Жас өнертапқыштарға арналған Arduino"),
                     summary: LocalizedText(ru: "Бесплатный курс: от светодиода до первого инклюзивного устройства.",
                                            en: "Free course: from an LED to your first inclusive device.",
                                            kk: "Тегін курс: жарық диодтан алғашқы инклюзивті құрылғыға дейін."),
                     teacher: "Kids Inventors Lab",
                     lessons: [AMLesson(title: "Что такое Arduino", text: "Плата, питание, первая программа Blink."),
                               AMLesson(title: "Датчики и вибромоторы", text: "Как устройство чувствует мир и отвечает вибрацией.",
                                        quiz: [AMQuizQuestion(question: "Какой компонент создаёт вибрацию?", options: ["Светодиод", "Вибромотор", "Резистор"], correctIndex: 1)])],
                     access: .free, published: true)
        ]
        db.products = [
            AMProduct(kind: .ebook, title: "100 People — 100 Stories (электронная книга)", summary: "Лучшие истории участников ATA MURA.", price: 3_000),
            AMProduct(kind: .kit, title: "Набор Kids Inventors Lab", summary: "Плата, датчики, вибромоторы и инструкция к первому проекту.", price: 25_000, stock: 30),
            AMProduct(kind: .ticket, title: "Билет на ATA MURA Expedition", summary: "Экскурсия-экспедиция по историческим местам региона.", price: 8_000)
        ]

        // Creator Studio.
        let s100 = AMSeries(name: "100 историй Казахстана", summary: "Интервью и семейные истории", plannedEpisodes: 100)
        let sInventor = AMSeries(name: "Young Inventor of the Week", summary: "Проект недели", plannedEpisodes: 52)
        let sExpedition = AMSeries(name: "ATA MURA Expedition", summary: "Выезды по регионам", plannedEpisodes: 20)
        let sForgotten = AMSeries(name: "Forgotten Ideas", summary: "Забытые идеи и их продолжение", plannedEpisodes: 20)
        let sInclusive = AMSeries(name: "Inclusive Engineering", summary: "Технологии для всех", plannedEpisodes: 20)
        let sMinute = AMSeries(name: "1 Minute of Kazakhstan History", summary: "Shorts за минуту", plannedEpisodes: 100)
        db.series = [s100, sInventor, sExpedition, sForgotten, sInclusive, sMinute]
        var turksibVideo = AMContentItem(title: "История Турксиба глазами детей", seriesId: s100.id, platforms: [.youtube, .shorts, .instagram])
        turksibVideo.status = .script
        turksibVideo.shootDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())
        turksibVideo.publishDate = Calendar.current.date(byAdding: .day, value: 12, to: Date())
        turksibVideo.idea = "Дети рассказывают, как строили Турксиб, и рисуют поезд будущего."
        turksibVideo.hook = "«А вы знали, что дорогу через степь построили всего за три года?»"
        db.contentItems = [turksibVideo]
        db.tasks = [
            AMTask(title: "Дописать сценарий YouTube", due: Date()),
            AMTask(title: "Подготовить пост LinkedIn", due: Date())
        ]
        db.events = [
            AMEvent(title: "Выставка юных изобретателей ATA MURA", date: Date().addingTimeInterval(86_400 * 20), place: "Астана",
                    summary: "Презентация проектов Inventors Lab.")
        ]
        return db
    }
}
