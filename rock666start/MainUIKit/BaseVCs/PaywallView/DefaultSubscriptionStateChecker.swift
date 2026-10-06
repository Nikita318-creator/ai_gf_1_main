import ApphudSDK

@MainActor
final class DefaultSubscriptionStateChecker: SubscriptionStateChecking {
    
    var isEntitlementActive: Bool {
//        #if DEBUG
//        return true
//        #else
        return evaluateActiveEntitlement()
//        #endif
    }
    
    private func evaluateActiveEntitlement() -> Bool {
        let hasDirectActive = Apphud.hasActiveSubscription()
        let hasActiveList = (Apphud.subscriptions()?.isEmpty == false)
        return hasDirectActive || hasActiveList
    }
}
