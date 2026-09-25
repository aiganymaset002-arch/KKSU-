//
//  KKSUPayments.swift
//  KKSU Online
//
//  Экраны монетизации: платный доступ (paywall), оформление и оплата счёта,
//  инструкции по банкам и международным переводам, история платежей и чеки,
//  KKSU Marketplace, Teacher Marketplace, подписки, сертификация педагога,
//  услуги KKSU Inventions, панель выручки, подтверждение оплат, возвраты,
//  промокоды, стипендии, цены и реквизиты.
//

import SwiftUI
import Charts
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Paywall: блокировка платного контента

struct PaywallCard: View {
    @EnvironmentObject private var store: KKSUStore
    let product: Product
    var targetID: UUID?
    var message: String?
    @State private var showCheckout = false

    var body: some View {
        let open = store.openInvoice(for: product.id, payerID: store.currentUser?.id)
        KCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(KKSUTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title).font(.headline)
                    Text(message ?? "Платный контент. Доступ откроется автоматически после подтверждения оплаты.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(store.priceText(product.priceUSD)).font(.title3.bold()).foregroundStyle(.tint)
                }
            }
            if let open {
                NavigationLink { InvoiceDetailView(invoiceID: open.id) } label: {
                    Label("\(open.status.title): счёт \(open.number)", systemImage: open.status.icon)
                }
            } else if store.currentUser == nil {
                Text("Войдите в аккаунт, чтобы оплатить.").font(.caption)
            } else {
                Button { showCheckout = true } label: {
                    Label("Оплатить", systemImage: "creditcard.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showCheckout) {
            NavigationStack { CheckoutView(product: product, targetID: targetID) }
        }
    }
}

/// Показывает содержимое, только если у пользователя есть доступ к продукту.
struct PaywallGate<Content: View>: View {
    @EnvironmentObject private var store: KKSUStore
    let product: Product?
    var userID: UUID?
    var message: String?
    let content: Content

    init(product: Product?, userID: UUID? = nil, message: String? = nil, @ViewBuilder content: () -> Content) {
        self.product = product
        self.userID = userID
        self.message = message
        self.content = content()
    }

    var body: some View {
        if let product, !store.hasAccess(userID ?? store.currentUser?.id, to: product) {
            PaywallCard(product: product, message: message)
        } else {
            content
        }
    }
}

/// Требует оплаченный статус ученика KKSU (или стипендию) для школьных модулей.
struct EnrollmentGate<Content: View>: View {
    @EnvironmentObject private var store: KKSUStore
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if store.role == .student {
            PaywallGate(product: store.enrollmentProduct,
                        message: "Домашние задания, тесты и школьная программа доступны ученикам KKSU. Оформите статус ученика — или попросите администратора о стипендии.") {
                content
            }
        } else {
            content
        }
    }
}

struct PriceBadge: View {
    @EnvironmentObject private var store: KKSUStore
    let product: Product?

    var body: some View {
        if let product {
            let owned = store.hasAccess(store.currentUser?.id, to: product)
            KBadge(text: owned && !product.isFree ? "Доступ открыт" : store.priceText(product.priceUSD, showKZT: false),
                   color: product.isFree || owned ? KKSUTheme.success : KKSUTheme.accent)
        }
    }
}

// MARK: - Оформление счёта (checkout)

