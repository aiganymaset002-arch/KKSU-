//
//  KKSUBilling.swift
//  KKSU Online
//
//  Монетизация KKSU: платные продукты, счета (инвойсы), оплата переводом
//  на счёт получателя (Kaspi, Halyk и другие банки, международные переводы),
//  конвертация валют, промокоды, подписки (в т.ч. семейная), стипендии,
//  возвраты, автоматическое открытие доступа после подтверждённой оплаты.
//
//  Схема оплаты без эквайринга: приложение выставляет счёт с уникальным кодом →
//  плательщик переводит сумму на номер/счёт получателя и прикладывает чек →
//  администратор сверяет поступление и подтверждает → доступ открывается автоматически.
//

import Foundation

// MARK: - Реквизиты получателя

/// Реквизиты по умолчанию. Администратор может изменить их в приложении:
/// «Модули → Настройки оплаты».
enum KKSUPaymentDefaults {
    static let recipientPhone = "+7 771 473 18 52"
    static let recipientName = "Получатель KKSU"
    static let usdToKzt = 505.0
    static let eurToKzt = 550.0
}

struct PaymentSettings: Codable, Hashable {
    var recipientPhone = KKSUPaymentDefaults.recipientPhone
    var recipientName = KKSUPaymentDefaults.recipientName
    /// Курс для пересчёта цен в тенге (банк при переводе конвертирует по своему курсу).
    var usdToKzt = KKSUPaymentDefaults.usdToKzt
    var eurToKzt = KKSUPaymentDefaults.eurToKzt
    var enabledMethods: [PaymentMethod] = PaymentMethod.allCases
    /// Срок, в течение которого можно запросить возврат.
    var refundDays = 14
    var instructionsFooter = "В комментарии к переводу обязательно укажите код счёта — так мы быстрее найдём ваш платёж."
}

enum PayCurrency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD", eur = "EUR", kzt = "KZT"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .kzt: return "₸"
        }
    }
}

// MARK: - Способы оплаты

enum PaymentRegion: String, Codable, CaseIterable, Identifiable {
    case kazakhstan, international
    var id: String { rawValue }
    var title: String { self == .kazakhstan ? "Из Казахстана" : "Из-за рубежа (США, Европа и др.)" }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case kaspi, halyk, freedom, jusan, forte, bereke, bcc, homeCredit, otherKZBank
    case internationalCard, koronaPay, westernUnion, wise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kaspi: return "Kaspi.kz"
        case .halyk: return "Halyk Bank (Homebank)"
        case .freedom: return "Freedom Bank"
        case .jusan: return "Jusan Bank"
        case .forte: return "ForteBank"
        case .bereke: return "Bereke Bank"
        case .bcc: return "Банк ЦентрКредит"
        case .homeCredit: return "Home Credit Bank"
        case .otherKZBank: return "Другой банк Казахстана"
        case .internationalCard: return "Карта Visa / Mastercard любой страны"
        case .koronaPay: return "Korona Pay (Золотая Корона)"
        case .westernUnion: return "Western Union"
        case .wise: return "Wise"
        }
    }

    var icon: String {
        switch self {
        case .kaspi: return "k.circle.fill"
        case .halyk: return "h.circle.fill"
        case .internationalCard: return "creditcard.fill"
        case .koronaPay, .westernUnion, .wise: return "globe.europe.africa.fill"
        default: return "building.columns.fill"
        }
    }

    var region: PaymentRegion {
        switch self {
        case .internationalCard, .koronaPay, .westernUnion, .wise: return .international
        default: return .kazakhstan
        }
    }

    /// В какой валюте удобнее всего платить этим способом.
    var preferredCurrency: PayCurrency {
        switch self {
        case .internationalCard, .westernUnion, .wise: return .usd
        default: return .kzt
        }
    }

    /// Пошаговая инструкция для плательщика.
    func instructions(settings: PaymentSettings, amount: String, code: String) -> [String] {
        let phone = settings.recipientPhone
        switch self {
        case .kaspi:
            return ["Откройте приложение Kaspi.kz → «Переводы» → «Клиенту Kaspi».",
                    "Введите номер телефона \(phone).",
                    "Проверьте имя получателя: \(settings.recipientName).",
                    "Сумма: \(amount). Комментарий: \(code)."]
        case .halyk, .freedom, .jusan, .forte, .bereke, .bcc, .homeCredit, .otherKZBank:
            return ["Откройте приложение своего банка (\(title)) → «Переводы» → «По номеру телефона» / «В другой банк».",
                    "Введите номер \(phone) и выберите банк получателя Kaspi Bank.",
                    "Сумма: \(amount). Комментарий: \(code).",
                    "Межбанковский перевод по номеру телефона зачисляется на счёт Kaspi получателя."]
        case .internationalCard:
            return ["Оплата картой из США, Франции, Италии и других стран возможна двумя способами:",
                    "1) через сервис денежных переводов (Korona Pay, Western Union, Wise) — выберите его в списке;",
                    "2) через онлайн-оплату картой, если администратор KKSU подключил интернет-эквайринг.",
                    "Сумма к оплате: \(amount). Банк спишет её в вашей валюте и сконвертирует автоматически. Код счёта: \(code)."]
        case .koronaPay:
            return ["Откройте Korona Pay (koronapay.com) или приложение.",
                    "Страна получателя: Казахстан. Получатель: \(settings.recipientName), телефон \(phone), банк Kaspi.",
                    "Отправьте \(amount) — сервис сам сконвертирует валюту в тенге.",
                    "В сообщении получателю укажите код \(code)."]
        case .westernUnion:
            return ["Оформите перевод в Казахстан на сайте westernunion.com или в отделении.",
                    "Получатель: \(settings.recipientName), телефон \(phone). Если доступно зачисление на счёт — выберите Kaspi Bank.",
                    "Сумма: \(amount). Отправьте нам номер перевода (MTCN) и чек.",
                    "Код счёта: \(code)."]
        case .wise:
            return ["В Wise выберите перевод в KZT (тенге), Казахстан.",
                    "Реквизиты получателя (IBAN Kaspi) запросите у администратора KKSU в чате.",
                    "Сумма: \(amount); конвертация выполняется Wise автоматически.",
                    "В назначении платежа укажите \(code)."]
        }
    }
}

