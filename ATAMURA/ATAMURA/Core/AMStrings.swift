//
//  AMStrings.swift
//  ATA MURA
//
//  Тексты интерфейса на трёх языках: ключ¦русский¦English¦қазақша.
//  Хранятся одной строкой и разбираются при первом обращении — так большой словарь
//  не замедляет компиляцию. «\n» внутри текста — перенос строки, %@ — подстановка.
//

import Foundation

enum AMStrings {
    static let table: [String: AMString] = {
        var result: [String: AMString] = [:]
        for line in raw.split(separator: "\n") {
            let parts = line.split(separator: "¦", omittingEmptySubsequences: false).map {
                String($0).replacingOccurrences(of: "\\n", with: "\n")
            }
            guard parts.count == 4 else { continue }
            result[parts[0]] = AMString(ru: parts[1], en: parts[2], kk: parts[3])
        }
        return result
    }()

    private static let raw = #"""
tab.home¦Главная¦Home¦Басты бет
tab.map¦Карта¦Map¦Карта
tab.create¦Создать¦Create¦Жасау
tab.profile¦Профиль¦Profile¦Профиль
common.add¦Добавить¦Add¦Қосу
common.addPhoto¦Добавить фото¦Add photo¦Фото қосу
common.all¦Все¦All¦Барлығы
common.allRegions¦Все регионы¦All regions¦Барлық өңірлер
common.back¦Назад¦Back¦Артқа
common.cancel¦Отмена¦Cancel¦Болдырмау
common.close¦Закрыть¦Close¦Жабу
common.delete¦Удалить¦Delete¦Жою
common.deleteConfirm¦Удалить безвозвратно?¦Delete permanently?¦Біржола жою керек пе?
common.edit¦Изменить¦Edit¦Өзгерту
common.listen¦Слушать¦Listen¦Тыңдау
common.next¦Далее¦Next¦Келесі
common.notFound¦Материал не найден или удалён.¦Not found or deleted.¦Материал табылмады немесе жойылды.
common.notSelected¦Не выбрано¦Not selected¦Таңдалмаған
common.photo¦Фотография¦Photo¦Фотосурет
common.region¦Регион¦Region¦Өңір
common.save¦Сохранить¦Save¦Сақтау
common.send¦Отправить¦Send¦Жіберу
common.share¦Поделиться¦Share¦Бөлісу
common.stop¦Стоп¦Stop¦Тоқтату
common.watchVideo¦Смотреть видео¦Watch video¦Бейнені көру
price.free¦Бесплатно¦Free¦Тегін
welcome.slogan.1¦Preserve the past — сохраняем прошлое.¦Preserve the past.¦Preserve the past — өткенді сақтаймыз.
welcome.slogan.2¦Research the present — исследуем настоящее.¦Research the present.¦Research the present — бүгінді зерттейміз.
welcome.slogan.3¦Invent the future — изобретаем будущее.¦Invent the future.¦Invent the future — болашақты ойлап табамыз.
welcome.about¦Цифровая платформа Казахстана, где наследие сохраняют, историю исследуют, знания публикуют, а идеи превращают в будущее.¦A digital platform of Kazakhstan where heritage is preserved, history is researched, knowledge is published and ideas become the future.¦Мұра сақталатын, тарих зерттелетін, білім жарияланатын және идеялар болашаққа айналатын Қазақстанның цифрлық платформасы.
path.tarih¦История Казахстана¦History of Kazakhstan¦Қазақстан тарихы
path.person¦Человек¦Person¦Адам
path.idea¦Идея¦Idea¦Идея
path.research¦Исследование¦Research¦Зерттеу
path.invention¦Изобретение¦Invention¦Өнертабыс
path.future¦Будущее¦Future¦Болашақ
auth.login¦Войти¦Sign in¦Кіру
auth.logout¦Выйти из аккаунта¦Sign out¦Аккаунттан шығу
auth.register¦Зарегистрироваться¦Create account¦Тіркелу
auth.email¦Email¦Email¦Email
auth.password¦Пароль¦Password¦Құпиясөз
auth.passwordHint¦Минимум 8 символов, буквы и цифры.¦At least 8 characters, letters and digits.¦Кемінде 8 таңба, әріптер мен сандар.
auth.name¦Имя и фамилия¦Full name¦Аты-жөні
auth.birthYear¦Год рождения (необязательно)¦Year of birth (optional)¦Туған жылы (міндетті емес)
auth.section.account¦Аккаунт¦Account¦Аккаунт
auth.section.about¦О себе¦About you¦Өзіңіз туралы
auth.terms¦Я согласен(а) с правилами ATA MURA: публикую правдивые материалы и указываю источники¦I agree to the ATA MURA rules: I publish truthful materials and cite sources¦ATA MURA ережелерімен келісемін: шынайы материал жариялап, дереккөздерді көрсетемін
auth.forgot¦Забыли пароль?¦Forgot password?¦Құпиясөзді ұмыттыңыз ба?
auth.resetSent¦Письмо для восстановления отправлено на ваш email.¦A recovery email has been sent.¦Қалпына келтіру хаты email-ге жіберілді.
auth.error.email¦Проверьте адрес email.¦Check your email address.¦Email мекенжайын тексеріңіз.
auth.error.password¦Пароль: минимум 8 символов, буквы и цифры.¦Password: at least 8 characters, letters and digits.¦Құпиясөз: кемінде 8 таңба, әріптер мен сандар.
auth.error.taken¦Пользователь с таким email уже зарегистрирован.¦This email is already registered.¦Бұл email бұрын тіркелген.
auth.error.credentials¦Неверный email или пароль.¦Wrong email or password.¦Email немесе құпиясөз қате.
auth.error.blocked¦Аккаунт заблокирован. Обратитесь к администратору ATA MURA.¦This account is blocked. Contact the ATA MURA team.¦Аккаунт бұғатталған. ATA MURA әкімшісіне хабарласыңыз.
auth.error.name¦Укажите имя.¦Enter your name.¦Атыңызды енгізіңіз.
inclusive.title¦Комфортный режим (Inclusive Mode)¦Comfort mode (Inclusive Mode)¦Ыңғайлы режим (Inclusive Mode)
inclusive.footer¦Режим можно поменять в любой момент в профиле. ATA MURA — инклюзивная платформа для всех.¦You can change the mode at any time in your profile. ATA MURA is an inclusive platform for everyone.¦Режимді профильде кез келген уақытта ауыстыруға болады. ATA MURA — барлығына арналған инклюзивті платформа.
inclusive.standard¦Standard¦Standard¦Standard
inclusive.standard.hint¦Обычный интерфейс.¦Default interface.¦Әдеттегі интерфейс.
inclusive.asd¦ASD Friendly¦ASD Friendly¦ASD Friendly
inclusive.asd.hint¦Меньше визуального шума, без анимаций, спокойные цвета, предсказуемая навигация.¦Less visual noise, no animations, calm colours, predictable navigation.¦Көрнекі шу аз, анимациясыз, сабырлы түстер, болжамды навигация.
inclusive.dyslexia¦Dyslexia Friendly¦Dyslexia Friendly¦Dyslexia Friendly
inclusive.dyslexia.hint¦Адаптированный шрифт, увеличенные интервалы между строками и буквами.¦Adapted font, wider line and letter spacing.¦Бейімделген қаріп, жолдар мен әріптер арасы кеңірек.
inclusive.lowVision¦Low Vision¦Low Vision¦Low Vision
inclusive.lowVision.hint¦Крупный интерфейс, контраст и озвучивание текстов.¦Large interface, high contrast and text-to-speech.¦Ірі интерфейс, контраст және мәтінді дауыстап оқу.
inclusive.hearing¦Hearing Accessibility¦Hearing Accessibility¦Hearing Accessibility
inclusive.hearing.hint¦Субтитры и текстовая расшифровка видео и аудио всегда открыты.¦Subtitles and transcripts of video and audio are always shown.¦Бейне мен аудионың субтитрі және мәтіндік нұсқасы әрдайым ашық.
inclusive.easyLanguage¦Easy Language¦Easy Language¦Easy Language
inclusive.easyLanguage.hint¦AI объясняет сложные статьи простым языком — «как ребёнку 10 лет».¦AI explains complex articles in plain language — “like to a 10-year-old”.¦AI күрделі мақалаларды қарапайым тілмен түсіндіреді — «10 жасар балаға айтқандай».
role.member¦Участник¦Member¦Қатысушы
role.editor¦Редактор¦Editor¦Редактор
role.admin¦Администратор¦Administrator¦Әкімші
home.search¦Поиск по истории, людям, изобретениям…¦Search history, people, inventions…¦Тарих, адамдар, өнертабыстар бойынша іздеу…
home.hello¦Сәлем, %@! Исследуем Казахстан.¦Sälem, %@! Let's explore Kazakhstan.¦Сәлем, %@! Қазақстанды зерттейік.
home.today¦Сегодня в ATA MURA¦Today in ATA MURA¦Бүгін ATA MURA-да
home.tarih¦История Казахстана¦History of Kazakhstan¦Қазақстан тарихы
home.stories¦Истории людей¦People's stories¦Адамдар тарихы
home.invent¦Создать изобретение¦Create an invention¦Өнертабыс жасау
home.map¦Карта Казахстана¦Map of Kazakhstan¦Қазақстан картасы
home.research¦Статьи и исследования¦Articles and research¦Мақалалар мен зерттеулер
home.academy¦Курсы ATA MURA¦ATA MURA courses¦ATA MURA курстары
home.news¦Новости¦News¦Жаңалықтар
home.quest¦Задания и уровни¦Quests and levels¦Тапсырмалар мен деңгейлер
home.forgotten¦Продолжи идею прошлого¦Continue an idea of the past¦Өткеннің идеясын жалғастыр
home.people¦Изобретатели и учёные¦Inventors and scholars¦Өнертапқыштар мен ғалымдар
home.market¦Книги, наборы, билеты¦Books, kits, tickets¦Кітаптар, жинақтар, билеттер
feed.news¦Новости¦News¦Жаңалықтар
feed.magazine¦Новый выпуск журнала¦New magazine issue¦Журналдың жаңа саны
feed.course¦Курс¦Course¦Курс
feed.museum¦Музей¦Museum¦Музей
feed.empty¦Пока здесь тихо. Опубликуйте первую историю!¦It's quiet here. Publish the first story!¦Әзірге тыныш. Алғашқы әңгімені жариялаңыз!
search.empty¦Ничего не найдено.¦Nothing found.¦Ештеңе табылмады.
search.topics¦Темы истории¦History topics¦Тарих тақырыптары
search.places¦Места¦Places¦Орындар
create.history¦Написать историю¦Write a history piece¦Тарих жазу
create.story¦Рассказать историю человека¦Tell a person's story¦Адам тарихын айту
create.article¦Опубликовать статью¦Publish an article¦Мақала жариялау
create.theory¦Предложить теорию¦Propose a theory¦Теория ұсыну
create.archive¦Добавить архив¦Add an archive item¦Мұрағат қосу
create.invention¦Создать изобретение¦Create an invention¦Өнертабыс жасау
create.kids¦Работа «История глазами ребёнка»¦“History through a child's eyes” work¦«Бала көзімен тарих» жұмысы
create.museum¦Добавить экспонат в музей¦Add a museum item¦Музейге жәдігер қосу
create.person¦Добавить человека¦Add a person¦Адам қосу
create.place¦Добавить место¦Add a place¦Орын қосу
create.post¦Пост в ленту¦Feed post¦Таспаға жазба
create.news¦Написать новость¦Write news¦Жаңалық жазу
notifications.title¦Уведомления¦Notifications¦Хабарландырулар
notifications.empty¦Уведомлений пока нет.¦No notifications yet.¦Әзірге хабарландыру жоқ.
notify.welcome.title¦Добро пожаловать в ATA MURA!¦Welcome to ATA MURA!¦ATA MURA-ға қош келдіңіз!
notify.welcome.body¦Начните с квеста: найдите историю своего рода или опубликуйте первую историю.¦Start with a quest: find your family's story or publish your first story.¦Квесттен бастаңыз: әулетіңіздің тарихын тауып, алғашқы әңгімені жариялаңыз.
notify.quest.title¦Квест выполнен: +%@ баллов¦Quest completed: +%@ points¦Квест орындалды: +%@ ұпай
notify.level.title¦Новый уровень!¦New level!¦Жаңа деңгей!
notify.moderation.title¦Решение редакции¦Editorial decision¦Редакция шешімі
notify.invite.title¦Приглашение в проект¦Project invitation¦Жобаға шақыру
notify.invite.body¦%@ приглашает вас в проект «%@»¦%@ invites you to the project “%@”¦%@ сізді «%@» жобасына шақырады
notify.inviteAnswer.title¦Ответ на приглашение¦Invitation reply¦Шақыруға жауап
notify.projectOfWeek.title¦Ваш проект — Young Inventor of the Week!¦Your project is Young Inventor of the Week!¦Сіздің жобаңыз — Young Inventor of the Week!
notify.research.title¦Статья отправлена на рецензию¦Article submitted for review¦Мақала рецензияға жіберілді
notify.research.status¦Статус статьи изменён¦Article status changed¦Мақала мәртебесі өзгерді
notify.order.title¦Новый заказ¦New order¦Жаңа тапсырыс
notify.orderStatus.title¦Статус заказа¦Order status¦Тапсырыс мәртебесі
notify.supervisor.title¦Просьба стать научным руководителем¦Request to be a research supervisor¦Ғылыми жетекші болу өтініші
invite.title¦Приглашения в проекты¦Project invitations¦Жобаларға шақырулар
invite.accept¦Принять¦Accept¦Қабылдау
invite.decline¦Отклонить¦Decline¦Бас тарту
invite.accepted¦приглашение принято¦invitation accepted¦шақыру қабылданды
invite.declined¦приглашение отклонено¦invitation declined¦шақырудан бас тартылды
invite.project¦Проект¦Project¦Жоба
invite.message¦Сообщение¦Message¦Хабарлама
invite.send¦Отправить приглашение¦Send invitation¦Шақыру жіберу
moderation.pending¦На модерации¦Under review¦Модерацияда
moderation.approved¦Опубликовано¦Published¦Жарияланды
moderation.needsRevision¦На доработке¦Needs revision¦Пысықтауда
moderation.rejected¦Отклонено¦Rejected¦Қабылданбады
moderation.note¦Комментарий редакции¦Editor's note¦Редакция пікірі
moderation.noteHint¦Что исправить или уточнить автору¦What the author should fix or clarify¦Авторға не түзету немесе нақтылау керек
moderation.label¦Отметка достоверности¦Credibility label¦Сенімділік белгісі
moderation.approve¦Одобрить¦Approve¦Мақұлдау
moderation.revise¦На доработку¦Send for revision¦Пысықтауға
moderation.reject¦Отклонить¦Reject¦Қабылдамау
moderation.empty¦Очередь пуста — всё проверено.¦Queue is empty — all reviewed.¦Кезек бос — бәрі тексерілді.
moderation.other¦Проекты и музей¦Projects & museum¦Жобалар мен музей
moderation.reports¦Жалобы¦Reports¦Шағымдар
moderation.noReports¦Жалоб нет.¦No reports.¦Шағым жоқ.
moderation.open¦Открыть¦Open¦Ашу
moderation.hide¦Скрыть¦Hide¦Жасыру
moderation.dismiss¦Отклонить жалобу¦Dismiss¦Шағымды қабылдамау
moderation.sources¦источников: %@¦sources: %@¦дереккөз: %@
verification.none¦Без отметки¦No label¦Белгісіз
verification.verifiedFact¦Проверенный факт¦Verified fact¦Тексерілген дерек
verification.sourceConfirmed¦Источник подтверждён¦Source confirmed¦Дереккөз расталды
verification.authorOpinion¦Мнение автора¦Author's opinion¦Автордың пікірі
verification.hypothesis¦Гипотеза¦Hypothesis¦Гипотеза
evidence.fact¦Факт¦Fact¦Дерек
evidence.scientific¦Научная статья¦Scientific article¦Ғылыми мақала
evidence.archive¦Архивный материал¦Archival material¦Мұрағаттық материал
evidence.oralHistory¦Устная история¦Oral history¦Ауызша тарих
evidence.interpretation¦Авторская интерпретация¦Author's interpretation¦Авторлық түсіндірме
evidence.hypothesis¦Гипотеза / теория¦Hypothesis / theory¦Гипотеза / теория
posttype.history¦История / Тарих¦History / Tarih¦Тарих
posttype.person¦Личность¦Person¦Тұлға
posttype.place¦Место¦Place¦Орын
posttype.archive¦Архив¦Archive¦Мұрағат
posttype.culture¦Культура¦Culture¦Мәдениет
posttype.research¦Научная статья¦Research article¦Ғылыми мақала
posttype.hypothesis¦Гипотеза¦Hypothesis¦Гипотеза
posttype.invention¦Изобретение¦Invention¦Өнертабыс
posttype.inclusive¦Inclusive Kazakhstan¦Inclusive Kazakhstan¦Inclusive Kazakhstan
posttype.youngInventor¦Young Inventor¦Young Inventor¦Young Inventor
posttype.news¦Новости¦News¦Жаңалықтар
posttype.video¦Видео / Vlog¦Video / Vlog¦Бейне / Vlog
posttype.familyStory¦Семейная история¦Family story¦Отбасы тарихы
source.book¦Книга¦Book¦Кітап
source.document¦Документ¦Document¦Құжат
source.map¦Карта¦Map¦Карта
source.photo¦Фотография¦Photograph¦Фотосурет
source.link¦Ссылка¦Link¦Сілтеме
source.interview¦Интервью¦Interview¦Сұхбат
source.question¦Какие у вас источники?¦What are your sources?¦Дереккөздеріңіз қандай?
source.required¦Для этой категории нужен хотя бы один источник: книга, документ, карта, фото или ссылка.¦This category needs at least one source: a book, document, map, photo or link.¦Бұл санатқа кемінде бір дереккөз керек: кітап, құжат, карта, фото немесе сілтеме.
source.optional¦Источники необязательны, но повышают доверие к материалу.¦Sources are optional but increase trust.¦Дереккөздер міндетті емес, бірақ сенімді арттырады.
source.kind¦Тип источника¦Source type¦Дереккөз түрі
source.titleField¦Название (книга, архив, документ)¦Title (book, archive, document)¦Атауы (кітап, мұрағат, құжат)
source.detail¦Автор, год, архивный шифр или ссылка¦Author, year, archive code or link¦Авторы, жылы, мұрағат шифры немесе сілтеме
source.attach¦Фото документа или карты¦Photo of the document or map¦Құжаттың немесе картаның фотосы
source.add¦Добавить источник¦Add source¦Дереккөз қосу
tarih.topics¦Темы энциклопедии¦Encyclopedia topics¦Энциклопедия тақырыптары
tarih.empty¦Публикаций пока нет. Станьте первым автором!¦No publications yet. Be the first author!¦Әзірге жарияланым жоқ. Алғашқы автор болыңыз!
tarih.explain¦Объяснить как ребёнку 10 лет¦Explain like I'm 10¦10 жасар балаға түсіндір
tarih.simple¦Простым языком¦In plain language¦Қарапайым тілмен
tarih.transcript¦Текстовая расшифровка¦Transcript¦Мәтіндік нұсқа
tarih.sources¦Источники¦Sources¦Дереккөздер
tarih.noSources¦Автор не указал источники.¦The author did not cite sources.¦Автор дереккөздерді көрсетпеген.
tarih.linked¦Связано с историей¦Linked history¦Тарихпен байланысы
topic.posts¦Публикации по теме¦Publications on this topic¦Тақырып бойынша жарияланымдар
topic.empty¦По этой теме ещё нет публикаций.¦No publications on this topic yet.¦Бұл тақырыпта әлі жарияланым жоқ.
comments.title¦Комментарии¦Comments¦Пікірлер
comments.placeholder¦Ваш комментарий¦Your comment¦Пікіріңіз
report.title¦Пожаловаться¦Report¦Шағымдану
report.reason¦Причина¦Reason¦Себебі
report.reason.false¦Недостоверная информация¦False information¦Жалған ақпарат
report.reason.offensive¦Оскорбительный контент¦Offensive content¦Қорлайтын контент
report.reason.spam¦Спам или реклама¦Spam or advertising¦Спам немесе жарнама
report.reason.copyright¦Нарушение авторских прав¦Copyright violation¦Авторлық құқықты бұзу
report.other¦Другая причина¦Other reason¦Басқа себеп
report.block¦Заблокировать автора (не показывать его материалы)¦Block the author (hide their content)¦Авторды бұғаттау (материалдарын көрсетпеу)
report.send¦Отправить жалобу¦Send report¦Шағым жіберу
editor.new¦Новая публикация¦New publication¦Жаңа жарияланым
editor.type¦Тип публикации¦Publication type¦Жарияланым түрі
editor.evidence¦Категория достоверности¦Credibility category¦Сенімділік санаты
editor.hero¦Герой истории¦Story hero¦Әңгіме кейіпкері
editor.heroName¦Имя героя (например, «Мой дед»)¦Hero's name (e.g. “My grandfather”)¦Кейіпкердің аты (мысалы, «Атам»)
editor.heroYears¦Годы жизни¦Years of life¦Өмір сүрген жылдары
editor.content¦Материал¦Content¦Материал
editor.title¦Заголовок¦Title¦Тақырып
editor.body¦Текст¦Text¦Мәтін
editor.video¦Ссылка на видео (YouTube и др.)¦Video link (YouTube etc.)¦Бейнеге сілтеме (YouTube т.б.)
editor.transcript¦Расшифровка аудио/видео (для слабослышащих)¦Audio/video transcript (for hard of hearing)¦Аудио/бейне мәтіні (есту қабілеті нашарларға)
editor.linkHistory¦Связать с историей¦Link to history¦Тарихпен байланыстыру
editor.linkHistory.hint¦Публикация будет автоматически связана с этими темами энциклопедии.¦The publication will be automatically linked to these encyclopedia topics.¦Жарияланым осы энциклопедия тақырыптарымен автоматты түрде байланысады.
editor.publish¦Опубликовать¦Publish¦Жариялау
editor.moderationNote¦Материал появится в ленте после проверки редакцией ATA MURA.¦The material will appear after review by the ATA MURA editors.¦Материал ATA MURA редакциясы тексергеннен кейін шығады.
editor.staffNote¦Вы редактор: материал публикуется сразу.¦You are an editor: published immediately.¦Сіз редакторсыз: материал бірден жарияланады.
editor.published¦Опубликовано!¦Published!¦Жарияланды!
editor.sent¦Отправлено на модерацию. Мы сообщим о решении.¦Sent for review. We'll notify you of the decision.¦Модерацияға жіберілді. Шешімді хабарлаймыз.
stories.about¦Каждый человек может рассказать историю — не обязательно о знаменитости. Фото, документы, рассказ, аудио и видео. Лучшие истории войдут в книгу.¦Anyone can tell a story — not only about famous people. Photos, documents, narrative, audio and video. The best stories will form the book.¦Кез келген адам тарих айта алады — міндетті түрде атақты адам туралы емес. Фото, құжат, әңгіме, аудио және бейне. Үздік әңгімелер кітапқа енеді.
stories.book¦В книге: %@ из 100¦In the book: %@ of 100¦Кітапта: %@ / 100
stories.onlyBook¦Только отобранные в книгу¦Only selected for the book¦Тек кітапқа іріктелгендер
stories.empty¦Историй пока нет. Расскажите первую — например, «Мой дед строил Турксиб».¦No stories yet. Tell the first one — e.g. “My grandfather built the Turksib”.¦Әзірге әңгіме жоқ. Алғашқысын айтыңыз — мысалы, «Атам Түрксібті салған».
stories.inBook¦В книге¦In the book¦Кітапта
region.astana¦Астана¦Astana¦Астана
region.almaty¦Алматы¦Almaty¦Алматы
region.shymkent¦Шымкент¦Shymkent¦Шымкент
region.abai¦Абайская область¦Abai Region¦Абай облысы
region.akmola¦Акмолинская область¦Akmola Region¦Ақмола облысы
region.aktobe¦Актюбинская область¦Aktobe Region¦Ақтөбе облысы
region.almatyRegion¦Алматинская область¦Almaty Region¦Алматы облысы
region.atyrau¦Атырауская область¦Atyrau Region¦Атырау облысы
region.eastKazakhstan¦Восточно-Казахстанская область¦East Kazakhstan Region¦Шығыс Қазақстан облысы
region.jambyl¦Жамбылская область¦Jambyl Region¦Жамбыл облысы
region.jetisu¦Жетысуская область¦Jetisu Region¦Жетісу облысы
region.westKazakhstan¦Западно-Казахстанская область¦West Kazakhstan Region¦Батыс Қазақстан облысы
region.karaganda¦Карагандинская область¦Karaganda Region¦Қарағанды облысы
region.kostanay¦Костанайская область¦Kostanay Region¦Қостанай облысы
region.kyzylorda¦Кызылординская область¦Kyzylorda Region¦Қызылорда облысы
region.mangystau¦Мангистауская область¦Mangystau Region¦Маңғыстау облысы
region.pavlodar¦Павлодарская область¦Pavlodar Region¦Павлодар облысы
region.northKazakhstan¦Северо-Казахстанская область¦North Kazakhstan Region¦Солтүстік Қазақстан облысы
region.turkistan¦Туркестанская область¦Turkistan Region¦Түркістан облысы
region.ulytau¦Улытауская область¦Ulytau Region¦Ұлытау облысы
placekind.person¦Исторические личности¦Historical figures¦Тарихи тұлғалар
placekind.monument¦Памятники¦Monuments¦Ескерткіштер
placekind.mine¦Шахты и рудники¦Mines¦Шахталар мен кеніштер
placekind.settlement¦Древние поселения¦Ancient settlements¦Ежелгі қоныстар
placekind.legend¦Легенды¦Legends¦Аңыздар
placekind.photo¦Фотографии¦Photographs¦Фотосуреттер
placekind.research¦Научные исследования¦Research¦Ғылыми зерттеулер
placekind.schoolProject¦Проекты школьников¦School projects¦Оқушылар жобалары
placekind.enterprise¦Предприятия¦Enterprises¦Кәсіпорындар
placekind.invention¦Изобретения региона¦Inventions of the region¦Өңір өнертабыстары
map.regionEmpty¦В этом регионе пока пусто. Добавьте первое место или историю!¦Nothing here yet. Add the first place or story!¦Бұл өңірде әзірге ештеңе жоқ. Алғашқы орынды немесе әңгімені қосыңыз!
map.writeAbout¦Написать историю о месте¦Write a story about a place¦Орын туралы әңгіме жазу
map.openInMaps¦Открыть в Картах¦Open in Maps¦Карталарда ашу
place.kind¦Категория¦Category¦Санат
place.period¦Период / годы¦Period / years¦Кезең / жылдар
place.summary¦Описание¦Description¦Сипаттама
place.coordinates¦Координаты¦Coordinates¦Координаттар
place.coordinatesHint¦По умолчанию — центр региона. Точные координаты можно скопировать из Карт.¦Defaults to the regional centre. Copy exact coordinates from Maps.¦Әдепкі бойынша — өңір орталығы. Нақты координатты Карталардан көшіруге болады.
place.lat¦Широта¦Latitude¦Ендік
place.lon¦Долгота¦Longitude¦Бойлық
stage.problem¦Проблема¦Problem¦Мәселе
stage.idea¦Идея¦Idea¦Идея
stage.sketch¦Эскиз¦Sketch¦Эскиз
stage.calculation¦Расчёт¦Calculation¦Есептеу
stage.prototype¦Прототип¦Prototype¦Прототип
stage.testing¦Испытание¦Testing¦Сынақ
stage.result¦Результат¦Result¦Нәтиже
stage.problem.question¦Какую проблему вы решаете? Для кого?¦What problem are you solving? For whom?¦Қандай мәселені шешесіз? Кім үшін?
stage.idea.question¦В чём ваша идея? Как она решает проблему?¦What is your idea? How does it solve the problem?¦Идеяңыз неде? Ол мәселені қалай шешеді?
stage.sketch.question¦Опишите эскиз и приложите фото рисунка.¦Describe the sketch and attach a photo of the drawing.¦Эскизді сипаттап, сызбаның фотосын тіркеңіз.
stage.calculation.question¦Какие размеры, детали, бюджет, формулы?¦What sizes, parts, budget, formulas?¦Қандай өлшемдер, бөлшектер, бюджет, формулалар?
stage.prototype.question¦Что вы собрали? Из каких материалов?¦What did you build? From what materials?¦Не құрастырдыңыз? Қандай материалдан?
stage.testing.question¦Как проверяли? Кто тестировал? Что не получилось?¦How did you test it? Who tested it? What failed?¦Қалай тексердіңіз? Кім сынады? Не шықпады?
stage.result.question¦Чего удалось добиться? Что дальше?¦What did you achieve? What's next?¦Неге қол жеткіздіңіз? Әрі қарай не?
direction.inclusiveEngineering¦Inclusive Engineering¦Inclusive Engineering¦Inclusive Engineering
direction.heritageTech¦Наследие и технологии¦Heritage tech¦Мұра және технология
direction.ecology¦Экология¦Ecology¦Экология
direction.energy¦Энергетика¦Energy¦Энергетика
direction.robotics¦Робототехника¦Robotics¦Робототехника
direction.agro¦Агротехнологии¦Agritech¦Агротехнология
direction.transport¦Транспорт и железные дороги¦Transport & railways¦Көлік және темір жол
direction.mining¦Горное дело¦Mining¦Тау-кен ісі
direction.education¦Образование¦Education¦Білім беру
direction.medicine¦Медицина¦Medicine¦Медицина
direction.art¦Искусство и культура¦Art & culture¦Өнер және мәдениет
direction.other¦Другое¦Other¦Басқа
inventors.haveIdea¦У меня есть идея¦I have an idea¦Менде идея бар
inventors.steps¦Проблема → идея → эскиз → расчёт → прототип → испытание → результат¦Problem → idea → sketch → calculation → prototype → testing → result¦Мәселе → идея → эскиз → есептеу → прототип → сынақ → нәтиже
inventors.lookingTeam¦Только ищущие команду¦Only looking for a team¦Тек команда іздейтіндер
inventors.empty¦Проектов пока нет — создайте первый!¦No projects yet — create the first one!¦Әзірге жоба жоқ — алғашқысын жасаңыз!
project.title¦Название проекта¦Project title¦Жоба атауы
project.author¦Автор¦Author¦Автор
project.age¦%@ лет¦age %@¦%@ жаста
project.direction¦Направление¦Field¦Бағыт
project.stage¦Стадия¦Stage¦Кезең
project.help¦Нужна помощь¦Help needed¦Көмек керек
project.helpHint¦Нужна помощь (через запятую): Arduino, 3D-печать…¦Help needed (comma-separated): Arduino, 3D printing…¦Көмек керек (үтір арқылы): Arduino, 3D басып шығару…
project.team¦Команда¦Team¦Команда
project.lookingTeam¦Ищем команду¦Looking for a team¦Команда іздейміз
project.teamNeeds¦Кого ищем (например, инженера)¦Who we need (e.g. an engineer)¦Кімді іздейміз (мысалы, инженер)
project.join¦Хочу в команду¦Join the team¦Командаға қосылғым келеді
project.makeWeek¦Сделать проектом недели¦Make project of the week¦Апта жобасы ету
project.create¦Создать проект ATA MURA¦Create ATA MURA project¦ATA MURA жобасын жасау
project.saved¦Сохранено!¦Saved!¦Сақталды!
forgotten.about¦Идеи, которые когда-то придумали, но не реализовали. Нажмите «Продолжить эту идею» и сделайте современную версию. Мы не только сохраняем прошлое — мы превращаем его идеи в технологии будущего.¦Ideas that were once conceived but never realised. Tap “Continue this idea” and build a modern version. We don't just preserve the past — we turn its ideas into future technology.¦Бір кезде ойлап табылған, бірақ іске аспаған идеялар. «Осы идеяны жалғастыру» түймесін басып, заманауи нұсқасын жасаңыз. Біз өткенді сақтап қана қоймай, оның идеяларын болашақ технологиясына айналдырамыз.
forgotten.why¦Почему не реализовали¦Why it wasn't realised¦Неге іске аспады
forgotten.continue¦Продолжить эту идею¦Continue this idea¦Осы идеяны жалғастыру
forgotten.continued¦Продолжений: %@¦Continuations: %@¦Жалғасы: %@
forgotten.continues¦Продолжение забытой идеи¦Continues a forgotten idea¦Ұмытылған идеяның жалғасы
forgotten.modernTitle¦%@ — современная версия¦%@ — modern version¦%@ — заманауи нұсқа
ai.intro¦Опишите идею или проблему — я помогу превратить её в проект: проблема, возможное решение, что изучить и первый прототип.¦Describe an idea or a problem — I'll help turn it into a project: problem, possible solution, what to learn and the first prototype.¦Идеяны немесе мәселені сипаттаңыз — оны жобаға айналдыруға көмектесемін: мәселе, шешім жолы, не үйрену керек және алғашқы прототип.
ai.localMode¦Работает локальный AI-режим. Для полного AI добавьте ключ Claude API в настройках.¦Local AI mode. Add a Claude API key in settings for full AI.¦Жергілікті AI режимі. Толық AI үшін баптауларда Claude API кілтін қосыңыз.
ai.connected¦AI подключён (Claude).¦AI connected (Claude).¦AI қосылған (Claude).
ai.placeholder¦Например: хочу сделать устройство…¦E.g. I want to build a device…¦Мысалы: құрылғы жасағым келеді…
ai.thinking¦AI думает…¦AI is thinking…¦AI ойлануда…
ai.new¦Новый диалог¦New chat¦Жаңа диалог
ai.createProject¦Создать проект ATA MURA¦Create ATA MURA project¦ATA MURA жобасын жасау
ai.example.1¦Я хочу сделать устройство, чтобы слабослышащий ребёнок чувствовал музыку.¦I want to build a device so a hard-of-hearing child can feel music.¦Есту қабілеті нашар бала музыканы сезінуі үшін құрылғы жасағым келеді.
ai.example.2¦Как помочь незрячему человеку безопасно ходить по улице?¦How can I help a blind person walk safely on the street?¦Көзі көрмейтін адамға көшеде қауіпсіз жүруге қалай көмектесуге болады?
ai.example.3¦Хочу сделать умную домбру, которая учит играть.¦I want to make a smart dombra that teaches you to play.¦Ойнауды үйрететін ақылды домбыра жасағым келеді.
ai.field.problem¦Проблема¦Problem¦Мәселе
ai.field.solution¦Возможное решение¦Possible solution¦Мүмкін шешім
ai.field.learn¦Что изучить¦What to learn¦Не үйрену керек
ai.field.prototype¦Первый прототип¦First prototype¦Алғашқы прототип
ai.endpoint¦Адрес AI-шлюза (прокси)¦AI gateway URL (proxy)¦AI шлюзінің мекенжайы (прокси)
ai.footer¦Ключ хранится в Keychain на устройстве. Для публикации в App Store используйте свой серверный прокси, чтобы не хранить ключ в приложении.¦The key is stored in the device Keychain. For App Store release use your own server proxy so the key isn't stored in the app.¦Кілт құрылғының Keychain-інде сақталады. App Store үшін кілтті қосымшада сақтамау үшін өз серверлік проксиіңізді қолданыңыз.
ai.error.notConfigured¦AI не настроен.¦AI is not configured.¦AI бапталмаған.
ai.error.http¦Ошибка AI (%@): %@¦AI error (%@): %@¦AI қатесі (%@): %@
ai.error.refusal¦AI не может ответить на этот запрос. Переформулируйте вопрос.¦AI can't answer this request. Please rephrase.¦AI бұл сұраққа жауап бере алмайды. Сұрақты басқаша қойыңыз.
ai.error.empty¦AI вернул пустой ответ.¦AI returned an empty response.¦AI бос жауап қайтарды.
localai.hearing.problem¦Слабослышащий ребёнок не воспринимает музыку на слух.¦A hard-of-hearing child can't perceive music by ear.¦Есту қабілеті нашар бала музыканы құлақпен қабылдай алмайды.
localai.hearing.solution¦Вибротактильная система: звук раскладывается по частотам, и каждая частота превращается в вибрацию на браслете или жилете.¦A vibrotactile system: sound is split into frequencies and each becomes a vibration on a wristband or vest.¦Вибротактильді жүйе: дыбыс жиіліктерге бөлініп, әр жиілік білезіктегі немесе жилеттегі дірілге айналады.
localai.hearing.prototype¦ESP32 + микрофон + 3 вибромотора (низкие, средние, высокие частоты) на браслете. Проверьте на любимой песне.¦ESP32 + microphone + 3 vibration motors (low, mid, high frequencies) on a wristband. Test it on a favourite song.¦ESP32 + микрофон + білезіктегі 3 діріл қозғалтқышы (төмен, орта, жоғары жиілік). Сүйікті әнмен тексеріңіз.
localai.vision.problem¦Незрячему человеку трудно замечать препятствия на уровне груди и головы.¦A blind person struggles to notice obstacles at chest and head level.¦Көзі көрмейтін адамға кеуде мен бас деңгейіндегі кедергілерді байқау қиын.
localai.vision.solution¦Носимый датчик расстояния, который предупреждает вибрацией: чем ближе препятствие, тем чаще вибрация.¦A wearable distance sensor that warns with vibration: the closer the obstacle, the faster it vibrates.¦Қашықтықты өлшейтін киілетін датчик дірілмен ескертеді: кедергі жақын болған сайын діріл жиілейді.
localai.vision.prototype¦Arduino Nano + HC-SR04 + вибромотор на кепке или поясе. Тестируйте в помещении с помощником.¦Arduino Nano + HC-SR04 + a vibration motor on a cap or belt. Test indoors with a helper.¦Arduino Nano + HC-SR04 + кепкадағы немесе белдіктегі діріл қозғалтқышы. Көмекшімен бөлмеде сынаңыз.
localai.mobility.problem¦Человеку на коляске трудно преодолевать пороги и открывать двери.¦A wheelchair user struggles with thresholds and doors.¦Арбадағы адамға табалдырық пен есіктен өту қиын.
localai.mobility.solution¦Складной лёгкий пандус или автоматический привод двери с кнопкой на подлокотнике.¦A light folding ramp or an automatic door opener with a button on the armrest.¦Жеңіл бүктелетін пандус немесе шынтақ сүйенішіндегі түймемен ашылатын автоматты есік.
localai.mobility.prototype¦Модель пандуса из фанеры в масштабе 1:5 и расчёт угла наклона (не круче 1:12).¦A 1:5 plywood ramp model and slope calculation (no steeper than 1:12).¦Фанерадан 1:5 масштабтағы пандус моделі және еңіс бұрышын есептеу (1:12-ден тік емес).
localai.dombra.problem¦Учиться играть на домбре сложно без педагога рядом.¦Learning the dombra is hard without a teacher nearby.¦Қасыңызда ұстаз болмаса, домбыра үйрену қиын.
localai.dombra.solution¦Умная домбра: датчики на ладах подсвечивают, куда ставить пальцы, а приложение проверяет мелодию.¦A smart dombra: sensors on the frets light up where to place fingers, and an app checks the melody.¦Ақылды домбыра: перне датчиктері саусақты қайда қою керегін жарықпен көрсетеді, ал қосымша әуенді тексереді.
localai.dombra.prototype¦Лента WS2812 вдоль грифа + ESP32, которая по очереди подсвечивает лады для простой мелодии «Елім-ай».¦A WS2812 strip along the neck + ESP32 lighting the frets in turn for a simple melody.¦Мойын бойындағы WS2812 таспасы + ESP32 қарапайым әуен үшін перделерді кезекпен жарықтандырады.
localai.water.problem¦Растения и сады страдают от нехватки воды и перелива.¦Plants suffer from both lack of water and overwatering.¦Өсімдіктер су тапшылығынан да, артық судан да зардап шегеді.
localai.water.solution¦Автополив по датчику влажности почвы с питанием от солнечной панели.¦Automatic watering driven by a soil moisture sensor, powered by a solar panel.¦Күн панелімен қоректенетін, топырақ ылғалдылығы датчигі бойынша автоматты суару.
localai.water.prototype¦Arduino + датчик влажности + реле + насос 5 В для одного горшка; замерьте расход воды за неделю.¦Arduino + moisture sensor + relay + 5 V pump for one pot; measure water use over a week.¦Бір құмыраға Arduino + ылғал датчигі + реле + 5 В сорғы; бір аптадағы су шығынын өлшеңіз.
localai.energy.problem¦В отдалённых аулах и на пастбищах нет стабильного электричества.¦Remote villages and pastures lack stable electricity.¦Шалғай ауылдар мен жайылымдарда тұрақты электр жоқ.
localai.energy.solution¦Мобильная солнечная или ветровая станция для юрты: свет, зарядка телефона, связь.¦A mobile solar or wind station for a yurt: light, phone charging, connectivity.¦Киіз үйге арналған жылжымалы күн немесе жел станциясы: жарық, телефон зарядтау, байланыс.
localai.energy.prototype¦Солнечная панель 10 Вт + контроллер + аккумулятор + USB; измерьте, сколько часов работает светильник.¦10 W solar panel + controller + battery + USB; measure how many hours a lamp runs.¦10 Вт күн панелі + контроллер + аккумулятор + USB; шам неше сағат жанатынын өлшеңіз.
localai.generic¦Отличная идея! Давайте разберём её по шагам ATA MURA: 1) опишите проблему и для кого она важна; 2) придумайте 2–3 варианта решения; 3) выберите самый простой и нарисуйте эскиз; 4) соберите первый прототип из доступных материалов. Нажмите «Создать проект ATA MURA», чтобы начать карточку.¦Great idea! Let's go through the ATA MURA steps: 1) describe the problem and who it matters to; 2) come up with 2–3 solutions; 3) pick the simplest and sketch it; 4) build a first prototype from available materials. Tap “Create ATA MURA project” to start a card.¦Керемет идея! ATA MURA қадамдарымен талдайық: 1) мәселені және ол кім үшін маңызды екенін сипаттаңыз; 2) 2–3 шешім ойлап табыңыз; 3) ең қарапайымын таңдап, эскиз салыңыз; 4) қолдағы материалдан алғашқы прототип жасаңыз. Карточканы бастау үшін «ATA MURA жобасын жасау» түймесін басыңыз.
localai.generic.solution¦Сформулируйте 2–3 варианта решения и выберите самый простой для проверки.¦Formulate 2–3 solutions and choose the simplest to test.¦2–3 шешім нұсқасын тұжырымдап, тексеруге ең қарапайымын таңдаңыз.
localai.generic.prototype¦Простая модель из картона, LEGO или Arduino, чтобы проверить главную идею.¦A simple model made of cardboard, LEGO or Arduino to test the main idea.¦Негізгі идеяны тексеру үшін картоннан, LEGO-дан немесе Arduino-дан жасалған қарапайым модель.
localai.next¦Следующий шаг: нажмите «Создать проект ATA MURA» — карточка проекта заполнится автоматически.¦Next step: tap “Create ATA MURA project” — the project card will be filled in automatically.¦Келесі қадам: «ATA MURA жобасын жасау» түймесін басыңыз — жоба карточкасы автоматты түрде толтырылады.
localai.simple.header¦Простыми словами (главное из текста):¦In simple words (key points):¦Қарапайым тілмен (мәтіннің негізгісі):
localai.idea.titles¦10 вариантов названия:¦10 title options:¦Атаудың 10 нұсқасы:
localai.idea.structure¦Структура ролика:¦Video structure:¦Бейне құрылымы:
localai.idea.s1¦Хук (0–5 сек): удивительный факт или вопрос.¦Hook (0–5 s): a surprising fact or question.¦Хук (0–5 сек): таңғаларлық дерек немесе сұрақ.
localai.idea.s2¦Контекст: где и когда это происходило, карта.¦Context: where and when it happened, a map.¦Контекст: қайда және қашан болды, карта.
localai.idea.s3¦Герой: человек, его история, архивные фото.¦Hero: the person, their story, archive photos.¦Кейіпкер: адам, оның тарихы, мұрағат фотолары.
localai.idea.s4¦Связь с сегодняшним днём: что изобрели бы сейчас.¦Link to today: what we'd invent now.¦Бүгінгі күнмен байланыс: қазір не ойлап табар едік.
localai.idea.s5¦Финал: вывод и призыв опубликовать свою историю в ATA MURA.¦Ending: takeaway and a call to publish your story on ATA MURA.¦Соңы: қорытынды және ATA MURA-да өз әңгімеңізді жариялауға шақыру.
localai.idea.questions¦Вопросы для интервью:¦Interview questions:¦Сұхбатқа сұрақтар:
localai.idea.q¦1. Как вы впервые узнали об этой истории?\n2. Кто был главным героем?\n3. Какие документы или фото сохранились?\n4. Что было самым трудным?\n5. Что люди забыли об этом?\n6. Чему это учит молодёжь?\n7. Какую идею отсюда стоит продолжить?\n8. Что бы вы сказали детям, которые это смотрят?¦1. How did you first learn about this story?\n2. Who was the main hero?\n3. What documents or photos survive?\n4. What was the hardest part?\n5. What have people forgotten about it?\n6. What does it teach young people?\n7. Which idea is worth continuing?\n8. What would you tell the children watching?¦1. Бұл тарихты алғаш қалай білдіңіз?\n2. Басты кейіпкер кім болды?\n3. Қандай құжаттар мен фотолар сақталды?\n4. Ең қиыны не болды?\n5. Адамдар бұл туралы нені ұмытты?\n6. Бұл жастарды неге үйретеді?\n7. Қай идеяны жалғастырған жөн?\n8. Көріп отырған балаларға не айтар едіңіз?
localai.idea.shorts¦Shorts из длинного видео:¦Shorts from the long video:¦Ұзын бейнеден Shorts:
localai.idea.shortsList¦• «1 факт за 30 секунд» — самый удивительный момент.\n• Цитата героя крупным планом с субтитрами.\n• «Было — стало»: архивное фото и то же место сегодня.¦• “1 fact in 30 seconds” — the most surprising moment.\n• A close-up hero quote with subtitles.\n• “Then and now”: an archive photo and the same place today.¦• «30 секундта 1 дерек» — ең таңғаларлық сәт.\n• Кейіпкердің субтитрлі ірі пландағы дәйексөзі.\n• «Бұрын — қазір»: мұрағат фотосы және сол орын бүгін.
localai.vlog.title¦План выпуска «Неделя ATA MURA»¦Episode plan “ATA MURA Week”¦«ATA MURA аптасы» шығарылым жоспары
localai.vlog.hook¦Хук¦Hook¦Хук
localai.vlog.final¦Финал: планы на следующую неделю и призыв подписаться.¦Ending: plans for next week and a call to subscribe.¦Соңы: келесі аптаның жоспары және жазылуға шақыру.
vlog.empty¦Добавьте записи в дневник, чтобы собрать выпуск.¦Add diary entries to build an episode.¦Шығарылым құру үшін күнделікке жазба қосыңыз.
vlog.today¦Запись дня¦Today's entry¦Күн жазбасы
vlog.date¦Дата¦Date¦Күні
vlog.happened¦Что произошло¦What happened¦Не болды
vlog.meetings¦Встречи¦Meetings¦Кездесулер
vlog.filmed¦Что снимали¦What was filmed¦Не түсірілді
vlog.quote¦Интересная цитата¦Quote of the day¦Қызық дәйексөз
vlog.forAudience¦Что показать аудитории¦What to show the audience¦Аудиторияға не көрсету
vlog.makePlan¦AI: собрать план выпуска недели¦AI: build this week's episode plan¦AI: апталық шығарылым жоспарын құру
vlog.weekPlan¦Выпуск недели¦Episode of the week¦Апта шығарылымы
vlog.toCalendar¦Добавить в контент-календарь¦Add to content calendar¦Контент-күнтізбеге қосу
vlog.history¦Дневник¦Diary¦Күнделік
academy.buy¦Купить курс¦Buy course¦Курсты сатып алу
academy.certificate¦Сертификат по окончании¦Certificate on completion¦Аяқтағаннан кейін сертификат
academy.certificateReady¦Курс пройден! Сертификат будет выдан командой ATA MURA.¦Course completed! The ATA MURA team will issue your certificate.¦Курс аяқталды! Сертификатты ATA MURA командасы береді.
academy.completed¦Урок пройден¦Lesson completed¦Сабақ өтілді
academy.course¦Курс¦Course¦Курс
academy.empty¦Курсы скоро появятся.¦Courses coming soon.¦Курстар жақында шығады.
academy.enrolled¦Вы записаны¦Enrolled¦Жазылдыңыз
academy.homework¦Домашнее задание¦Homework¦Үй тапсырмасы
academy.join¦Записаться¦Enrol¦Жазылу
academy.lessons¦Уроков: %@¦Lessons: %@¦Сабақтар: %@
academy.markDone¦Отметить пройденным¦Mark as done¦Өтілді деп белгілеу
academy.mineEmpty¦Вы пока не записаны ни на один курс.¦You haven't enrolled in any course yet.¦Сіз әзірге ешбір курсқа жазылмадыңыз.
academy.orderCreated¦Заказ на %@ создан. Оплатите по реквизитам ATA MURA — доступ откроется после подтверждения оплаты.¦Order for %@ created. Pay using the ATA MURA details — access opens once payment is confirmed.¦%@ сомасына тапсырыс жасалды. ATA MURA деректемелері бойынша төлеңіз — төлем расталған соң қолжетімділік ашылады.
academy.pending¦Ожидает оплаты: %@¦Awaiting payment: %@¦Төлем күтілуде: %@
academy.pendingHint¦Как только администратор подтвердит оплату, курс появится в My Courses.¦Once the administrator confirms payment, the course will appear in My Courses.¦Әкімші төлемді растаған соң курс My Courses бөлімінде пайда болады.
academy.program¦Программа курса¦Course programme¦Курс бағдарламасы
academy.progress¦Пройдено %@ из %@¦Completed %@ of %@¦%@/%@ өтілді
academy.promo¦Промокод¦Promo code¦Промокод
academy.quiz¦Тест¦Quiz¦Тест
academy.salesStart¦Продажи с %@¦On sale from %@¦Сату %@ бастап
academy.seats¦Осталось мест: %@¦Seats left: %@¦Қалған орын: %@
academy.startFree¦Начать бесплатно¦Start for free¦Тегін бастау
academy.total¦Итого: %@¦Total: %@¦Барлығы: %@
admin.title¦Админ-панель ATA MURA¦ATA MURA admin¦ATA MURA әкімші панелі
admin.noAccess¦Раздел доступен только команде ATA MURA.¦Only the ATA MURA team can access this section.¦Бұл бөлім тек ATA MURA командасына қолжетімді.
admin.group.studio¦ATA MURA Creator Studio¦ATA MURA Creator Studio¦ATA MURA Creator Studio
admin.group.publishing¦Публикации и редакция¦Publishing & editorial¦Жарияланымдар және редакция
admin.group.platform¦Платформа¦Platform¦Платформа
admin.dashboard¦Morning Dashboard¦Morning Dashboard¦Morning Dashboard
admin.calendar¦Контент-календарь¦Content Calendar¦Контент-күнтізбе
admin.vlog¦Vlog Diary¦Vlog Diary¦Vlog Diary
admin.ideas¦Банк идей¦Idea Bank¦Идеялар банкі
admin.series¦Рубрики (Series)¦Series¦Айдарлар (Series)
admin.guests¦Герои и гости¦People & Guests¦Кейіпкерлер мен қонақтар
admin.news¦Новости¦News¦Жаңалықтар
admin.magazine¦Журнал¦Magazine¦Журнал
admin.courses¦Курсы¦Courses¦Курстар
admin.orders¦Заказы и оплаты¦Orders & payments¦Тапсырыстар мен төлемдер
admin.moderation¦Модерация¦Moderation¦Модерация
admin.posts¦Публикации¦Posts¦Жарияланымдар
admin.projects¦Проекты и изобретатели¦Projects & inventors¦Жобалар мен өнертапқыштар
admin.museum¦Цифровой музей¦Digital Museum¦Цифрлық музей
admin.research¦Исследования¦Research¦Зерттеулер
admin.users¦Пользователи¦Users¦Пайдаланушылар
admin.events¦Мероприятия¦Events¦Іс-шаралар
admin.partners¦Партнёры и спонсоры¦Partners & sponsors¦Серіктестер мен демеушілер
admin.marketplace¦Marketplace¦Marketplace¦Marketplace
admin.media¦Медиатека¦Media Library¦Медиатека
admin.analytics¦Аналитика¦Analytics¦Аналитика
admin.tasks¦Задачи¦Tasks¦Тапсырмалар
admin.map¦Карта и энциклопедия¦Map & encyclopedia¦Карта және энциклопедия
admin.stat.users¦Участники¦Members¦Қатысушылар
admin.stat.posts¦Публикации¦Posts¦Жарияланымдар
admin.stat.projects¦Проекты¦Projects¦Жобалар
admin.bookCount¦Отобрано в книгу «100 Stories»: %@¦Selected for the “100 Stories” book: %@¦«100 Stories» кітабына іріктелді: %@
admin.toBook¦В книгу¦To the book¦Кітапқа
morning.greeting¦Доброе утро, %@!¦Good morning, %@!¦Қайырлы таң, %@!
morning.clear¦Срочных дел нет — хороший день для новой идеи.¦Nothing urgent — a good day for a new idea.¦Шұғыл іс жоқ — жаңа идеяға жақсы күн.
morning.shoot¦Съёмка сегодня: %@¦Shooting today: %@¦Бүгін түсірілім: %@
morning.publish¦Публикация: %@¦Publishing: %@¦Жариялау: %@
morning.script¦Дописать сценарий: %@¦Finish the script: %@¦Сценарийді аяқтау: %@
morning.guest¦Подтвердить интервью: %@¦Confirm interview: %@¦Сұхбатты растау: %@
morning.moderation¦Проверить новые публикации: %@¦Review new publications: %@¦Жаңа жарияланымдарды тексеру: %@
morning.orders¦Подтвердить оплаты: %@¦Confirm payments: %@¦Төлемдерді растау: %@
morning.projectOfWeek¦Выбрать проект недели¦Choose the project of the week¦Апта жобасын таңдау
morning.research¦Статьи на рецензию: %@¦Articles to review: %@¦Рецензияға мақалалар: %@
morning.news¦Сегодня выходит новость: %@¦News going out today: %@¦Бүгін жаңалық шығады: %@
analytics.insight.compare¦«%@» набирает в %@ раза больше просмотров, чем «%@» — стоит снять ещё 3 выпуска этой рубрики.¦“%@” gets %@× more views than “%@” — worth filming 3 more episodes of this series.¦«%@» айдарын %@ есе көбірек көреді («%@» айдарымен салыстырғанда) — тағы 3 шығарылым түсірген жөн.
analytics.insight.single¦Лучше всего смотрят рубрику «%@» — продолжайте её.¦The “%@” series performs best — keep it going.¦«%@» айдарын ең көп көреді — жалғастырыңыз.
analytics.media¦Ролики¦Videos¦Бейнелер
analytics.videos¦Выпусков¦Episodes¦Шығарылым
analytics.views¦Просмотры¦Views¦Қаралым
analytics.subscribers¦Новые подписчики¦New subscribers¦Жаңа жазылушылар
analytics.bySeries¦Средние просмотры по рубрикам¦Average views by series¦Айдарлар бойынша орташа қаралым
analytics.noData¦Добавьте результаты опубликованных роликов в контент-календаре.¦Add results of published videos in the content calendar.¦Жарияланған бейнелердің нәтижесін контент-күнтізбеге енгізіңіз.
analytics.platform¦Платформа¦Platform¦Платформа
analytics.revenue¦Выручка¦Revenue¦Түсім
cloud.title¦Сервер ATA MURA (Supabase)¦ATA MURA server (Supabase)¦ATA MURA сервері (Supabase)
cloud.enable¦Подключить сервер¦Connect server¦Серверді қосу
cloud.footer¦Без сервера данные хранятся только на этом устройстве. Сначала выполните ATAMURA/backend/schema.sql в Supabase, затем включите сервер и войдите заново.¦Without a server, data stays on this device only. First run ATAMURA/backend/schema.sql in Supabase, then enable the server and sign in again.¦Серверсіз деректер тек осы құрылғыда сақталады. Алдымен Supabase-те ATAMURA/backend/schema.sql орындаңыз, содан кейін серверді қосып, қайта кіріңіз.
cloud.signInHint¦Выйдите и войдите заново, чтобы аккаунт создался на сервере.¦Sign out and sign in again to create your account on the server.¦Аккаунт серверде құрылуы үшін шығып, қайта кіріңіз.
cloud.syncNow¦Синхронизировать сейчас¦Sync now¦Қазір синхрондау
cloud.uploadStarter¦Загрузить стартовые темы, места и курсы на сервер¦Upload starter topics, places and courses to the server¦Бастапқы тақырыптарды, орындарды және курстарды серверге жүктеу
cloud.status.local¦Локальный режим (сервер не подключён)¦Local mode (no server)¦Жергілікті режим (сервер қосылмаған)
cloud.status.signedOut¦Сервер подключён, вход не выполнен¦Server connected, not signed in¦Сервер қосылған, кіру орындалмаған
cloud.status.syncing¦Синхронизация…¦Syncing…¦Синхрондау…
cloud.status.synced¦Синхронизировано %@¦Synced %@¦Синхрондалды %@
cloud.status.failed¦Ошибка синхронизации: %@¦Sync error: %@¦Синхрондау қатесі: %@
cloud.error.notConfigured¦Сервер ATA MURA не подключён.¦The ATA MURA server is not connected.¦ATA MURA сервері қосылмаған.
cloud.error.http¦Ошибка сервера (%@).¦Server error (%@).¦Сервер қатесі (%@).
cloud.error.confirm¦Мы отправили письмо для подтверждения email. Подтвердите адрес и войдите.¦We sent a confirmation email. Confirm your address and sign in.¦Email-ді растау хатын жібердік. Мекенжайды растап, кіріңіз.
cloud.error.noSession¦Войдите в аккаунт.¦Please sign in.¦Аккаунтқа кіріңіз.
cloud.error.rls¦Недостаточно прав для этого действия.¦You don't have permission for this action.¦Бұл әрекетке құқығыңыз жеткіліксіз.
cloud.error.schema¦Таблицы ATA MURA не найдены: выполните backend/schema.sql в Supabase.¦ATA MURA tables not found: run backend/schema.sql in Supabase.¦ATA MURA кестелері табылмады: Supabase-те backend/schema.sql орындаңыз.
course.create¦Создать курс¦Create course¦Курс жасау
course.titleField¦Название курса¦Course title¦Курс атауы
course.description¦Описание¦Description¦Сипаттама
course.teacher¦Преподаватель¦Teacher¦Оқытушы
course.access¦Доступ¦Access¦Қолжетімділік
course.price¦Цена, ₸¦Price, ₸¦Бағасы, ₸
course.discount¦Скидка: %@%¦Discount: %@%¦Жеңілдік: %@%
course.salesStart¦Начало продаж¦Sales start¦Сату басталуы
course.limitSeats¦Ограничить количество мест¦Limit seats¦Орын санын шектеу
course.seats¦Мест: %@¦Seats: %@¦Орын: %@
course.pricing¦Цена и продажи¦Pricing & sales¦Баға және сату
course.pricingHint¦Цену ставите вы: 0 ₸, 5 000 ₸, 20 000 ₸ или любую другую. «Только для участников» — бесплатно с уровня Researcher.¦You set the price: 0 ₸, 5,000 ₸, 20,000 ₸ or any other. “Members only” is free from the Researcher level.¦Бағаны өзіңіз қоясыз: 0 ₸, 5 000 ₸, 20 000 ₸ немесе кез келген. «Тек қатысушыларға» — Researcher деңгейінен тегін.
course.promo¦Промокоды¦Promo codes¦Промокодтар
course.promoCode¦Новый промокод¦New promo code¦Жаңа промокод
course.lesson¦Урок %@¦Lesson %@¦%@-сабақ
course.addLesson¦Добавить урок¦Add lesson¦Сабақ қосу
course.publish¦Опубликовать¦Publish¦Жариялау
course.students¦Учеников: %@¦Students: %@¦Оқушылар: %@
access.free¦Бесплатный¦Free¦Тегін
access.paid¦Платный¦Paid¦Ақылы
access.subscription¦По подписке¦Subscription¦Жазылым бойынша
access.membersOnly¦Только для участников ATA MURA¦ATA MURA members only¦Тек ATA MURA қатысушыларына
lesson.video¦Ссылка на видео урока¦Lesson video link¦Сабақ бейнесіне сілтеме
lesson.pdf¦Ссылка на PDF¦PDF link¦PDF сілтемесі
lesson.text¦Текст урока¦Lesson text¦Сабақ мәтіні
lesson.question¦Вопрос теста¦Quiz question¦Тест сұрағы
lesson.options¦Варианты через «;»¦Options separated by “;”¦Нұсқалар «;» арқылы
lesson.correct¦Правильный вариант: %@¦Correct option: %@¦Дұрыс нұсқа: %@
events.title¦Мероприятия¦Events¦Іс-шаралар
events.new¦Новое мероприятие¦New event¦Жаңа іс-шара
events.date¦Дата и время¦Date and time¦Күні мен уақыты
events.place¦Место проведения¦Venue¦Өтетін орны
guests.empty¦Добавьте героев для интервью: учёных, детей, инженеров, партнёров, ветеранов отрасли, историков.¦Add interview guests: scientists, children, engineers, partners, industry veterans, historians.¦Сұхбатқа кейіпкерлер қосыңыз: ғалымдар, балалар, инженерлер, серіктестер, сала ардагерлері, тарихшылар.
guests.new¦Новый гость¦New guest¦Жаңа қонақ
guests.name¦Имя¦Name¦Аты
guests.category¦Кто это¦Who¦Кім
guests.contacts¦Контакты¦Contacts¦Байланыс
guests.topic¦Тема интервью¦Interview topic¦Сұхбат тақырыбы
guests.notes¦Заметки¦Notes¦Жазбалар
guests.appeared¦Участвовал(а) в роликах¦Appeared in¦Қатысқан бейнелер
guestcat.scientist¦Учёный¦Scientist¦Ғалым
guestcat.child¦Ребёнок¦Child¦Бала
guestcat.engineer¦Инженер¦Engineer¦Инженер
guestcat.partner¦Партнёр¦Partner¦Серіктес
guestcat.veteran¦Ветеран отрасли¦Industry veteran¦Сала ардагері
guestcat.historian¦Историк¦Historian¦Тарихшы
guestcat.other¦Другое¦Other¦Басқа
gueststatus.candidate¦Кандидат¦Candidate¦Үміткер
gueststatus.invited¦Приглашён¦Invited¦Шақырылды
gueststatus.agreed¦Согласился¦Agreed¦Келісті
gueststatus.filmed¦Снят¦Filmed¦Түсірілді
gueststatus.declined¦Отказался¦Declined¦Бас тартты
ideas.placeholder¦Например: снять ролик про забытых инженеров Казахстана¦E.g. film a video about the forgotten engineers of Kazakhstan¦Мысалы: Қазақстанның ұмытылған инженерлері туралы бейне түсіру
ideas.save¦Сохранить идею¦Save idea¦Идеяны сақтау
ideas.aiResult¦Предложения AI: названия, структура, вопросы, Shorts¦AI suggestions: titles, structure, questions, Shorts¦AI ұсыныстары: атаулар, құрылым, сұрақтар, Shorts
ideas.toCalendar¦В календарь¦To calendar¦Күнтізбеге
ideas.inCalendar¦В календаре¦In calendar¦Күнтізбеде
kids.title¦История глазами ребёнка¦History through a child's eyes¦Бала көзімен тарих
kids.about¦Выбери историческую тему и сделай рисунок, модель, LEGO-модель, 3D-модель, видео, комикс или изобретение.¦Choose a history theme and make a drawing, model, LEGO model, 3D model, video, comic or invention.¦Тарихи тақырып таңдап, сурет, модель, LEGO-модель, 3D-модель, бейне, комикс немесе өнертабыс жаса.
kids.themes¦Темы¦Themes¦Тақырыптар
kids.make¦Сделать работу¦Make a work¦Жұмыс жасау
kids.free¦Своя тема¦My own theme¦Өз тақырыбым
kids.gallery¦Галерея работ¦Gallery¦Жұмыстар галереясы
kids.empty¦Работ пока нет — стань первым!¦No works yet — be the first!¦Әзірге жұмыс жоқ — бірінші бол!
kids.theme¦Тема¦Theme¦Тақырып
kids.format¦Формат¦Format¦Формат
kids.describe¦Расскажи о своей работе¦Tell us about your work¦Жұмысың туралы айтып бер
kids.parentNote¦Если тебе меньше 14 лет, публикуй работу вместе с родителями или учителем. Не указывай фамилию и адрес.¦If you are under 14, publish together with a parent or teacher. Don't share your surname or address.¦Егер 14-ке толмасаң, жұмысты ата-анаңмен немесе мұғаліммен бірге жарияла. Тегіңді және мекенжайыңды көрсетпе.
kidsformat.drawing¦Рисунок¦Drawing¦Сурет
kidsformat.model¦Модель¦Model¦Модель
kidsformat.lego¦LEGO-модель¦LEGO model¦LEGO-модель
kidsformat.model3D¦3D-модель¦3D model¦3D-модель
kidsformat.video¦Видео¦Video¦Бейне
kidsformat.comic¦Комикс¦Comic¦Комикс
kidsformat.invention¦Изобретение¦Invention¦Өнертабыс
magazine.create¦Создать выпуск¦Create issue¦Шығарылым жасау
magazine.number¦Номер выпуска: %@¦Issue number: %@¦Шығарылым нөмірі: %@
magazine.titleField¦Название выпуска¦Issue title¦Шығарылым атауы
magazine.description¦Описание¦Description¦Сипаттама
magazine.release¦Дата выпуска¦Release date¦Шығу күні
magazine.cover¦Обложка¦Cover¦Мұқаба
magazine.uploadPdf¦Загрузить PDF-журнал¦Upload magazine PDF¦PDF-журналды жүктеу
magazine.pdfReady¦PDF загружен (%@) — заменить¦PDF uploaded (%@) — replace¦PDF жүктелді (%@) — ауыстыру
magazine.pdfURL¦Или ссылка на PDF¦Or a PDF link¦Немесе PDF сілтемесі
magazine.pdfHint¦Большие PDF лучше хранить по ссылке (Google Drive, сайт), чтобы приложение работало быстро.¦Large PDFs are better linked (Google Drive, website) to keep the app fast.¦Үлкен PDF-ті сілтеме арқылы сақтаған дұрыс (Google Drive, сайт), сонда қосымша жылдам жұмыс істейді.
magazine.authors¦Авторы¦Authors¦Авторлар
magazine.board¦Редакционная коллегия¦Editorial board¦Редакция алқасы
magazine.price¦Цена, ₸ (0 — бесплатно)¦Price, ₸ (0 — free)¦Бағасы, ₸ (0 — тегін)
magazine.publish¦Опубликовать выпуск¦Publish issue¦Шығарылымды жариялау
magazine.publishHint¦После публикации выпуск появится в ленте пользователей как пост «Вышел новый номер ATA MURA Magazine».¦Once published, the issue appears in the feed as “A new ATA MURA Magazine issue is out”.¦Жарияланғаннан кейін шығарылым таспада «ATA MURA Magazine-ның жаңа саны шықты» жазбасы ретінде көрінеді.
magazine.newIssue¦Вышел новый номер ATA MURA Magazine¦A new ATA MURA Magazine issue is out¦ATA MURA Magazine-ның жаңа саны шықты
magazine.empty¦Выпусков пока нет.¦No issues yet.¦Әзірге шығарылым жоқ.
magazine.read¦Читать¦Read¦Оқу
magazine.readOnline¦Открыть PDF по ссылке¦Open PDF link¦PDF сілтемесін ашу
magazine.noPdf¦PDF выпуска скоро будет добавлен.¦The issue PDF will be added soon.¦Шығарылымның PDF-і жақында қосылады.
magazine.buy¦Купить за %@¦Buy for %@¦%@-ге сатып алу
mapadmin.topics¦Темы энциклопедии («Связать с историей»)¦Encyclopedia topics (“Link to history”)¦Энциклопедия тақырыптары («Тарихпен байланыстыру»)
mapadmin.keywords¦Ключевые слова (через запятую)¦Keywords (comma-separated)¦Кілт сөздер (үтір арқылы)
mapadmin.places¦Места на карте¦Map places¦Картадағы орындар
mapadmin.year¦Год / период¦Year / period¦Жылы / кезеңі
mapadmin.author¦Автор идеи¦Author of the idea¦Идея авторы
mapadmin.prompt¦Задание для детей¦Task for children¦Балаларға тапсырма
market.add¦Добавить товар¦Add product¦Тауар қосу
market.buy¦Купить¦Buy¦Сатып алу
market.kind¦Тип¦Type¦Түрі
market.limited¦Ограниченное количество¦Limited quantity¦Шектеулі саны
market.product¦Товар¦Product¦Тауар
market.stock¦В наличии: %@¦In stock: %@¦Қолда бар: %@
product.ebook¦Электронные книги¦E-books¦Электронды кітаптар
product.magazine¦Журналы¦Magazines¦Журналдар
product.ticket¦Билеты на мероприятия¦Event tickets¦Іс-шара билеттері
product.masterclass¦Мастер-классы¦Masterclasses¦Шеберлік сабақтары
product.kit¦Наборы Kids Inventors Lab¦Kids Inventors Lab kits¦Kids Inventors Lab жинақтары
product.lecture¦Закрытые лекции¦Private lectures¦Жабық дәрістер
media.add¦Добавить в медиатеку¦Add to library¦Медиатекаға қосу
media.empty¦Здесь будут фото, видео, логотипы, музыка, документы, архивы и обложки.¦Photos, videos, logos, music, documents, archives and covers will live here.¦Мұнда фото, бейне, логотип, музыка, құжат, мұрағат және мұқабалар сақталады.
media.kind¦Тип¦Type¦Түрі
media.tags¦Теги¦Tags¦Тегтер
media.url¦Ссылка на файл (Drive, YouTube…)¦File link (Drive, YouTube…)¦Файл сілтемесі (Drive, YouTube…)
media.photo¦Фото¦Photo¦Фото
media.video¦Видео¦Video¦Бейне
media.logo¦Логотипы¦Logos¦Логотиптер
media.music¦Музыка¦Music¦Музыка
media.document¦Документы¦Documents¦Құжаттар
media.archive¦Архивные материалы¦Archive materials¦Мұрағат материалдары
media.cover¦Обложки¦Covers¦Мұқабалар
museum.about¦Народный цифровой музей Казахстана. Сфотографируйте старый предмет — приложение задаст вопросы: что это, кому принадлежало, примерный год.¦The people's digital museum of Kazakhstan. Photograph an old object — the app will ask: what is it, who owned it, roughly what year.¦Қазақстанның халықтық цифрлық музейі. Ескі затты суретке түсіріңіз — қосымша сұрайды: бұл не, кімдікі болған, шамамен қай жыл.
museum.onlyFamily¦Только «Музей вещей моей семьи»¦Only “My family's museum”¦Тек «Отбасымның заттар музейі»
museum.empty¦Экспонатов пока нет.¦No items yet.¦Әзірге жәдігер жоқ.
museum.family¦Музей вещей моей семьи¦My family's museum¦Отбасымның заттар музейі
museum.what¦Что это¦What it is¦Бұл не
museum.owner¦Кому принадлежало¦Who it belonged to¦Кімдікі болған
museum.place¦Место¦Place¦Орны
museum.story¦История предмета¦The object's story¦Заттың тарихы
museum.addedBy¦Добавил(а): %@¦Added by %@¦Қосқан: %@
museum.step.photo¦Шаг 1. Сфотографируйте предмет¦Step 1. Photograph the object¦1-қадам. Затты суретке түсіріңіз
museum.step.questions¦Шаг 2. Ответьте на вопросы¦Step 2. Answer the questions¦2-қадам. Сұрақтарға жауап беріңіз
museum.q.title¦Как назвать экспонат?¦What should we call it?¦Жәдігерді қалай атаймыз?
museum.q.what¦Что это?¦What is it?¦Бұл не?
museum.q.owner¦Кому принадлежало?¦Who did it belong to?¦Кімдікі болған?
museum.q.period¦Примерный год или период?¦Approximate year or period?¦Шамамен қай жыл немесе кезең?
museum.q.place¦Где хранился или где найден?¦Where was it kept or found?¦Қайда сақталған немесе табылған?
museum.q.story¦Расскажите его историю¦Tell its story¦Оның тарихын айтыңыз
museum.video¦Ссылка на видео¦Video link¦Бейне сілтемесі
museum.model3d¦Ссылка на 3D-модель (Sketchfab и др.)¦3D model link (Sketchfab etc.)¦3D-модель сілтемесі (Sketchfab т.б.)
museum.needPhoto¦Нужна хотя бы одна фотография.¦At least one photo is required.¦Кемінде бір фото қажет.
news.headline¦Заголовок¦Headline¦Тақырып
news.text¦Текст новости¦News text¦Жаңалық мәтіні
news.languagesHint¦Заполните хотя бы один язык. Пользователь видит новость на своём языке, а если перевода нет — на доступном.¦Fill at least one language. Users see the news in their language, or in any available one if there is no translation.¦Кемінде бір тілді толтырыңыз. Пайдаланушы жаңалықты өз тілінде, аударма болмаса — қолжетімді тілде көреді.
news.photo¦Фото новости¦News photo¦Жаңалық фотосы
news.buttonTitle¦Текст кнопки (например, «Подробнее»)¦Button text (e.g. “Read more”)¦Түйме мәтіні (мысалы, «Толығырақ»)
news.buttonURL¦Ссылка кнопки¦Button link¦Түйме сілтемесі
news.pin¦Закрепить сверху¦Pin to top¦Жоғарыға бекіту
news.draft¦Черновик¦Draft¦Қаралама
news.publishAt¦Дата публикации¦Publish date¦Жариялау күні
news.scheduleHint¦Если дата в будущем — новость выйдет автоматически в это время.¦If the date is in the future, the news will go out automatically at that time.¦Күн болашақта болса — жаңалық сол уақытта автоматты түрде шығады.
news.saveDraft¦Сохранить черновик¦Save draft¦Қараламаны сақтау
news.schedule¦Запланировать¦Schedule¦Жоспарлау
news.publishNow¦Опубликовать сейчас¦Publish now¦Қазір жариялау
news.preview¦Предпросмотр¦Preview¦Алдын ала қарау
news.published¦Опубликовано¦Published¦Жарияланды
news.scheduled¦Запланировано¦Scheduled¦Жоспарланды
news.more¦Подробнее¦Read more¦Толығырақ
order.pending¦Ожидает оплаты¦Awaiting payment¦Төлем күтілуде
order.paid¦Оплачено¦Paid¦Төленді
order.cancelled¦Отменён¦Cancelled¦Бас тартылды
order.refunded¦Возврат¦Refunded¦Қайтарылды
orders.title¦Мои заказы¦My orders¦Тапсырыстарым
orders.empty¦Заказов нет.¦No orders.¦Тапсырыс жоқ.
orders.confirm¦Оплачено¦Mark paid¦Төленді
orders.cancel¦Отменить¦Cancel¦Болдырмау
orders.refund¦Возврат¦Refund¦Қайтару
payment.method¦Способ оплаты¦Payment method¦Төлем тәсілі
payment.kaspi¦Kaspi¦Kaspi¦Kaspi
payment.card¦Банковская карта¦Bank card¦Банк картасы
payment.transfer¦Банковский перевод¦Bank transfer¦Банк аударымы
payment.cash¦Наличными на месте¦Cash on site¦Орнында қолма-қол
partners.new¦Новый партнёр или спонсор¦New partner or sponsor¦Жаңа серіктес немесе демеуші
partners.name¦Организация¦Organisation¦Ұйым
partners.kind¦Тип¦Type¦Түрі
partners.agreement¦Соглашение / формат сотрудничества¦Agreement / cooperation format¦Келісім / ынтымақтастық түрі
partners.amount¦Сумма поддержки, ₸¦Support amount, ₸¦Қолдау сомасы, ₸
partnerkind.partner¦Партнёры¦Partners¦Серіктестер
partnerkind.sponsor¦Спонсоры¦Sponsors¦Демеушілер
people.onlyMentors¦Только эксперты и научные руководители¦Only experts and supervisors¦Тек сарапшылар мен ғылыми жетекшілер
profile.city¦Город / аул¦City / village¦Қала / ауыл
profile.bio¦О себе¦About me¦Өзім туралы
profile.photo¦Фото профиля¦Profile photo¦Профиль фотосы
profile.portfolio¦Портфолио¦Portfolio¦Портфолио
profile.titlesHint¦Роли через запятую: Inventor, Researcher, Web Developer¦Roles, comma-separated: Inventor, Researcher, Web Developer¦Рөлдер үтір арқылы: Inventor, Researcher, Web Developer
profile.skills¦Навыки¦Skills¦Дағдылар
profile.mentorToggle¦Я эксперт и могу быть научным руководителем¦I'm an expert and can supervise research¦Мен сарапшымын және ғылыми жетекші бола аламын
profile.expertise¦Области экспертизы (через запятую)¦Areas of expertise (comma-separated)¦Сараптама салалары (үтір арқылы)
profile.mentorHint¦Школьники и студенты смогут найти вас через «Найти научного руководителя».¦Students will find you via “Find a supervisor”.¦Оқушылар мен студенттер сізді «Ғылыми жетекші табу» арқылы таба алады.
profile.mentor¦Эксперт¦Expert¦Сарапшы
profile.my¦Моё¦My space¦Менің бөлімім
profile.posts¦Публикации¦Publications¦Жарияланымдар
profile.block¦Заблокировать¦Block¦Бұғаттау
quest.levels¦Уровни¦Levels¦Деңгейлер
quest.tasks¦Задания¦Quests¦Тапсырмалар
quest.done¦выполнено¦completed¦орындалды
quest.toNext¦Ещё %@ баллов до уровня %@¦%@ more points to %@¦Тағы %@ ұпай — %@ деңгейіне дейін
quest.firstPost¦Опубликуй первую историю¦Publish your first story¦Алғашқы әңгімеңді жарияла
quest.firstPost.hint¦Любая публикация в TARIH или ленте.¦Any publication in TARIH or the feed.¦TARIH-тағы немесе таспадағы кез келген жарияланым.
quest.familyRoots¦Найди историю своего рода¦Find your family's story¦Әулетіңнің тарихын тап
quest.familyRoots.hint¦Опубликуй семейную историю.¦Publish a family story.¦Отбасы тарихын жарияла.
quest.elderInterview¦Возьми интервью у человека старше 70 лет¦Interview someone over 70¦70 жастан асқан адаммен сұхбат ал
quest.elderInterview.hint¦Публикация с категорией «Устная история».¦A publication in the “Oral history” category.¦«Ауызша тарих» санатындағы жарияланым.
quest.museumItem¦Добавь экспонат в музей¦Add a museum item¦Музейге жәдігер қос
quest.museumItem.hint¦Сфотографируй старый семейный предмет.¦Photograph an old family object.¦Отбасындағы ескі затты суретке түсір.
quest.kidsWork¦«История глазами ребёнка»¦“History through a child's eyes”¦«Бала көзімен тарих»
quest.kidsWork.hint¦Рисунок, модель, LEGO, видео или комикс.¦A drawing, model, LEGO, video or comic.¦Сурет, модель, LEGO, бейне немесе комикс.
quest.mapPlace¦Отметь место на карте¦Add a place to the map¦Картаға орын белгіле
quest.mapPlace.hint¦Памятник, шахта, легенда твоего края.¦A monument, mine or legend of your region.¦Өлкеңнің ескерткіші, шахтасы, аңызы.
quest.engineering¦Создай инженерное решение¦Create an engineering solution¦Инженерлік шешім жаса
quest.engineering.hint¦Проект в Inventors Lab.¦A project in Inventors Lab.¦Inventors Lab-тағы жоба.
quest.continueIdea¦Продолжи забытую идею¦Continue a forgotten idea¦Ұмытылған идеяны жалғастыр
quest.continueIdea.hint¦Проект из Forgotten Ideas.¦A project from Forgotten Ideas.¦Forgotten Ideas-тағы жоба.
quest.research¦Опубликуй исследование¦Publish research¦Зерттеу жарияла
quest.research.hint¦Статья, прошедшая рецензирование в ATA MURA Research.¦A peer-reviewed article in ATA MURA Research.¦ATA MURA Research-те рецензиядан өткен мақала.
reminder.shoot¦Через 2 часа съёмка: %@¦Shooting in 2 hours: %@¦2 сағаттан кейін түсірілім: %@
reminder.publish¦Через 2 часа публикация: %@¦Publishing in 2 hours: %@¦2 сағаттан кейін жариялау: %@
research.about¦Статьи школьников, студентов и учёных: автор, ORCID, источники, DOI, рецензирование и версии.¦Articles by students and scholars: author, ORCID, sources, DOI, peer review and versions.¦Оқушылардың, студенттердің және ғалымдардың мақалалары: автор, ORCID, дереккөздер, DOI, рецензия және нұсқалар.
research.mine¦Мои статьи¦My articles¦Менің мақалаларым
research.published¦Опубликованные¦Published¦Жарияланғандар
research.empty¦Опубликованных статей пока нет.¦No published articles yet.¦Әзірге жарияланған мақала жоқ.
research.needsSupervisor¦Нужен научный руководитель¦Needs a supervisor¦Ғылыми жетекші керек
research.abstract¦Аннотация¦Abstract¦Аңдатпа
research.openPDF¦Открыть PDF статьи¦Open article PDF¦Мақаланың PDF-ін ашу
research.versions¦Версии статьи¦Versions¦Мақала нұсқалары
research.supervisorNeeded¦Нужен эксперт: %@¦Expert needed: %@¦Сарапшы керек: %@
research.supervisor¦Научный руководитель: %@¦Supervisor: %@¦Ғылыми жетекші: %@
research.findSupervisor¦Найти научного руководителя¦Find a supervisor¦Ғылыми жетекші табу
research.reviews¦Рецензии¦Reviews¦Рецензиялар
research.submit¦Отправить на рецензию¦Submit for review¦Рецензияға жіберу
research.status¦Статус рецензирования¦Review status¦Рецензия мәртебесі
research.writeReview¦Написать рецензию¦Write a review¦Рецензия жазу
research.verdict¦Решение¦Verdict¦Шешім
research.reviewText¦Текст рецензии¦Review text¦Рецензия мәтіні
research.mentorHint¦Подходящие эксперты по теме: %@¦Suitable experts for: %@¦Тақырып бойынша сарапшылар: %@
research.noMentors¦Экспертов пока нет. Эксперты отмечают себя в профиле.¦No experts yet. Experts mark themselves in their profile.¦Әзірге сарапшы жоқ. Сарапшылар өздерін профильде белгілейді.
research.ask¦Попросить¦Ask¦Сұрау
research.section.main¦Статья¦Article¦Мақала
research.authors¦Авторы¦Authors¦Авторлар
research.field¦Область науки¦Field¦Ғылым саласы
research.keywords¦Ключевые слова (через запятую)¦Keywords (comma-separated)¦Кілт сөздер (үтір арқылы)
research.body¦Полный текст (необязательно, если есть PDF)¦Full text (optional if you attach a PDF)¦Толық мәтін (PDF болса, міндетті емес)
research.attachPDF¦Прикрепить PDF¦Attach PDF¦PDF тіркеу
research.replacePDF¦Заменить PDF¦Replace PDF¦PDF ауыстыру
research.doi¦DOI (если статья опубликована)¦DOI (if published)¦DOI (мақала жарияланған болса)
research.supervisorSection¦Научный руководитель¦Supervisor¦Ғылыми жетекші
research.expertise¦Какой эксперт нужен (например, Railway Engineering / History)¦What expert you need (e.g. Railway Engineering / History)¦Қандай сарапшы керек (мысалы, Railway Engineering / History)
research.newVersion¦Новая версия¦New version¦Жаңа нұсқа
research.versionNote¦Что изменилось¦What changed¦Не өзгерді
research.saveVersion¦Сохранить¦Save¦Сақтау
research.draftNote¦Статья сохраняется как черновик. Когда будете готовы — отправьте её на рецензию.¦The article is saved as a draft. When ready, submit it for review.¦Мақала қаралама ретінде сақталады. Дайын болғанда — рецензияға жіберіңіз.
research.firstVersion¦Первая версия¦First version¦Алғашқы нұсқа
review.draft¦Черновик¦Draft¦Қаралама
review.submitted¦На рецензии¦Submitted¦Рецензияда
review.inReview¦Рецензируется¦In review¦Рецензияланып жатыр
review.reviewed¦Рецензия получена¦Reviewed¦Рецензия алынды
review.published¦Опубликована¦Published¦Жарияланды
verdict.accept¦Принять¦Accept¦Қабылдау
verdict.minor¦Мелкие правки¦Minor revisions¦Шағын түзетулер
verdict.major¦Серьёзные правки¦Major revisions¦Елеулі түзетулер
verdict.reject¦Отклонить¦Reject¦Қабылдамау
series.new¦Новая рубрика¦New series¦Жаңа айдар
series.progress¦Выпущено %@ из %@¦Released %@ of %@¦%@/%@ шықты
series.next¦Следующий: %@¦Next: %@¦Келесісі: %@
series.avgViews¦В среднем %@ просмотров¦Average %@ views¦Орташа %@ қаралым
series.planned¦Запланировано выпусков: %@¦Planned episodes: %@¦Жоспарланған шығарылым: %@
settings.title¦Настройки¦Settings¦Баптаулар
settings.language¦Язык¦Language¦Тіл
settings.deleteAccount¦Удалить аккаунт¦Delete account¦Аккаунтты жою
settings.deleteConfirm¦Удалить аккаунт и все ваши публикации? Это нельзя отменить.¦Delete your account and all your publications? This can't be undone.¦Аккаунтты және барлық жарияланымдарыңызды жою керек пе? Мұны қайтару мүмкін емес.
settings.deleteHint¦Аккаунт и материалы удаляются сразу, в том числе с сервера.¦Your account and content are deleted immediately, including from the server.¦Аккаунт пен материалдар бірден, соның ішінде серверден де жойылады.
studio.status¦Статус¦Status¦Мәртебе
studio.pipeline¦Воронка роликов¦Video pipeline¦Бейнелер легі
studio.videos¦Ролики месяца¦This month's videos¦Айдың бейнелері
studio.empty¦В этом месяце роликов нет. Нажмите «+».¦No videos this month. Tap “+”.¦Бұл айда бейне жоқ. «+» басыңыз.
studio.untitled¦Без названия¦Untitled¦Атаусыз
studio.newVideo¦Новый ролик¦New video¦Жаңа бейне
studio.title¦Название ролика¦Video title¦Бейне атауы
studio.dates¦Даты¦Dates¦Күндер
studio.shootDate¦Дата съёмки¦Shooting date¦Түсірілім күні
studio.publishDate¦Дата публикации¦Publish date¦Жариялау күні
studio.reminder¦Напомнить (за 2 часа)¦Remind me (2 hours before)¦Еске салу (2 сағат бұрын)
studio.responsible¦Ответственный¦Responsible¦Жауапты
studio.card¦Рабочая карточка¦Working card¦Жұмыс карточкасы
studio.idea¦Идея¦Idea¦Идея
studio.goal¦Цель¦Goal¦Мақсат
studio.audience¦Аудитория¦Audience¦Аудитория
studio.hook¦Хук первых 5 секунд¦Hook for the first 5 seconds¦Алғашқы 5 секундтың хугы
studio.script¦Сценарий¦Script¦Сценарий
studio.shotList¦Список кадров¦Shot list¦Кадрлар тізімі
studio.questions¦Вопросы для интервью¦Interview questions¦Сұхбат сұрақтары
studio.props¦Реквизит¦Props¦Реквизит
studio.location¦Место съёмки¦Location¦Түсірілім орны
studio.participants¦Участники¦Participants¦Қатысушылар
studio.music¦Музыка¦Music¦Музыка
studio.cover¦Обложка¦Cover¦Мұқаба
studio.description¦Описание¦Description¦Сипаттама
studio.hashtags¦Хэштеги¦Hashtags¦Хэштегтер
studio.links¦Ссылки¦Links¦Сілтемелер
studio.aiHelp¦AI: 10 названий, структура, вопросы, Shorts¦AI: 10 titles, structure, questions, Shorts¦AI: 10 атау, құрылым, сұрақтар, Shorts
studio.aiToScript¦Вставить в сценарий¦Insert into script¦Сценарийге қою
studio.result¦Результат после публикации¦Results after publishing¦Жарияланғаннан кейінгі нәтиже
studio.likes¦Лайки¦Likes¦Лайктар
studio.comments¦Комментарии¦Comments¦Пікірлер
studio.subscribers¦Новые подписчики¦New subscribers¦Жаңа жазылушылар
studio.resultNotes¦Выводы¦Takeaways¦Қорытынды
cstatus.idea¦Идея¦Idea¦Идея
cstatus.script¦Сценарий¦Script¦Сценарий
cstatus.shooting¦Съёмка¦Shooting¦Түсірілім
cstatus.editing¦Монтаж¦Editing¦Монтаж
cstatus.ready¦Готово¦Ready¦Дайын
cstatus.published¦Опубликовано¦Published¦Жарияланды
tasks.new¦Новая задача¦New task¦Жаңа тапсырма
tasks.due¦Срок¦Due¦Мерзімі
tasks.open¦В работе¦Open¦Орындалуда
tasks.done¦Готово¦Done¦Дайын
users.role¦Роль¦Role¦Рөл
users.blocked¦Блок¦Blocked¦Бұғат
"""#
}
