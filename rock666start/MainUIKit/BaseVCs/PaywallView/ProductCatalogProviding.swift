import ApphudSDK

protocol ProductCatalogProviding: AnyObject {
    func resolveAvailableProducts() async -> [ApphudProduct]
}

protocol TransactionExecuting: AnyObject {
    func executePurchase(for product: ApphudProduct, completion: @escaping (FeatureAccessResult) -> Void)
    func restoreEntitlements(completion: @escaping (FeatureAccessResult) -> Void)
}

protocol SubscriptionStateChecking: AnyObject {
    var isEntitlementActive: Bool { get }
}