// MARK: - Продукты

enum ProductKind: String, Codable, CaseIterable, Identifiable {
    case enrollment, course, teacherAcademy, teacherCertification, marketplaceListing, marketplaceCourse
    case futureEngineers, globalClassroom, youngInventors, inventionsService, conference, subscription

    var id: String { rawValue }

    var title: String {
        switch self {
        case .enrollment: return "Статус ученика KKSU"
        case .course: return "Образовательные курсы"
        case .teacherAcademy: return "Teacher Academy"
        case .teacherCertification: return "Сертификация педагогов"
        case .marketplaceListing: return "Публикация курса педагогом"
        case .marketplaceCourse: return "Teacher Marketplace"
        case .futureEngineers: return "Future Engineers"
        case .globalClassroom: return "Global Classroom"
        case .youngInventors: return "Young Inventors 30"
        case .inventionsService: return "Услуги KKSU Inventions"
        case .conference: return "Конференции"
        case .subscription: return "Подписка KKSU"
        }
    }

    var icon: String {
        switch self {
        case .enrollment: return "graduationcap.fill"
        case .course: return "book.fill"
        case .teacherAcademy: return "building.columns.fill"
        case .teacherCertification: return "rosette"
        case .marketplaceListing: return "megaphone.fill"
        case .marketplaceCourse: return "storefront.fill"
        case .futureEngineers: return "wrench.and.screwdriver.fill"
        case .globalClassroom: return "globe.europe.africa.fill"
        case .youngInventors: return "sparkles"
        case .inventionsService: return "hammer.fill"
        case .conference: return "calendar.badge.plus"
        case .subscription: return "star.circle.fill"
        }
    }

    /// Какие продукты открывает действующая подписка KKSU.
    var coveredBySubscription: Bool {
        self == .course || self == .futureEngineers || self == .globalClassroom
    }
}

struct Product: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var kind: ProductKind
    var priceUSD: Double
    var summary: String
    /// Связанный объект: курс, мероприятие, программа и т.п.
    var refID: UUID?
    /// Продавец (для курсов педагогов в Marketplace).
    var sellerID: UUID?
    /// Срок действия доступа в днях (подписки). nil — бессрочно.
    var durationDays: Int?
    /// Сколько детей покрывает семейная подписка (0 — индивидуальная).
    var familySeats: Int = 0
    var isActive = true

    var isFree: Bool { priceUSD <= 0 }
}

// MARK: - Промокоды

