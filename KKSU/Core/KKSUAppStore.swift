//
//  KKSUAppStore.swift
//  KKSU Online
//
//  Встроенные покупки Apple (StoreKit 2).
//  По правилам App Store (Guideline 3.1.1) цифровой контент в iOS-приложении —
//  курсы, программы, статус ученика, подписки — продаётся только через App Store.
//
//  Каталог App Store:
//  • разовые покупки — расходуемые «пропуски» по ценовым ступеням ($10, $15 … $300):
//    покупка открывает доступ к конкретному курсу/программе в аккаунте KKSU;
//  • подписки — автопродлеваемые: месяц, год, семейная месяц/год.
//  Идентификаторы должны совпадать с продуктами в App Store Connect и в KKSU.storekit.
//

import Foundation
import StoreKit

enum KKSUStoreCatalog {
    static let prefix = "kz.kksu.online"
    static let unlockTiers = [10, 15, 20, 25, 30, 35, 40, 50, 60, 90, 100, 120, 150, 200, 250, 300]

    static let monthly = "\(prefix).sub.monthly"
    static let yearly = "\(prefix).sub.yearly"
    static let familyMonthly = "\(prefix).sub.family.monthly"
    static let familyYearly = "\(prefix).sub.family.yearly"
    static let subscriptionIDs = [monthly, yearly, familyMonthly, familyYearly]

    static func unlockID(tier: Int) -> String { "\(prefix).unlock.usd\(tier)" }
    static var unlockIDs: [String] { unlockTiers.map(unlockID(tier:)) }
    static var allIDs: [String] { unlockIDs + subscriptionIDs }

    /// Идентификатор продукта App Store для продукта KKSU (nil — продаётся только переводом).
    static func appStoreID(for product: Product) -> String? {
        guard product.kind.isDigital, !product.isFree else { return nil }
        if product.kind == .subscription {
            let isYear = (product.durationDays ?? 30) > 31
            if product.familySeats > 0 { return isYear ? familyYearly : familyMonthly }
            return isYear ? yearly : monthly
        }
        guard let tier = unlockTiers.first(where: { Double($0) >= product.priceUSD }) else { return nil }
        return unlockID(tier: tier)
    }
}

@MainActor
final class KKSUAppStore: ObservableObject {
    static let shared = KKSUAppStore()

    @Published private(set) var products: [String: StoreKit.Product] = [:]
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?
    private weak var store: KKSUStore?

    enum PurchaseOutcome {
        case success, pending, cancelled
    }

    private init() {}

    /// Вызывается при запуске: загружает продукты и слушает транзакции (Ask to Buy, продления, покупки с других устройств).
    func start(with store: KKSUStore) {
        self.store = store
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await StoreKit.Product.products(for: KKSUStoreCatalog.allIDs)
            products = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Нужно ли продавать этот продукт через App Store.
    func usesAppStore(_ product: Product, settings: PaymentSettings) -> Bool {
        #if os(iOS)
        return settings.useAppStoreForDigital && KKSUStoreCatalog.appStoreID(for: product) != nil
        #else
        return false
        #endif
    }

    func storeProduct(for product: Product) -> StoreKit.Product? {
        KKSUStoreCatalog.appStoreID(for: product).flatMap { products[$0] }
    }

    /// Покупка через App Store. После подтверждённой транзакции доступ открывается автоматически.
    func purchase(_ product: Product, beneficiaries: [UUID], targetID: UUID?) async throws -> PurchaseOutcome {
        guard let store, let payer = store.currentUser else { return .cancelled }
        if products.isEmpty { await loadProducts() }
        guard let storeProduct = storeProduct(for: product) else {
            throw KKSUAppStoreError.productUnavailable
        }
        // Запоминаем намерение: если покупка «отложена» (Ask to Buy), доступ откроется, когда придёт транзакция.
        let pending = store.createAppStorePending(product: product, beneficiaries: beneficiaries, targetID: targetID, storeProductID: storeProduct.id)

        let result = try await storeProduct.purchase(options: [.appAccountToken(payer.id)])
        switch result {
        case .success(let verification):
            let transaction = try checked(verification)
            store.completeAppStorePurchase(invoiceID: pending.id, transactionID: String(transaction.id), expires: transaction.expirationDate)
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            store.cancelInvoice(pending.id)
            return .cancelled
        @unknown default:
            store.cancelInvoice(pending.id)
            return .cancelled
        }
    }

    /// Восстановление покупок: синхронизирует App Store и обновляет подписки.
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
        await refreshSubscriptions()
    }

    /// Актуализирует срок действия подписок по текущим правам App Store.
    func refreshSubscriptions() async {
        guard let store else { return }
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? checked(entitlement), transaction.productType == .autoRenewable else { continue }
            store.syncAppStoreSubscription(storeProductID: transaction.productID, transactionID: String(transaction.id),
                                           userID: transaction.appAccountToken, expires: transaction.expirationDate,
                                           revoked: transaction.revocationDate != nil)
        }
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard let transaction = try? checked(update), let store else { return }
        if transaction.revocationDate != nil {
            store.revokeAppStoreTransaction(String(transaction.id))
        } else if let invoice = store.pendingAppStoreInvoice(storeProductID: transaction.productID, payerID: transaction.appAccountToken) {
            store.completeAppStorePurchase(invoiceID: invoice.id, transactionID: String(transaction.id), expires: transaction.expirationDate)
        } else if transaction.productType == .autoRenewable {
            store.syncAppStoreSubscription(storeProductID: transaction.productID, transactionID: String(transaction.id),
                                           userID: transaction.appAccountToken, expires: transaction.expirationDate, revoked: false)
        }
        await transaction.finish()
    }

    private func checked<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw KKSUAppStoreError.failedVerification
        }
    }
}

enum KKSUAppStoreError: LocalizedError {
    case productUnavailable, failedVerification

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "Покупка пока недоступна: продукт не найден в App Store. Проверьте подключение к интернету."
        case .failedVerification: return "Не удалось проверить покупку в App Store."
        }
    }
}
