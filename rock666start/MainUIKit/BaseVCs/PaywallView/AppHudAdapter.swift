import Foundation
import UIKit
import ApphudSDK

final class AppHudAdapter: NSObject {
    
    // MARK: - Singleton
    
    static let shared = AppHudAdapter()
    
    // MARK: - Private Dependencies
    
    private let catalogResolver: ProductCatalogProviding
    private let transactionEngine: TransactionExecuting
    private let stateChecker: SubscriptionStateChecking
    
    // MARK: - Internal State
    
    private(set) var cachedCatalogProducts: [ApphudProduct] = []
    var pendingCompletionHandler: ((FeatureAccessResult) -> Void)?
    
    var hasActiveSubscription: Bool {
        return true // test111
//        return stateChecker.isEntitlementActive
    }
    
    // MARK: - Initialization
    
    private init(
        catalogResolver: ProductCatalogProviding = DefaultProductCatalogResolver(),
        transactionEngine: TransactionExecuting? = nil,
        stateChecker: SubscriptionStateChecking = DefaultSubscriptionStateChecker()
    ) {
        self.catalogResolver = catalogResolver
        self.stateChecker = stateChecker
        self.transactionEngine = transactionEngine ?? DefaultTransactionExecutionEngine(stateChecker: stateChecker)
        
        super.init()
        syncCatalogData()
    }
    
    // MARK: - Private Catalog Sync
    
    private func syncCatalogData() {
        Task { [weak self] in
            guard let self = self else { return }
            let resolvedProducts = await self.catalogResolver.resolveAvailableProducts()
            await MainActor.run {
                self.cachedCatalogProducts = resolvedProducts
            }
        }
    }
    
    // MARK: - Public Interface
    
    func getProducts() -> [ApphudProduct] {
        return cachedCatalogProducts
    }
    
    func purchase(productId: String, closure: @escaping (FeatureAccessResult) -> Void) {
        self.pendingCompletionHandler = closure
        
        guard let matchingProduct = cachedCatalogProducts.first(where: { $0.productId == productId }) else {
            closure(.error)
            return
        }
        
        transactionEngine.executePurchase(for: matchingProduct) { [weak self] status in
            self?.pendingCompletionHandler?(status)
        }
    }
    
    func restorePurchases(closure: @escaping (FeatureAccessResult) -> Void) {
        transactionEngine.restoreEntitlements(completion: closure)
    }
}