struct PromoCode: Identifiable, Codable, Hashable {
    var id = UUID()
    var code: String
    var percentOff: Double = 0
    var amountOffUSD: Double = 0
    var validUntil: Date?
    var maxUses: Int = 0            // 0 — без ограничений
    var uses: Int = 0
    var kinds: [ProductKind] = []   // пусто — для всех продуктов
    var isActive = true

    func isValid(for product: Product, now: Date = Date()) -> Bool {
        isActive && (validUntil.map { $0 >= now } ?? true) && (maxUses == 0 || uses < maxUses) &&
        (kinds.isEmpty || kinds.contains(product.kind))
    }

    func discount(on price: Double) -> Double {
        min(price, price * percentOff / 100 + amountOffUSD)
    }
}

// MARK: - Счета и платежи

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case awaitingPayment, pendingConfirmation, paid, cancelled, rejected, refundRequested, refunded
    var id: String { rawValue }
    var title: String {
        switch self {
        case .awaitingPayment: return "Ожидает оплаты"
        case .pendingConfirmation: return "Проверяется"
        case .paid: return "Оплачен"
        case .cancelled: return "Отменён"
        case .rejected: return "Платёж не найден"
        case .refundRequested: return "Запрошен возврат"
        case .refunded: return "Возвращён"
        }
    }
    var icon: String {
        switch self {
        case .awaitingPayment: return "clock"
        case .pendingConfirmation: return "hourglass"
        case .paid: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        case .rejected: return "exclamationmark.triangle.fill"
        case .refundRequested: return "arrow.uturn.backward.circle"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        }
    }
}

struct Invoice: Identifiable, Codable, Hashable {
    var id = UUID()
    var number: String
    var payerID: UUID
    /// Кому открывается доступ (для семейной подписки — несколько детей).
    var beneficiaryIDs: [UUID]
    var productID: UUID
    var productTitle: String
    var productKind: ProductKind
    /// Дополнительный объект: например, курс педагога для оплаты публикации.
    var targetID: UUID?
    var priceUSD: Double
    var discountUSD: Double = 0
    var promoCode: String?
    var currency: PayCurrency = .kzt
    var rate: Double
    var method: PaymentMethod = .kaspi
    var status: PaymentStatus = .awaitingPayment
    var createdAt = Date()
    var payerNote: String = ""
    var receipt: Attachment?
    var paidAt: Date?
    var confirmedBy: UUID?
    var refundReason: String = ""
    var refundedAt: Date?

    var totalUSD: Double { max(priceUSD - discountUSD, 0) }
    /// Код для комментария к переводу.
    var paymentCode: String { number }

    func amount(in currency: PayCurrency, settings: PaymentSettings) -> Double {
        switch currency {
        case .usd: return totalUSD
        case .kzt: return (totalUSD * settings.usdToKzt).rounded()
        case .eur: return (totalUSD * settings.usdToKzt / settings.eurToKzt * 100).rounded() / 100
        }
    }
}

// MARK: - Доступы (entitlements)

enum AccessSource: String, Codable {
    case payment, scholarship, free, subscription, bundle
    var title: String {
        switch self {
        case .payment: return "Оплата"
        case .scholarship: return "Стипендия / бесплатный доступ"
        case .free: return "Бесплатно"
        case .subscription: return "Подписка"
        case .bundle: return "Входит в пакет"
        }
    }
}

struct Entitlement: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var productID: UUID
    var source: AccessSource
    var grantedAt = Date()
    var expiresAt: Date?
    var invoiceID: UUID?
    var grantedBy: UUID?
    var note: String = ""
    var revoked = false

    func isActive(now: Date = Date()) -> Bool {
        !revoked && (expiresAt.map { $0 > now } ?? true)
    }
}

// MARK: - Teacher Marketplace

enum MarketplaceCourseStatus: String, Codable, CaseIterable {
    case draft, awaitingListingFee, published, archived
    var title: String {
        switch self {
        case .draft: return "Черновик"
        case .awaitingListingFee: return "Ожидает оплаты публикации"
        case .published: return "Опубликован"
        case .archived: return "В архиве"
        }
    }
}

struct MarketplaceCourse: Identifiable, Codable, Hashable {
    var id = UUID()
    var teacherID: UUID
    var title: String
    var summary: String
    var subject: String
    var lessons: [String]
    var priceUSD: Double
    var status: MarketplaceCourseStatus = .draft
    var createdAt = Date()
}

