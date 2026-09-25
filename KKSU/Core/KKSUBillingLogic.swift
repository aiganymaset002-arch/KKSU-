//
//  KKSUBillingLogic.swift
//  KKSU Online
//
//  Бизнес-логика оплаты: выставление счёта, промокоды, подтверждение оплаты
//  с автоматическим открытием доступа, отмены, возвраты, стипендии,
//  проверка доступа к платному контенту, выручка и статистика продаж.
//

import Foundation

enum BillingError: LocalizedError {
    case invalidPromo, alreadyOwned, noBeneficiary, tooManyChildren(Int), refundExpired

    var errorDescription: String? {
        switch self {
        case .invalidPromo: return "Промокод недействителен или не подходит для этого продукта."
        case .alreadyOwned: return "Доступ уже открыт."
        case .noBeneficiary: return "Выберите, для кого оформляется оплата."
        case .tooManyChildren(let seats): return "Семейная подписка покрывает не более \(seats) детей."
        case .refundExpired: return "Срок запроса возврата истёк."
        }
    }
}

extension KKSUStore {

    // MARK: - Поиск продуктов

    func product(_ id: UUID?) -> Product? {
        guard let id else { return nil }
        return billing.products.first { $0.id == id }
    }

    /// Платный продукт, привязанный к курсу, мероприятию, программе и т.п.
    func product(forRef refID: UUID) -> Product? {
        billing.products.first { $0.refID == refID && $0.isActive }
    }

    func product(titled title: String) -> Product? {
        billing.products.first { $0.title == title && $0.isActive }
    }

    var enrollmentProduct: Product? { product(titled: KKSUBillingSeed.Key.enrollment) }

    // MARK: - Форматирование цен

    func priceText(_ usd: Double, showKZT: Bool = true) -> String {
        guard usd > 0 else { return "Бесплатно" }
        let usdText = usd.rounded() == usd ? "$\(Int(usd))" : String(format: "$%.2f", usd)
        guard showKZT else { return usdText }
        let kzt = Int((usd * billing.settings.usdToKzt).rounded())
        return "\(usdText) ≈ \(kzt.formatted()) ₸"
    }

    func amountText(_ invoice: Invoice, currency: PayCurrency? = nil) -> String {
        let cur = currency ?? invoice.currency
        let value = invoice.amount(in: cur, settings: billing.settings)
        switch cur {
        case .kzt: return "\(Int(value).formatted()) ₸"
        case .usd: return String(format: "$%.2f", value)
        case .eur: return String(format: "%.2f €", value)
        }
    }

    // MARK: - Доступ к платному контенту (блокировка до подтверждения оплаты)

    func activeEntitlements(for userID: UUID) -> [Entitlement] {
        billing.entitlements.filter { $0.userID == userID && $0.isActive() }
    }

    func activeSubscription(for userID: UUID) -> Entitlement? {
        activeEntitlements(for: userID).first { product($0.productID)?.kind == .subscription }
    }

    /// Есть ли у пользователя доступ к продукту: бесплатный продукт, оплата, стипендия или подписка.
    func hasAccess(_ userID: UUID?, to product: Product?) -> Bool {
        guard let product else { return true }
        if product.isFree { return true }
        guard let userID else { return false }
        if user(userID)?.role == .admin { return true }
        if product.sellerID == userID { return true }
        if activeEntitlements(for: userID).contains(where: { $0.productID == product.id }) { return true }
        if product.kind.coveredBySubscription, activeSubscription(for: userID) != nil { return true }
        return false
    }

    /// Проверка доступа к объекту (курсу, мероприятию…) по его id.
    func hasAccess(_ userID: UUID?, toRef refID: UUID) -> Bool {
        hasAccess(userID, to: product(forRef: refID))
    }

    func isEnrolled(_ studentID: UUID?) -> Bool {
        hasAccess(studentID, to: enrollmentProduct)
    }

    /// Счёт, ожидающий оплаты или проверки по этому продукту.
    func openInvoice(for productID: UUID, payerID: UUID?) -> Invoice? {
        billing.invoices.last { $0.productID == productID && $0.payerID == payerID && ($0.status == .awaitingPayment || $0.status == .pendingConfirmation) }
    }