struct CheckoutView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let product: Product
    var targetID: UUID?

    @State private var beneficiaries: Set<UUID> = []
    @State private var promo = ""
    @State private var appliedPromo: PromoCode?
    @State private var region: PaymentRegion = .kazakhstan
    @State private var method: PaymentMethod = .kaspi
    @State private var currency: PayCurrency = .kzt
    @State private var error: String?
    @State private var createdInvoiceID: UUID?
    @State private var purchasing = false
    @State private var purchaseMessage: String?
    @ObservedObject private var appStore = KKSUAppStore.shared

    /// Цифровой контент в iOS продаётся через App Store (правила Apple 3.1.1).
    private var viaAppStore: Bool { appStore.usesAppStore(product, settings: store.billing.settings) }

    private var candidates: [KKSUUser] {
        guard let me = store.currentUser else { return [] }
        let children = store.db.users.filter { me.linkedStudentIDs.contains($0.id) }
        switch me.role {
        case .parent: return product.familySeats > 0 ? [me] + children : children
        case .admin: return store.students
        default: return [me]
        }
    }

    private var discount: Double { appliedPromo?.discount(on: product.priceUSD) ?? 0 }
    private var totalUSD: Double { max(product.priceUSD - discount, 0) }

    private func converted(_ usd: Double, to currency: PayCurrency) -> String {
        let s = store.billing.settings
        switch currency {
        case .usd: return String(format: "$%.2f", usd)
        case .kzt: return "\(Int((usd * s.usdToKzt).rounded()).formatted()) ₸"
        case .eur: return String(format: "%.2f €", usd * s.usdToKzt / s.eurToKzt)
        }
    }

    var body: some View {
        if let createdInvoiceID {
            InvoiceDetailView(invoiceID: createdInvoiceID)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        } else {
            Form {
                Section {
                    HStack {
                        Image(systemName: product.kind.icon).foregroundStyle(.tint).font(.title2)
                        VStack(alignment: .leading) {
                            Text(product.title).font(.headline)
                            Text(product.kind.title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text(product.summary).font(.callout)
                    if let days = product.durationDays { KInfoRow(label: "Срок доступа", value: "\(days) дн.") }
                }
                if candidates.count > 1 || store.role == .parent {
                    Section(product.familySeats > 0 ? "Кто получает доступ (до \(product.familySeats) детей)" : "Для кого") {
                        if candidates.isEmpty {
                            Text("К аккаунту не привязаны дети. Обратитесь к администратору.").foregroundStyle(.secondary)
                        }
                        ForEach(candidates) { user in
                            Toggle(user.fullName, isOn: Binding(
                                get: { beneficiaries.contains(user.id) },
                                set: { on in if on { beneficiaries.insert(user.id) } else { beneficiaries.remove(user.id) } }))
                        }
                    }
                }
                if viaAppStore {
                    Section {
                        HStack {
                            Image(systemName: "apple.logo").font(.title2)
                            VStack(alignment: .leading) {
                                Text("Оплата через App Store").font(.headline)
                                Text("Apple ID, Apple Pay или карта, привязанная к App Store").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            Text("Итого").bold()
                            Spacer()
                            Text(appStore.storeProduct(for: product)?.displayPrice ?? converted(product.priceUSD, to: .usd))
                                .font(.title3.bold()).foregroundStyle(.tint)
                        }
                        Text("Цена в App Store указывается в валюте вашей страны. Доступ откроется сразу после оплаты. Скидки по промокодам в App Store не применяются — используйте коды предложений Apple.")
                            .font(.caption).foregroundStyle(.secondary)
                        if let purchaseMessage {
                            Text(purchaseMessage).font(.callout).foregroundStyle(KKSUTheme.success)
                        }
                    }
                    if let error {
                        Section { Text(error).foregroundStyle(KKSUTheme.danger) }
                    }
                    Section {
                        Button {
                            Task { await buyInAppStore() }
                        } label: {
                            HStack {
                                if purchasing { SwiftUI.ProgressView() }
                                Label("Купить через App Store", systemImage: "apple.logo").frame(maxWidth: .infinity)
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(purchasing)
                        Button("Восстановить покупки") { Task { await appStore.restore() } }
                            .font(.caption)
                    }
                } else {
                    Section("Промокод") {
                        HStack {
                            TextField("Например, KKSU10", text: $promo)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                            Button("Применить") {
                                appliedPromo = store.validatePromo(promo, for: product)
                                error = appliedPromo == nil ? BillingError.invalidPromo.localizedDescription : nil
                            }
                            .disabled(promo.isEmpty)
                        }
                        if let appliedPromo {
                            Label("Скидка \(converted(discount, to: .usd)) по коду \(appliedPromo.code)", systemImage: "tag.fill")
                                .foregroundStyle(KKSUTheme.success)
                        }
                    }
                    Section("Откуда вы платите") {
                        Picker("Регион", selection: $region) {
                            ForEach(PaymentRegion.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: region) { _, newRegion in
                            method = store.billing.settings.enabledMethods.first { $0.region == newRegion } ?? method
                            currency = method.preferredCurrency
                        }
                        Picker("Способ оплаты", selection: $method) {
                            ForEach(store.billing.settings.enabledMethods.filter { $0.region == region }) { m in
                                Label(m.title, systemImage: m.icon).tag(m)
                            }
                        }
                        .onChange(of: method) { _, m in currency = m.preferredCurrency }
                        Picker("Валюта отображения", selection: $currency) {
                            ForEach(PayCurrency.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("К оплате") {
                        KInfoRow(label: "Цена", value: converted(product.priceUSD, to: .usd))
                        if discount > 0 { KInfoRow(label: "Скидка", value: "−" + converted(discount, to: .usd)) }
                        HStack {
                            Text("Итого").bold()
                            Spacer()
                            Text(converted(totalUSD, to: currency)).font(.title3.bold()).foregroundStyle(.tint)
                        }
                        Text("≈ \(converted(totalUSD, to: .usd)) · \(converted(totalUSD, to: .eur)) · \(converted(totalUSD, to: .kzt))")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Деньги зачисляются на счёт получателя KKSU в тенге. Если вы платите в долларах или евро, ваш банк или сервис перевода сконвертирует сумму автоматически по своему курсу.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let error {
                        Section { Text(error).foregroundStyle(KKSUTheme.danger) }
                    }
                    Section {
                        Button {
                            createInvoice()
                        } label: {
                            Label(totalUSD > 0 ? "Выставить счёт и перейти к оплате" : "Получить доступ бесплатно", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Оплата")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
            .onAppear {
                if beneficiaries.isEmpty {
                    if let me = store.currentUser, me.role != .parent || product.familySeats > 0 { beneficiaries.insert(me.id) }
                    if let child = candidates.first(where: { $0.role == .student }) { beneficiaries.insert(child.id) }
                }
                method = store.billing.settings.enabledMethods.first { $0.region == region } ?? .kaspi
                currency = method.preferredCurrency
            }
        }
    }

    private func buyInAppStore() async {
        purchasing = true
        defer { purchasing = false }
        let list = candidates.count > 1 || store.role == .parent ? Array(beneficiaries) : [store.currentUser?.id].compactMap { $0 }
        guard !list.isEmpty else {
            error = BillingError.noBeneficiary.localizedDescription
            return
        }
        do {
            switch try await appStore.purchase(product, beneficiaries: list, targetID: targetID) {
            case .success:
                error = nil
                purchaseMessage = "Оплачено! Доступ уже открыт."
                dismiss()
            case .pending:
                purchaseMessage = "Покупка ожидает подтверждения (например, «Попросить купить»). Доступ откроется автоматически."
            case .cancelled:
                break
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func createInvoice() {
        do {
            let list = candidates.count > 1 || store.role == .parent ? Array(beneficiaries) : [store.currentUser?.id].compactMap { $0 }
            let invoice = try store.createInvoice(product: product, beneficiaries: list, promo: appliedPromo?.code ?? "",
                                                  method: method, currency: currency, targetID: targetID)
            error = nil
            createdInvoiceID = invoice.id
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Счёт: инструкции по оплате, чек, статус

struct InvoiceDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    let invoiceID: UUID
    @State private var receipts: [Attachment] = []
    @State private var note = ""
    @State private var refundReason = ""
    @State private var pdfURL: URL?
    @State private var copied = false
    @State private var displayCurrency: PayCurrency?

    var body: some View {
        if let invoice = store.billing.invoices.first(where: { $0.id == invoiceID }) {
            let settings = store.billing.settings
            let currency = displayCurrency ?? invoice.currency
            let amount = store.amountText(invoice, currency: currency)
            KPage("Счёт \(invoice.number)") {
                KCard {
                    HStack {
                        Label(invoice.status.title, systemImage: invoice.status.icon)
                            .font(.headline)
                            .foregroundStyle(statusColor(invoice.status))
                        Spacer()
                        Text(invoice.createdAt.kksuDateTime).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(invoice.productTitle).font(.title3.bold())
                    Picker("Валюта", selection: Binding(get: { currency }, set: { displayCurrency = $0 })) {
                        ForEach(PayCurrency.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text(amount).font(.largeTitle.bold()).foregroundStyle(.tint)
                    if invoice.discountUSD > 0 {
                        Text("С учётом скидки \(String(format: "$%.2f", invoice.discountUSD))\(invoice.promoCode.map { " (\($0))" } ?? "")")
                            .font(.caption)
                    }
                    KInfoRow(label: "Плательщик", value: store.userName(invoice.payerID))
                    KInfoRow(label: "Доступ для", value: invoice.beneficiaryIDs.map { store.userName($0) }.joined(separator: ", "))
                    KInfoRow(label: "Код для комментария", value: invoice.paymentCode)
                }

                if invoice.status == .awaitingPayment || invoice.status == .rejected {
                    KCard {
                        Text("Куда платить").font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(settings.recipientPhone).font(.title2.bold().monospacedDigit())
                                Text(settings.recipientName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                copyToClipboard(settings.recipientPhone.filter { $0.isNumber || $0 == "+" })
                                copied = true
                            } label: {
                                Label(copied ? "Скопировано" : "Копировать", systemImage: copied ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("Способ: \(invoice.method.title)").font(.callout.weight(.semibold))
                        ForEach(Array(invoice.method.instructions(settings: settings, amount: amount, code: invoice.paymentCode).enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).").bold().frame(width: 22, alignment: .leading)
                                Text(step).font(.callout)
                            }
                        }
                        Text(settings.instructionsFooter).font(.caption).foregroundStyle(.secondary)
                        BankLinks(method: invoice.method)
                    }
                    KCard {
                        Text("Я оплатил(а)").font(.headline)
                        Text("Прикрепите скриншот или PDF чека — так проверка пройдёт быстрее.").font(.caption).foregroundStyle(.secondary)
                        AttachmentPicker(attachments: $receipts)
                        TextField("Комментарий (кто и откуда платил)", text: $note, axis: .vertical).textFieldStyle(.roundedBorder)
                        HStack {
                            Button("Отменить счёт", role: .destructive) { store.cancelInvoice(invoice.id) }
                            Spacer()
                            Button("Отправить на проверку") {
                                store.reportPayment(invoiceID: invoice.id, receipt: receipts.first, note: note, method: invoice.method)
                                receipts = []
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                if invoice.status == .pendingConfirmation {
                    KCard {
                        Label("Оплата проверяется администратором. Доступ откроется автоматически сразу после подтверждения.", systemImage: "hourglass")
                        if let receipt = invoice.receipt { AttachmentRow(attachment: receipt) }
                        if !invoice.payerNote.isEmpty { Text(invoice.payerNote).font(.caption) }
                    }
                }

                if invoice.status == .paid {
                    KCard {
                        Label("Оплачено \(invoice.paidAt?.kksuDateTime ?? "") · доступ открыт", systemImage: "lock.open.fill")
                            .foregroundStyle(KKSUTheme.success)
                        if store.canRequestRefund(invoice) && invoice.payerID == store.currentUser?.id {
                            DisclosureGroup("Запросить возврат") {
                                TextField("Причина возврата", text: $refundReason, axis: .vertical).textFieldStyle(.roundedBorder)
                                Button("Отправить запрос") {
                                    try? store.requestRefund(invoice.id, reason: refundReason)
                                }
                                .disabled(refundReason.isEmpty)
                            }
                            Text("Возврат возможен в течение \(settings.refundDays) дней после оплаты.").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                if invoice.status == .refundRequested || invoice.status == .refunded {
                    KCard {
                        Label(invoice.status.title, systemImage: invoice.status.icon).font(.headline)
                        if !invoice.refundReason.isEmpty { Text("Причина: \(invoice.refundReason)").font(.callout) }
                        if let date = invoice.refundedAt { Text("Возврат оформлен \(date.kksuDateTime)").font(.caption) }
                    }
                }

                if store.role == .admin {
                    AdminInvoiceActions(invoiceID: invoice.id)
                }

                HStack {
                    Button {
                        pdfURL = KKSUPDF.invoice(invoice, store: store)
                    } label: {
                        Label(invoice.status == .paid ? "Чек (PDF)" : "Счёт (PDF)", systemImage: "doc.richtext")
                    }
                    if let pdfURL {
                        ShareLink(item: pdfURL) { Label("Скачать", systemImage: "square.and.arrow.up") }
                    }
                }
            }
        } else {
            KEmptyState(text: "Счёт не найден", icon: "doc.questionmark")
        }
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

func statusColor(_ status: PaymentStatus) -> Color {
    switch status {
    case .paid: return KKSUTheme.success
    case .awaitingPayment, .pendingConfirmation, .refundRequested: return KKSUTheme.warning
    case .cancelled, .refunded: return .secondary
    case .rejected: return KKSUTheme.danger
    }
}

/// Быстрые ссылки на банки и сервисы переводов.
struct BankLinks: View {
    let method: PaymentMethod

    private var links: [(String, String)] {
        switch method {
        case .kaspi: return [("Открыть Kaspi.kz", "https://kaspi.kz")]
        case .halyk: return [("Открыть Homebank", "https://homebank.kz")]
        case .freedom: return [("Открыть Freedom Bank", "https://bankffin.kz")]
        case .jusan: return [("Открыть Jusan", "https://jusan.kz")]
        case .forte: return [("Открыть ForteBank", "https://forte.kz")]
        case .bereke: return [("Открыть Bereke Bank", "https://berekebank.kz")]
        case .bcc: return [("Открыть BCC", "https://bcc.kz")]
        case .homeCredit: return [("Открыть Home Credit", "https://homebank.kz")]
        case .otherKZBank: return []
        case .internationalCard, .koronaPay: return [("Korona Pay", "https://koronapay.com")]
        case .westernUnion: return [("Western Union", "https://www.westernunion.com")]
        case .wise: return [("Wise", "https://wise.com")]
        case .appStore: return []
        }
    }

    var body: some View {
        HStack {
            ForEach(links, id: \.1) { link in
                if let url = URL(string: link.1) {
                    Link(destination: url) { Label(link.0, systemImage: "arrow.up.right.square") }
                        .font(.callout)
                }
            }
        }
    }
}

// MARK: - История платежей (задача: история, инвойсы, статусы)

struct PaymentHistoryView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        let invoices = store.billing.invoices.filter { invoice in invoice.payerID == me || (me.map { invoice.beneficiaryIDs.contains($0) } ?? false) }
            .sorted { $0.createdAt > $1.createdAt }
        let entitlements = me.map { store.activeEntitlements(for: $0) } ?? []
        List {
            Section("Мои доступы") {
                if entitlements.isEmpty { Text("Платных доступов пока нет").foregroundStyle(.secondary) }
                ForEach(entitlements) { item in
                    HStack {
                        Image(systemName: store.product(item.productID)?.kind.icon ?? "lock.open")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(store.product(item.productID)?.title ?? "Продукт")
                            Text("\(item.source.title)\(item.expiresAt.map { " · до \($0.kksuShort)" } ?? " · бессрочно")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Счета и платежи") {
                if invoices.isEmpty { Text("Платежей пока нет").foregroundStyle(.secondary) }
                ForEach(invoices) { invoice in
                    NavigationLink { InvoiceDetailView(invoiceID: invoice.id) } label: { InvoiceRow(invoice: invoice) }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Восстановить") { Task { await KKSUAppStore.shared.restore() } }
            }
        }
        .navigationTitle("История платежей")
    }
}

struct InvoiceRow: View {
    @EnvironmentObject private var store: KKSUStore
    let invoice: Invoice

    var body: some View {
        HStack {
            Image(systemName: invoice.status.icon).foregroundStyle(statusColor(invoice.status)).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.productTitle).lineLimit(1)
                Text("\(invoice.number) · \(invoice.createdAt.kksuShort) · \(invoice.method.title)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(store.amountText(invoice, currency: .kzt)).bold()
                Text(invoice.status.title).font(.caption2).foregroundStyle(statusColor(invoice.status))
            }
        }
    }
}

// MARK: - KKSU Marketplace — каталог платных продуктов

struct MarketplaceView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var kind: ProductKind?
    @State private var query = ""
    @State private var selected: Product?

    var body: some View {
        let products = store.billing.products.filter { p in
            p.isActive && p.kind != .marketplaceListing &&
            (kind == nil || p.kind == kind) &&
            (query.isEmpty || p.title.localizedCaseInsensitiveContains(query))
        }
        KPage("KKSU Marketplace") {
            Text("Регистрация и подача заявки в KKSU — бесплатно. Платные программы и курсы открываются автоматически после подтверждения оплаты.")
                .font(.callout).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Все", selected: kind == nil) { kind = nil }
                    ForEach(ProductKind.allCases.filter { $0 != .marketplaceListing }) { item in
                        FilterChip(title: item.title, selected: kind == item) { kind = item }
                    }
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(products) { product in
                    Button { selected = product } label: { ProductCard(product: product) }
                        .buttonStyle(.plain)
                }
            }
            HStack {
                RouteTile(route: .subscriptions)
                RouteTile(route: .teacherMarketplace)
                RouteTile(route: .paymentHistory)
            }
        }
        .searchable(text: $query, prompt: "Поиск продукта")
        .sheet(item: $selected) { product in
            NavigationStack { ProductDetailView(product: product) }
        }
    }
}

struct ProductCard: View {
    @EnvironmentObject private var store: KKSUStore
    let product: Product

    var body: some View {
        KCard {
            HStack(alignment: .top) {
                Image(systemName: product.kind.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(KKSUTheme.softBlue, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.title).font(.headline).lineLimit(2)
                    Text(product.kind.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(product.summary).font(.caption).lineLimit(3)
            HStack {
                PriceBadge(product: product)
                if let seller = product.sellerID { Text("Автор: \(store.userName(seller))").font(.caption2).foregroundStyle(.secondary) }
                Spacer()
                if product.familySeats > 0 { KBadge(text: "Семейная", color: .purple) }
            }
        }
    }
}

struct ProductDetailView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let product: Product

    var body: some View {
        KPage(product.title) {
            ProductCard(product: product)
            if product.kind == .marketplaceCourse, let course = store.billing.marketplaceCourses.first(where: { $0.id == product.refID }) {
                KCard {
                    Text("Программа курса").font(.headline)
                    PaywallGate(product: product, message: "Уроки откроются после подтверждения оплаты.") {
                        ForEach(Array(course.lessons.enumerated()), id: \.offset) { index, lesson in
                            Label("\(index + 1). \(lesson)", systemImage: "play.circle")
                        }
                    }
                }
            } else if store.hasAccess(store.currentUser?.id, to: product) {
                Label(product.isFree ? "Бесплатно — доступ открыт" : "Доступ открыт", systemImage: "lock.open.fill")
                    .foregroundStyle(KKSUTheme.success)
            } else {
                PaywallCard(product: product)
            }
        }
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
    }
}

// MARK: - Подписка KKSU и семейная подписка

struct SubscriptionsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let plans = store.billing.products.filter { $0.kind == .subscription && $0.isActive }.sorted { $0.priceUSD < $1.priceUSD }
        let me = store.currentUser?.id
        KPage("Подписка KKSU") {
            if let me, let active = store.activeSubscription(for: me) {
                KCard {
                    Label("Подписка активна", systemImage: "star.circle.fill").font(.headline).foregroundStyle(KKSUTheme.success)
                    Text(store.product(active.productID)?.title ?? "")
                    if let expires = active.expiresAt { Text("Действует до \(expires.kksuShort)").font(.caption) }
                }
            }
            Text("Подписка открывает все образовательные курсы, Future Engineers и Global Classroom. Семейная подписка — до 4 детей в одном аккаунте родителя.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Восстановить покупки") { Task { await KKSUAppStore.shared.restore() } }
                Spacer()
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    Link("Управлять подписками", destination: url)
                }
            }
            .font(.callout)
            Text("Подписка продлевается автоматически, пока вы её не отмените в настройках Apple ID не позднее чем за 24 часа до конца периода.")
                .font(.caption2).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(plans) { plan in
                    KCard {
                        HStack {
                            Text(plan.title).font(.headline)
                            Spacer()
                            if plan.familySeats > 0 { Image(systemName: "figure.2.and.child.holdinghands").foregroundStyle(.purple) }
                        }
                        Text(store.priceText(plan.priceUSD)).font(.title3.bold()).foregroundStyle(.tint)
                        Text(plan.summary).font(.caption)
                        PaywallGate(product: plan) {
                            Label("Оформлена", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Teacher Marketplace: педагоги размещают свои курсы

struct TeacherMarketplaceView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showEditor = false
    @State private var selected: Product?

    var body: some View {
        let me = store.currentUser?.id
        let published = store.billing.products.filter { $0.kind == .marketplaceCourse && $0.isActive }
        let mine = store.billing.marketplaceCourses.filter { $0.teacherID == me }
        let listing = store.product(titled: KKSUBillingSeed.Key.listing)
        KPage("Teacher Marketplace") {
            Text("Педагоги KKSU и партнёров предлагают собственные курсы. Публикация курса — \(store.priceText(listing?.priceUSD ?? 300)).")
                .font(.callout).foregroundStyle(.secondary)
            if store.role == .teacher || store.role == .admin {
                KSectionHeader(title: "Мои курсы", icon: "person.crop.rectangle")
                ForEach(mine) { course in
                    KCard {
                        HStack {
                            Text(course.title).font(.headline)
                            Spacer()
                            KBadge(text: course.status.title, color: course.status == .published ? KKSUTheme.success : KKSUTheme.warning)
                        }
                        Text("\(course.subject) · \(course.lessons.count) уроков · \(store.priceText(course.priceUSD, showKZT: false))").font(.caption)
                        if course.status != .published, let listing {
                            PaywallCard(product: listing, targetID: course.id, message: "Оплатите публикацию — курс появится в каталоге сразу после подтверждения.")
                        }
                        let sales = store.paidInvoices.filter { store.product($0.productID)?.refID == course.id }
                        if course.status == .published {
                            Text("Продаж: \(sales.count) · выручка \(String(format: "$%.2f", store.revenueUSD(sales)))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                PrimaryButton(title: "Разместить свой курс", icon: "plus", style: .outlined) { showEditor = true }
            }
            KSectionHeader(title: "Курсы педагогов", icon: "storefront.fill")
            if published.isEmpty { KEmptyState(text: "Пока нет опубликованных курсов", icon: "storefront") }
            ForEach(published) { product in
                Button { selected = product } label: { ProductCard(product: product) }
                    .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showEditor) { NavigationStack { MarketplaceCourseEditorView() } }
        .sheet(item: $selected) { product in NavigationStack { ProductDetailView(product: product) } }
    }
}

struct MarketplaceCourseEditorView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subject = ""
    @State private var summary = ""
    @State private var lessons = ""
    @State private var price = 20.0

    var body: some View {
        Form {
            Section("Курс") {
                TextField("Название", text: $title)
                TextField("Предмет", text: $subject)
                TextField("Описание", text: $summary, axis: .vertical)
                TextField("Уроки (каждый с новой строки)", text: $lessons, axis: .vertical)
            }
            Section("Цена для учеников") {
                Stepper(store.priceText(price), value: $price, in: 0...500, step: 5)
            }
            Section {
                Text("После сохранения оплатите публикацию курса. Курс появится в KKSU Marketplace автоматически после подтверждения оплаты.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Новый курс")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    guard let me = store.currentUser?.id else { return }
                    let list = lessons.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    store.billing.marketplaceCourses.append(MarketplaceCourse(teacherID: me, title: title, summary: summary, subject: subject, lessons: list, priceUSD: price, status: .awaitingListingFee))
                    dismiss()
                }
                .disabled(title.isEmpty || lessons.isEmpty)
            }
        }
    }
}

// MARK: - Платная сертификация преподавателя

struct TeacherCertificationView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let product = store.product(titled: KKSUBillingSeed.Key.certification)
        let me = store.currentUser?.id
        let teacherTests = store.db.tests.filter { $0.audience == .teachers }
        let passed = store.db.attempts.contains { attempt in attempt.userID == me && attempt.passed && teacherTests.contains { $0.id == attempt.testID } }
        let certified = store.db.certificates.contains { $0.userID == me && $0.title == "Сертифицированный преподаватель KKSU" }
        KPage("Сертификация преподавателя") {
            KCard {
                Label("Сертификация преподавателя KKSU", systemImage: "rosette").font(.title3.bold()).foregroundStyle(.tint)
                Text("Отдельный тариф: итоговое тестирование по инклюзивной педагогике и электронный сертификат с кодом проверки.")
                if let product { Text(store.priceText(product.priceUSD)).font(.headline) }
            }
            PaywallGate(product: product, message: "Оплатите сертификацию, чтобы пройти итоговое тестирование.") {
                KCard {
                    Text("1. Пройдите итоговый тест").font(.headline)
                    ForEach(teacherTests) { TestCard(test: $0) }
                    Text("2. Получите сертификат").font(.headline)
                    if certified {
                        Label("Сертификат выдан", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                    } else {
                        Button("Получить сертификат") {
                            if let me { store.issueCertificate(to: me, title: "Сертифицированный преподаватель KKSU", issuer: .teacherAcademy) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!passed)
                        if !passed { Text("Кнопка станет активной после успешного теста.").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            RouteRow(route: .certificates)
        }
    }
}

// MARK: - Платные услуги KKSU Inventions

struct InventionsServicesView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let services = store.billing.products.filter { $0.kind == .inventionsService && $0.isActive }
        KPage("Услуги KKSU Inventions") {
            Text("Дополнительные платные услуги для проектов. Базовая работа над проектом с наставником — бесплатна.")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(services) { service in
                VStack(alignment: .leading, spacing: 6) {
                    ProductCard(product: service)
                    PaywallGate(product: service) {
                        Label("Услуга оплачена — наставник свяжется с вами в чате", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(KKSUTheme.success).font(.callout)
                    }
                }
            }
        }
    }
}

// MARK: - Администратор: выручка и статистика продаж

struct RevenueDashboardView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let rate = store.billing.settings.usdToKzt
        let pending = store.billing.invoices.filter { $0.status == .pendingConfirmation || $0.status == .refundRequested }
        let byKind = store.salesByKind()
        let byProduct = store.salesByProduct()
        let byTeacher = store.salesByTeacher()
        let monthly = store.monthlyRevenue()
        let byMethod = store.salesByMethod()
        KPage("Выручка KKSU") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Выручка, USD", value: String(format: "$%.0f", store.revenueUSD()), icon: "dollarsign.circle.fill", color: KKSUTheme.success)
                KStatTile(title: "Выручка, ₸", value: Int((store.revenueUSD() * rate).rounded()).formatted(), icon: "banknote.fill")
                KStatTile(title: "Оплаченных счетов", value: "\(store.paidInvoices.count)", icon: "checkmark.seal.fill", color: KKSUTheme.accent)
                KStatTile(title: "Ждут проверки", value: "\(pending.count)", icon: "hourglass", color: KKSUTheme.warning)
                KStatTile(title: "Возвращено, USD", value: String(format: "$%.0f", store.refundedUSD), icon: "arrow.uturn.backward.circle", color: KKSUTheme.danger)
                KStatTile(title: "Стипендий", value: "\(store.billing.entitlements.filter { $0.source == .scholarship && $0.isActive() }.count)", icon: "gift.fill", color: .purple)
            }
            RouteRow(route: .paymentsAdmin, subtitle: "Подтвердить оплаты, оформить возвраты")
            KCard {
                Text("Выручка по месяцам, USD").font(.headline)
                Chart(monthly, id: \.month) { item in
                    BarMark(x: .value("Месяц", item.month, unit: .month), y: .value("USD", item.usd))
                        .foregroundStyle(KKSUTheme.primary)
                }
                .frame(height: 180)
            }
            if !byKind.isEmpty {
                KCard {
                    Text("Продажи по программам").font(.headline)
                    Chart(byKind, id: \.kind) { item in
                        SectorMark(angle: .value("USD", item.usd), innerRadius: .ratio(0.55))
                            .foregroundStyle(by: .value("Программа", item.kind.title))
                    }
                    .frame(height: 220)
                    ForEach(byKind, id: \.kind) { item in
                        KInfoRow(label: item.kind.title, value: String(format: "$%.0f · %d шт.", item.usd, item.count))
                    }
                }
            }
            KCard {
                Text("Продажи по курсам и продуктам").font(.headline)
                if byProduct.isEmpty { Text("Продаж пока нет").foregroundStyle(.secondary) }
                ForEach(byProduct, id: \.title) { item in
                    KInfoRow(label: item.title, value: String(format: "$%.0f · %d шт.", item.usd, item.count))
                }
            }
            KCard {
                Text("Продажи по преподавателям").font(.headline)
                if byTeacher.isEmpty { Text("Продаж курсов педагогов пока нет").foregroundStyle(.secondary) }
                ForEach(byTeacher, id: \.teacherID) { item in
                    KInfoRow(label: store.userName(item.teacherID), value: String(format: "$%.0f · %d шт.", item.usd, item.count))
                }
            }
            if !byMethod.isEmpty {
                KCard {
                    Text("По способам оплаты").font(.headline)
                    ForEach(byMethod, id: \.method) { item in
                        KInfoRow(label: item.method.title, value: String(format: "$%.0f", item.usd))
                    }
                }
            }
            if let url = revenueCSV() {
                ShareLink(item: url) { Label("Экспорт платежей в CSV", systemImage: "tablecells") }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                RouteTile(route: .pricing)
                RouteTile(route: .promoCodes)
                RouteTile(route: .scholarships)
                RouteTile(route: .paymentSettings)
            }
        }
    }

    private func revenueCSV() -> URL? {
        var csv = "Счёт;Дата;Плательщик;Продукт;Программа;Способ;Статус;USD;KZT;Промокод\n"
        for i in store.billing.invoices.sorted(by: { $0.createdAt > $1.createdAt }) {
            csv += "\(i.number);\(i.createdAt.kksuShort);\(store.userName(i.payerID));\(i.productTitle);\(i.productKind.title);\(i.method.title);\(i.status.title);\(String(format: "%.2f", i.totalUSD));\(Int(i.totalUSD * i.rate));\(i.promoCode ?? "")\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KKSU-payments.csv")
        return (try? csv.data(using: .utf8)?.write(to: url)) != nil ? url : nil
    }
}

// MARK: - Администратор: подтверждение оплат, отмены, возвраты

struct PaymentsAdminView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var filter: PaymentStatus? = .pendingConfirmation

    var body: some View {
        let invoices = store.billing.invoices.filter { filter == nil || $0.status == filter }.sorted { $0.createdAt > $1.createdAt }
        List {
            Section {
                Picker("Статус", selection: $filter) {
                    Text("Все").tag(PaymentStatus?.none)
                    ForEach(PaymentStatus.allCases) { status in
                        Text("\(status.title) (\(store.billing.invoices.filter { $0.status == status }.count))").tag(PaymentStatus?.some(status))
                    }
                }
            } footer: {
                Text("Сверьте поступление в приложении банка (сумма и код счёта в комментарии) и подтвердите оплату — доступ откроется автоматически.")
            }
            ForEach(invoices) { invoice in
                NavigationLink { InvoiceDetailView(invoiceID: invoice.id) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        InvoiceRow(invoice: invoice)
                        Text("Плательщик: \(store.userName(invoice.payerID))\(invoice.receipt != nil ? " · чек приложен" : "")")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Платежи")
    }
}

struct AdminInvoiceActions: View {
    @EnvironmentObject private var store: KKSUStore
    let invoiceID: UUID
    @State private var reason = ""

    var body: some View {
        if let invoice = store.billing.invoices.first(where: { $0.id == invoiceID }) {
            KCard {
                Text("Действия администратора").font(.headline)
                TextField("Комментарий / причина", text: $reason).textFieldStyle(.roundedBorder)
                switch invoice.status {
                case .awaitingPayment, .pendingConfirmation, .rejected:
                    HStack {
                        Button("Платёж не найден", role: .destructive) { store.rejectPayment(invoice.id, reason: reason.isEmpty ? "поступление не найдено" : reason) }
                        Spacer()
                        Button("Подтвердить оплату") { store.confirmPayment(invoice.id) }
                            .buttonStyle(.borderedProminent)
                            .tint(KKSUTheme.success)
                    }
                case .paid, .refundRequested:
                    Button("Оформить возврат и закрыть доступ", role: .destructive) { store.refund(invoice.id, reason: reason) }
                        .buttonStyle(.bordered)
                case .cancelled, .refunded:
                    Text("Действий нет").foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Администратор: промокоды и скидки

struct PromoCodesAdminView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var code = ""
    @State private var percent = 10.0
    @State private var amount = 0.0
    @State private var maxUses = 0
    @State private var hasExpiry = false
    @State private var expiry = Date().addingTimeInterval(30 * 86400)
    @State private var kinds: Set<ProductKind> = []

    var body: some View {
        Form {
            Section("Промокоды") {
                ForEach($store.billing.promoCodes) { $promo in
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $promo.isActive) {
                            Text(promo.code).font(.headline.monospaced())
                        }
                        Text(describe(promo)).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { store.billing.promoCodes.remove(atOffsets: $0) }
            }
            Section("Новый промокод") {
                TextField("Код", text: $code)
                    .autocorrectionDisabled()
                Stepper("Скидка: \(Int(percent))%", value: $percent, in: 0...100, step: 5)
                Stepper("или фиксированная: $\(Int(amount))", value: $amount, in: 0...500, step: 5)
                Stepper(maxUses == 0 ? "Использований: без ограничений" : "Использований: \(maxUses)", value: $maxUses, in: 0...10_000, step: 10)
                Toggle("Срок действия", isOn: $hasExpiry)
                if hasExpiry { DatePicker("До", selection: $expiry, displayedComponents: .date) }
                DisclosureGroup("Для программ (пусто — для всех)") {
                    ForEach(ProductKind.allCases) { kind in
                        Toggle(kind.title, isOn: Binding(get: { kinds.contains(kind) }, set: { on in if on { kinds.insert(kind) } else { kinds.remove(kind) } }))
                    }
                }
                Button("Создать") {
                    store.billing.promoCodes.append(PromoCode(code: code.uppercased(), percentOff: percent, amountOffUSD: amount, validUntil: hasExpiry ? expiry : nil, maxUses: maxUses, kinds: Array(kinds)))
                    code = ""
                }
                .disabled(code.isEmpty || (percent == 0 && amount == 0) || store.billing.promoCodes.contains { $0.code.uppercased() == code.uppercased() })
            }
        }
        .navigationTitle("Промокоды и скидки")
    }

    private func describe(_ promo: PromoCode) -> String {
        var parts: [String] = []
        if promo.percentOff > 0 { parts.append("−\(Int(promo.percentOff))%") }
        if promo.amountOffUSD > 0 { parts.append("−$\(Int(promo.amountOffUSD))") }
        parts.append("использован \(promo.uses)\(promo.maxUses > 0 ? " из \(promo.maxUses)" : "")")
        if let until = promo.validUntil { parts.append("до \(until.kksuShort)") }
        parts.append(promo.kinds.isEmpty ? "все программы" : promo.kinds.map(\.title).joined(separator: ", "))
        return parts.joined(separator: " · ")
    }
}

// MARK: - Администратор: стипендии и бесплатный доступ

struct ScholarshipsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var studentID: UUID?
    @State private var productID: UUID?
    @State private var days = 365
    @State private var unlimited = false
    @State private var note = "Стипендия KKSU"

    var body: some View {
        let grants = store.billing.entitlements.filter { $0.source == .scholarship }.sorted { $0.grantedAt > $1.grantedAt }
        Form {
            Section("Выдать бесплатный доступ") {
                Picker("Ученик / пользователь", selection: $studentID) {
                    Text("Выберите").tag(UUID?.none)
                    ForEach(store.db.users.filter { $0.role != .admin }) { Text("\($0.fullName) (\($0.role.title))").tag(UUID?.some($0.id)) }
                }
                Picker("Программа", selection: $productID) {
                    Text("Выберите").tag(UUID?.none)
                    ForEach(store.billing.products.filter { !$0.isFree && $0.kind != .marketplaceListing }) { Text($0.title).tag(UUID?.some($0.id)) }
                }
                Toggle("Бессрочно", isOn: $unlimited)
                if !unlimited { Stepper("Срок: \(days) дн.", value: $days, in: 7...730, step: 7) }
                TextField("Основание", text: $note)
                Button("Выдать доступ") {
                    guard let studentID, let product = store.product(productID) else { return }
                    store.grantScholarship(to: studentID, product: product, days: unlimited ? nil : days, note: note)
                }
                .disabled(studentID == nil || productID == nil)
            }
            Section("Выданные стипендии") {
                if grants.isEmpty { Text("Пока нет").foregroundStyle(.secondary) }
                ForEach(grants) { grant in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(store.userName(grant.userID))
                            Text("\(store.product(grant.productID)?.title ?? "") · \(grant.note)\(grant.expiresAt.map { " · до \($0.kksuShort)" } ?? "")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if grant.isActive() {
                            Button("Отозвать", role: .destructive) { store.revokeEntitlement(grant.id) }
                                .buttonStyle(.borderless)
                        } else {
                            Text("Неактивна").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Стипендии и бесплатный доступ")
    }
}

// MARK: - Администратор: цены и продукты

struct PricingAdminView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var newTitle = ""
    @State private var newKind: ProductKind = .course
    @State private var newPrice = 10.0

    var body: some View {
        Form {
            Section {
                Text("Регистрация пользователя и подача заявки — бесплатны всегда. Цена 0 делает программу бесплатной.")
                    .font(.caption)
            }
            ForEach(ProductKind.allCases) { kind in
                let indices = store.billing.products.indices.filter { store.billing.products[$0].kind == kind }
                if !indices.isEmpty {
                    Section(kind.title) {
                        ForEach(indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(store.billing.products[index].title).lineLimit(2)
                                    Spacer()
                                    Toggle("", isOn: $store.billing.products[index].isActive).labelsHidden()
                                }
                                Stepper(store.priceText(store.billing.products[index].priceUSD),
                                        value: $store.billing.products[index].priceUSD, in: 0...5000, step: 5)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            Section("Новый продукт") {
                TextField("Название", text: $newTitle)
                Picker("Программа", selection: $newKind) {
                    ForEach(ProductKind.allCases) { Text($0.title).tag($0) }
                }
                Stepper(store.priceText(newPrice), value: $newPrice, in: 0...5000, step: 5)
                Button("Добавить") {
                    store.billing.products.append(Product(title: newTitle, kind: newKind, priceUSD: newPrice, summary: "",
                                                          durationDays: newKind == .subscription ? 30 : nil))
                    newTitle = ""
                }
                .disabled(newTitle.isEmpty)
            }
        }
        .navigationTitle("Цены и продукты")
    }
}

// MARK: - Администратор: реквизиты и курсы валют

struct PaymentSettingsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        Form {
            Section {
                TextField("Номер телефона для переводов", text: $store.billing.settings.recipientPhone)
                TextField("Имя получателя (как в банке)", text: $store.billing.settings.recipientName)
            } header: {
                Text("Получатель платежей")
            } footer: {
                Text("На этот номер переводят оплату через Kaspi, Halyk и другие банки Казахстана. Иностранные платежи через Korona Pay, Western Union и Wise зачисляются в тенге.")
            }
            Section("Курсы для пересчёта цен") {
                Stepper("1 USD = \(Int(store.billing.settings.usdToKzt)) ₸", value: $store.billing.settings.usdToKzt, in: 100...2000, step: 1)
                Stepper("1 EUR = \(Int(store.billing.settings.eurToKzt)) ₸", value: $store.billing.settings.eurToKzt, in: 100...2000, step: 1)
                Text("Цены хранятся в долларах. Банк плательщика конвертирует валюту по своему курсу.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Toggle("Цифровой контент — через App Store", isOn: $store.billing.settings.useAppStoreForDigital)
            } header: {
                Text("App Store")
            } footer: {
                Text("Apple требует продавать курсы, программы и подписки в iOS-приложении через встроенные покупки. Переводы на счёт остаются для конференций, конкурсов и очных услуг. Выключайте только для внутренних сборок.")
            }
            Section("Способы оплаты переводом") {
                ForEach(PaymentMethod.manualCases) { method in
                    Toggle(isOn: Binding(
                        get: { store.billing.settings.enabledMethods.contains(method) },
                        set: { on in
                            if on { store.billing.settings.enabledMethods.append(method) }
                            else { store.billing.settings.enabledMethods.removeAll { $0 == method } }
                        })) {
                        Label(method.title, systemImage: method.icon)
                    }
                }
            }
            Section("Правила") {
                Stepper("Возврат в течение \(store.billing.settings.refundDays) дн.", value: $store.billing.settings.refundDays, in: 0...90)
                TextField("Подсказка плательщику", text: $store.billing.settings.instructionsFooter, axis: .vertical)
            }
        }
        .navigationTitle("Настройки оплаты")
    }
}

// MARK: - PDF счёта / чека

extension KKSUPDF {
    static func invoice(_ invoice: Invoice, store: KKSUStore) -> URL? {
        let page = InvoicePDFPage(invoice: invoice, settings: store.billing.settings,
                                  payer: store.userName(invoice.payerID),
                                  beneficiaries: invoice.beneficiaryIDs.map { store.userName($0) }.joined(separator: ", "))
        return render(pages: [AnyView(page)], size: a4, fileName: "\(invoice.number).pdf")
    }
}

struct InvoicePDFPage: View {
    let invoice: Invoice
    let settings: PaymentSettings
    let payer: String
    let beneficiaries: String

    private func money(_ currency: PayCurrency) -> String {
        let value = invoice.amount(in: currency, settings: settings)
        switch currency {
        case .kzt: return "\(Int(value)) ₸"
        case .usd: return String(format: "$%.2f", value)
        case .eur: return String(format: "%.2f €", value)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("KKSU ONLINE").font(.system(size: 18, weight: .heavy)).foregroundColor(KKSUTheme.primary)
                Spacer()
                Text(invoice.status == .paid ? "ЧЕК" : "СЧЁТ НА ОПЛАТУ").font(.system(size: 18, weight: .bold))
            }
            Rectangle().fill(KKSUTheme.primary).frame(height: 2)
            Group {
                row("Номер", invoice.number)
                row("Дата", invoice.createdAt.kksuDateTime)
                row("Плательщик", payer)
                row("Доступ для", beneficiaries)
                row("Продукт", invoice.productTitle)
                row("Программа", invoice.productKind.title)
                row("Цена", String(format: "$%.2f", invoice.priceUSD))
                if invoice.discountUSD > 0 { row("Скидка", String(format: "−$%.2f %@", invoice.discountUSD, invoice.promoCode ?? "")) }
            }
            Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 1)
            row("ИТОГО", "\(money(.kzt))  (\(money(.usd)) · \(money(.eur)))").font(.system(size: 14, weight: .bold))
            row("Курс", "1 USD = \(Int(invoice.rate)) ₸")
            row("Способ оплаты", invoice.method.title)
            row("Получатель", "\(settings.recipientName), \(settings.recipientPhone)")
            row("Статус", invoice.status.title + (invoice.paidAt.map { " · \($0.kksuDateTime)" } ?? ""))
            if invoice.status == .refunded {
                row("Возврат", invoice.refundedAt?.kksuDateTime ?? "")
            }
            Text("Укажите в комментарии к переводу код \(invoice.paymentCode).").font(.system(size: 11))
            Spacer()
            Text("Документ сформирован автоматически платформой KKSU Online.").font(.system(size: 9)).foregroundColor(.gray)
        }
        .font(.system(size: 12))
        .foregroundColor(.black)
        .padding(48)
        .frame(width: KKSUPDF.a4.width, height: KKSUPDF.a4.height, alignment: .topLeading)
        .background(Color.white)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundColor(.gray).frame(width: 130, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}

// MARK: - Статус ученика KKSU (enrollment)

struct EnrollmentStatusCard: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        if let product = store.enrollmentProduct {
            if store.isEnrolled(studentID) {
                let entitlement = store.activeEntitlements(for: studentID).first { $0.productID == product.id }
                KCard {
                    Label("Статус ученика KKSU активен", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(KKSUTheme.success)
                    if let entitlement {
                        Text("\(entitlement.source.title)\(entitlement.expiresAt.map { " · до \($0.kksuShort)" } ?? "")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                PaywallCard(product: product, message: "Регистрация и заявка — бесплатно. Чтобы стать учеником KKSU и открыть школьную программу, оплатите статус ученика или получите стипендию.")
            }
        }
    }
}