// MARK: - База биллинга

struct KKSUBillingDatabase: Codable {
    var settings = PaymentSettings()
    var products: [Product] = []
    var invoices: [Invoice] = []
    var entitlements: [Entitlement] = []
    var promoCodes: [PromoCode] = []
    var marketplaceCourses: [MarketplaceCourse] = []
    var invoiceCounter = 0
}

// MARK: - Демо-данные биллинга

enum KKSUBillingSeed {
    /// Ключевые продукты, на которые ссылаются модули приложения.
    enum Key {
        static let enrollment = "Статус ученика KKSU"
        static let listing = "Публикация курса в Teacher Marketplace"
        static let certification = "Сертификация преподавателя KKSU"
        static let youngInventors = "Регистрационный взнос Young Inventors 30"
    }

    static func make(db: KKSUDatabase) -> KKSUBillingDatabase {
        var billing = KKSUBillingDatabase()
        var products: [Product] = [
            Product(title: Key.enrollment, kind: .enrollment, priceUSD: 200, summary: "Зачисление в KKSU: школьная программа, расписание, домашние задания, тесты, портфолио и сопровождение на учебный год.", durationDays: 365),
            Product(title: Key.listing, kind: .marketplaceListing, priceUSD: 300, summary: "Педагог размещает собственный курс в каталоге KKSU и получает доступ к ученикам платформы."),
            Product(title: Key.certification, kind: .teacherCertification, priceUSD: 100, summary: "Итоговое тестирование и электронный сертификат преподавателя KKSU."),
            Product(title: Key.youngInventors, kind: .youngInventors, priceUSD: 25, summary: "Участие в сезоне Young Inventors 30: экспертиза жюри, выставка, сертификат участника."),
            Product(title: "Подписка KKSU — месяц", kind: .subscription, priceUSD: 15, summary: "Все образовательные курсы, Future Engineers и Global Classroom на 30 дней.", durationDays: 30),
            Product(title: "Подписка KKSU — год", kind: .subscription, priceUSD: 150, summary: "Все курсы на 12 месяцев. Выгода 2 месяца.", durationDays: 365),
            Product(title: "Семейная подписка — месяц", kind: .subscription, priceUSD: 25, summary: "До 4 детей в одном аккаунте родителя на 30 дней.", durationDays: 30, familySeats: 4),
            Product(title: "Семейная подписка — год", kind: .subscription, priceUSD: 250, summary: "До 4 детей в одном аккаунте родителя на 12 месяцев.", durationDays: 365, familySeats: 4),
            Product(title: "Консультация наставника-эксперта", kind: .inventionsService, priceUSD: 20, summary: "60 минут онлайн-консультации инженера по вашему проекту."),
            Product(title: "3D-печать прототипа", kind: .inventionsService, priceUSD: 30, summary: "Печать деталей прототипа в лаборатории KKSU (до 200 г пластика)."),
            Product(title: "Патентная консультация", kind: .inventionsService, priceUSD: 50, summary: "Проверка новизны изобретения и помощь с заявкой на патент.")
        ]
        // Курсы и программы
        let libraryPrices: [Double] = [10, 15, 12]
        for (index, item) in db.library.filter({ $0.kind == .video }).enumerated() where index < libraryPrices.count {
            products.append(Product(title: "Курс «\(item.title)»", kind: .course, priceUSD: libraryPrices[index], summary: item.summary, refID: item.id))
        }
        for (index, course) in db.teacherCourses.enumerated() {
            products.append(Product(title: course.title, kind: .teacherAcademy, priceUSD: [120, 60, 90][index % 3], summary: "\(course.hours) ч, \(course.level)", refID: course.id))
        }
        for course in db.engineeringCourses {
            // Future Engineers: вводные курсы бесплатные, остальные платные.
            let price: Double = course.level == "Начальный" ? 0 : (course.track == .mashstroy ? 50 : 35)
            products.append(Product(title: course.title, kind: .futureEngineers, priceUSD: price, summary: course.summary, refID: course.id))
        }
        for globalClass in db.globalClasses {
            products.append(Product(title: "Global Classroom: \(globalClass.title)", kind: .globalClassroom, priceUSD: 40, summary: globalClass.summary, refID: globalClass.id))
        }
        for event in db.events where event.kind == .conference {
            products.append(Product(title: "Взнос: \(event.title)", kind: .conference, priceUSD: 30, summary: "Регистрационный взнос участника конференции.", refID: event.id))
        }
        billing.products = products

        billing.promoCodes = [
            PromoCode(code: "KKSU10", percentOff: 10),
            PromoCode(code: "WELCOME", percentOff: 20, maxUses: 100, kinds: [.enrollment, .subscription]),
            PromoCode(code: "TEACHER50", amountOffUSD: 50, kinds: [.marketplaceListing, .teacherAcademy])
        ]

        // Демо: у двух учеников статус оплачен, одной ученице выдан бесплатный доступ.
        let enrollment = products[0]
        let students = db.users.filter { $0.role == .student }
        let admin = db.users.first { $0.role == .admin }
        let parent = db.users.first { $0.role == .parent }
        var counter = 0
        for (index, student) in students.enumerated() {
            if index == 0, let payer = parent {
                counter += 1
                let invoice = Invoice(number: invoiceNumber(counter), payerID: payer.id, beneficiaryIDs: [student.id], productID: enrollment.id, productTitle: enrollment.title, productKind: .enrollment, priceUSD: 200, discountUSD: 20, promoCode: "KKSU10", rate: KKSUPaymentDefaults.usdToKzt, method: .kaspi, status: .paid, createdAt: Date().addingTimeInterval(-40 * 86400), paidAt: Date().addingTimeInterval(-39 * 86400), confirmedBy: admin?.id)
                billing.invoices.append(invoice)
                billing.entitlements.append(Entitlement(userID: student.id, productID: enrollment.id, source: .payment, grantedAt: invoice.paidAt ?? Date(), expiresAt: Date().addingTimeInterval(325 * 86400), invoiceID: invoice.id))
            } else if index == 1 {
                billing.entitlements.append(Entitlement(userID: student.id, productID: enrollment.id, source: .scholarship, expiresAt: Date().addingTimeInterval(300 * 86400), grantedBy: admin?.id, note: "Грант KKSU для учеников с ООП"))
            }
        }
        if let teacher = db.users.first(where: { $0.role == .teacher }), let academy = products.first(where: { $0.kind == .teacherAcademy }) {
            counter += 1
            let invoice = Invoice(number: invoiceNumber(counter), payerID: teacher.id, beneficiaryIDs: [teacher.id], productID: academy.id, productTitle: academy.title, productKind: .teacherAcademy, priceUSD: academy.priceUSD, rate: KKSUPaymentDefaults.usdToKzt, method: .halyk, status: .paid, createdAt: Date().addingTimeInterval(-20 * 86400), paidAt: Date().addingTimeInterval(-19 * 86400), confirmedBy: admin?.id)
            billing.invoices.append(invoice)
            billing.entitlements.append(Entitlement(userID: teacher.id, productID: academy.id, source: .payment, grantedAt: invoice.paidAt ?? Date(), invoiceID: invoice.id))
            let course = MarketplaceCourse(teacherID: teacher.id, title: "Олимпиадная математика 6–8", summary: "Разбор олимпиадных задач: логика, комбинаторика, геометрия.", subject: "Математика", lessons: ["Логические задачи", "Комбинаторика", "Геометрия на клетчатой бумаге", "Разбор олимпиады"], priceUSD: 35, status: .published)
            billing.marketplaceCourses.append(course)
            billing.products.append(Product(title: course.title, kind: .marketplaceCourse, priceUSD: course.priceUSD, summary: course.summary, refID: course.id, sellerID: teacher.id))
        }
        if let student = students.last, let global = billing.products.first(where: { $0.kind == .globalClassroom }) {
            counter += 1
            billing.invoices.append(Invoice(number: invoiceNumber(counter), payerID: student.id, beneficiaryIDs: [student.id], productID: global.id, productTitle: global.title, productKind: .globalClassroom, priceUSD: global.priceUSD, rate: KKSUPaymentDefaults.usdToKzt, method: .koronaPay, status: .pendingConfirmation, createdAt: Date().addingTimeInterval(-86400), payerNote: "Перевела бабушка из Италии через Korona Pay"))
        }
        billing.invoiceCounter = counter
        return billing
    }

    static func invoiceNumber(_ counter: Int) -> String {
        "KKSU-\(Calendar.current.component(.year, from: Date()))-\(String(format: "%05d", counter))"
    }
}