    // MARK: - Промокоды

    func validatePromo(_ code: String, for product: Product) -> PromoCode? {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        guard !normalized.isEmpty else { return nil }
        return billing.promoCodes.first { $0.code.uppercased() == normalized && $0.isValid(for: product) }
    }

    // MARK: - Выставление счёта

    @discardableResult
    func createInvoice(product: Product, beneficiaries: [UUID], promo: String, method: PaymentMethod, currency: PayCurrency, targetID: UUID? = nil, note: String = "") throws -> Invoice {
        guard let payer = currentUser else { throw BillingError.noBeneficiary }
        guard !beneficiaries.isEmpty else { throw BillingError.noBeneficiary }
        if product.familySeats > 0 {
            let children = beneficiaries.filter { $0 != payer.id }
            if children.count > product.familySeats { throw BillingError.tooManyChildren(product.familySeats) }
        }
        if product.kind != .marketplaceListing, product.durationDays == nil,
           beneficiaries.allSatisfy({ hasAccess($0, to: product) }) {
            throw BillingError.alreadyOwned
        }
        var discount = 0.0
        var promoCode: String?
        if !promo.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let code = validatePromo(promo, for: product) else { throw BillingError.invalidPromo }
            discount = code.discount(on: product.priceUSD)
            promoCode = code.code
        }
        billing.invoiceCounter += 1
        var invoice = Invoice(number: KKSUBillingSeed.invoiceNumber(billing.invoiceCounter), payerID: payer.id, beneficiaryIDs: beneficiaries,
                              productID: product.id, productTitle: product.title, productKind: product.kind, targetID: targetID,
                              priceUSD: product.priceUSD, discountUSD: discount, promoCode: promoCode, currency: currency,
                              rate: billing.settings.usdToKzt, method: method, payerNote: note)
        // Полная скидка (100% промокод) — доступ открывается сразу.
        if invoice.totalUSD <= 0 {
            invoice.status = .paid
            invoice.paidAt = Date()
            billing.invoices.append(invoice)
            if let code = promoCode { incrementPromo(code) }
            fulfill(invoice)
            return invoice
        }
        billing.invoices.append(invoice)
        log(payer.id, "Выставлен счёт", details: "\(invoice.number): \(product.title)", icon: "doc.text")
        return invoice
    }

    private func incrementPromo(_ code: String) {
        if let index = billing.promoCodes.firstIndex(where: { $0.code == code }) {
            billing.promoCodes[index].uses += 1
        }
    }

    /// Плательщик сообщает об оплате и прикладывает чек.
    func reportPayment(invoiceID: UUID, receipt: Attachment?, note: String, method: PaymentMethod) {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }) else { return }
        billing.invoices[index].status = .pendingConfirmation
        billing.invoices[index].receipt = receipt
        billing.invoices[index].method = method
        if !note.isEmpty { billing.invoices[index].payerNote = note }
        let invoice = billing.invoices[index]
        for admin in users(with: .admin) {
            notify(admin.id, "Поступила оплата на проверку", "\(invoice.number) · \(amountText(invoice)) · \(invoice.method.title)", kind: .system)
        }
        notify(invoice.payerID, "Оплата отправлена на проверку", "Счёт \(invoice.number). Доступ откроется после подтверждения.", kind: .info)
    }

    func cancelInvoice(_ invoiceID: UUID) {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }),
              billing.invoices[index].status == .awaitingPayment || billing.invoices[index].status == .pendingConfirmation else { return }
        billing.invoices[index].status = .cancelled
        log(billing.invoices[index].payerID, "Счёт отменён", details: billing.invoices[index].number, icon: "xmark.circle")
    }

    // MARK: - Подтверждение оплаты → автоматическое открытие доступа

    func confirmPayment(_ invoiceID: UUID) {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }),
              billing.invoices[index].status != .paid, billing.invoices[index].status != .refunded else { return }
        billing.invoices[index].status = .paid
        billing.invoices[index].paidAt = Date()
        billing.invoices[index].confirmedBy = currentUser?.id
        let invoice = billing.invoices[index]
        if let code = invoice.promoCode { incrementPromo(code) }
        fulfill(invoice)
    }

    func rejectPayment(_ invoiceID: UUID, reason: String) {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }) else { return }
        billing.invoices[index].status = .rejected
        let invoice = billing.invoices[index]
        notify(invoice.payerID, "Платёж не найден", "Счёт \(invoice.number): \(reason). Напишите администратору в чат.", kind: .system)
    }

    /// Выдаёт доступ по оплаченному счёту и выполняет действие продукта.
    private func fulfill(_ invoice: Invoice) {
        guard let product = self.product(invoice.productID) else { return }
        let expires = product.durationDays.map { Date().addingTimeInterval(TimeInterval($0 * 86400)) }
        for userID in invoice.beneficiaryIDs {
            billing.entitlements.append(Entitlement(userID: userID, productID: product.id, source: product.kind == .subscription ? .subscription : .payment,
                                                    expiresAt: expires, invoiceID: invoice.id))
            notify(userID, "Доступ открыт", "«\(product.title)» — оплата подтверждена.", kind: .info)
            log(userID, "Открыт доступ после оплаты", details: product.title, icon: "lock.open.fill")
        }
        if invoice.payerID != invoice.beneficiaryIDs.first {
            notify(invoice.payerID, "Оплата подтверждена", "Счёт \(invoice.number): \(product.title)", kind: .info)
        }
        switch product.kind {
        case .marketplaceListing:
            if let courseID = invoice.targetID, let cIndex = billing.marketplaceCourses.firstIndex(where: { $0.id == courseID }) {
                billing.marketplaceCourses[cIndex].status = .published
                let course = billing.marketplaceCourses[cIndex]
                if !billing.products.contains(where: { $0.refID == course.id }) {
                    billing.products.append(Product(title: course.title, kind: .marketplaceCourse, priceUSD: course.priceUSD, summary: course.summary, refID: course.id, sellerID: course.teacherID))
                }
                notify(course.teacherID, "Курс опубликован в Marketplace", course.title, kind: .info)
            }
        case .enrollment:
            for userID in invoice.beneficiaryIDs where profile(for: userID) == nil && user(userID)?.role == .student {
                db.studentProfiles.append(StudentProfile(userID: userID))
            }
        case .globalClassroom:
            if let refID = product.refID, let gIndex = db.globalClasses.firstIndex(where: { $0.id == refID }) {
                for userID in invoice.beneficiaryIDs where !db.globalClasses[gIndex].participantIDs.contains(userID) {
                    db.globalClasses[gIndex].participantIDs.append(userID)
                }
            }
        case .futureEngineers:
            if let refID = product.refID, let eIndex = db.engineeringCourses.firstIndex(where: { $0.id == refID }) {
                for userID in invoice.beneficiaryIDs where !db.engineeringCourses[eIndex].enrolledIDs.contains(userID) {
                    db.engineeringCourses[eIndex].enrolledIDs.append(userID)
                }
            }
        case .teacherAcademy:
            if let refID = product.refID, let tIndex = db.teacherCourses.firstIndex(where: { $0.id == refID }) {
                for userID in invoice.beneficiaryIDs where !db.teacherCourses[tIndex].enrolledIDs.contains(userID) {
                    db.teacherCourses[tIndex].enrolledIDs.append(userID)
                }
            }
        default:
            break
        }
    }

    // MARK: - Возвраты и отмены

    func canRequestRefund(_ invoice: Invoice) -> Bool {
        guard invoice.status == .paid, let paidAt = invoice.paidAt else { return false }
        return Date().timeIntervalSince(paidAt) <= TimeInterval(billing.settings.refundDays * 86400)
    }

    func requestRefund(_ invoiceID: UUID, reason: String) throws {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }) else { return }
        guard canRequestRefund(billing.invoices[index]) else { throw BillingError.refundExpired }
        billing.invoices[index].status = .refundRequested
        billing.invoices[index].refundReason = reason
        let invoice = billing.invoices[index]
        for admin in users(with: .admin) {
            notify(admin.id, "Запрос на возврат", "\(invoice.number) · \(amountText(invoice)): \(reason)", kind: .system)
        }
    }

    /// Администратор оформляет возврат: доступ закрывается, деньги возвращаются тем же способом.
    func refund(_ invoiceID: UUID, reason: String) {
        guard let index = billing.invoices.firstIndex(where: { $0.id == invoiceID }) else { return }
        billing.invoices[index].status = .refunded
        billing.invoices[index].refundedAt = Date()
        if !reason.isEmpty { billing.invoices[index].refundReason = reason }
        for eIndex in billing.entitlements.indices where billing.entitlements[eIndex].invoiceID == invoiceID {
            billing.entitlements[eIndex].revoked = true
        }
        let invoice = billing.invoices[index]
        notify(invoice.payerID, "Возврат оформлен", "\(invoice.number): \(amountText(invoice)) будет возвращено на \(invoice.method.title).", kind: .info)
    }

    // MARK: - Стипендии и бесплатный доступ

    func grantScholarship(to userID: UUID, product: Product, days: Int?, note: String) {
        billing.entitlements.append(Entitlement(userID: userID, productID: product.id, source: .scholarship,
                                                expiresAt: days.map { Date().addingTimeInterval(TimeInterval($0 * 86400)) },
                                                grantedBy: currentUser?.id, note: note))
        notify(userID, "Вам выдан бесплатный доступ", "«\(product.title)». \(note)", kind: .info)
        log(userID, "Стипендия / бесплатный доступ", details: product.title, icon: "gift.fill")
    }

    func revokeEntitlement(_ id: UUID) {
        if let index = billing.entitlements.firstIndex(where: { $0.id == id }) {
            billing.entitlements[index].revoked = true
        }
    }

    // MARK: - Выручка и статистика

    var paidInvoices: [Invoice] { billing.invoices.filter { $0.status == .paid } }

    func revenueUSD(_ invoices: [Invoice]? = nil) -> Double {
        (invoices ?? paidInvoices).reduce(0) { $0 + $1.totalUSD }
    }

    var refundedUSD: Double {
        billing.invoices.filter { $0.status == .refunded }.reduce(0) { $0 + $1.totalUSD }
    }

    func salesByKind() -> [(kind: ProductKind, usd: Double, count: Int)] {
        ProductKind.allCases.compactMap { kind -> (kind: ProductKind, usd: Double, count: Int)? in
            let items = paidInvoices.filter { $0.productKind == kind }
            return items.isEmpty ? nil : (kind, revenueUSD(items), items.count)
        }
        .sorted { $0.usd > $1.usd }
    }

    func salesByProduct() -> [(title: String, usd: Double, count: Int)] {
        Dictionary(grouping: paidInvoices, by: \.productTitle)
            .map { (title: $0.key, usd: revenueUSD($0.value), count: $0.value.count) }
            .sorted { $0.usd > $1.usd }
    }

    /// Продажи по преподавателям: курсы педагогов в Marketplace.
    func salesByTeacher() -> [(teacherID: UUID, usd: Double, count: Int)] {
        var result: [UUID: (Double, Int)] = [:]
        for invoice in paidInvoices {
            guard let seller = product(invoice.productID)?.sellerID else { continue }
            let current = result[seller] ?? (0, 0)
            result[seller] = (current.0 + invoice.totalUSD, current.1 + 1)
        }
        return result.map { (teacherID: $0.key, usd: $0.value.0, count: $0.value.1) }.sorted { $0.usd > $1.usd }
    }

    func monthlyRevenue(months: Int = 6) -> [(month: Date, usd: Double)] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return (0..<months).reversed().compactMap { offset -> (month: Date, usd: Double)? in
            guard let month = cal.date(byAdding: .month, value: -offset, to: start),
                  let next = cal.date(byAdding: .month, value: 1, to: month) else { return nil }
            let items = paidInvoices.filter { ($0.paidAt ?? $0.createdAt) >= month && ($0.paidAt ?? $0.createdAt) < next }
            return (month, revenueUSD(items))
        }
    }

    func salesByMethod() -> [(method: PaymentMethod, usd: Double)] {
        PaymentMethod.allCases.compactMap { method -> (method: PaymentMethod, usd: Double)? in
            let items = paidInvoices.filter { $0.method == method }
            return items.isEmpty ? nil : (method, revenueUSD(items))
        }
    }
}
