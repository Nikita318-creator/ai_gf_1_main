import ApphudSDK

final class DefaultTransactionExecutionEngine: TransactionExecuting {
    private let stateChecker: SubscriptionStateChecking
    
    init(stateChecker: SubscriptionStateChecking) {
        self.stateChecker = stateChecker
    }
    
    func executePurchase(for product: ApphudProduct, completion: @escaping (FeatureAccessResult) -> Void) {
        Task { @MainActor in
            Apphud.purchase(product) { result in
                if result.error != nil {
                    completion(.error)
                    return
                }
                
                if result.transaction != nil {
                    completion(.paid)
                } else {
                    completion(.error)
                }
            }
        }
    }
    
    func restoreEntitlements(completion: @escaping (FeatureAccessResult) -> Void) {
        Task { @MainActor in
            let restoreError = await Apphud.restorePurchases()
            if restoreError != nil {
                completion(.error)
                return
            }
            
            if self.stateChecker.isEntitlementActive {
                completion(.restoredOld)
            } else {
                completion(.error)
            }
        }
    }
}
