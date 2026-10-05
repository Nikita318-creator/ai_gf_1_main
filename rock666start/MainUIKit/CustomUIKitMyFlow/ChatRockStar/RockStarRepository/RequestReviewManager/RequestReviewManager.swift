import Foundation

final class RequestReviewManager {
    
    static let shared = RequestReviewManager()
    
    private let defaults = UserDefaults.standard

    func needShowRateUs() -> Bool {
        if let lastDate = defaults.object(forKey: "needShowRateUs") as? Date {
            let daysPassed = Date().timeIntervalSince(lastDate) / (60 * 60 * 24)
            return daysPassed >= 30
        } else {
            return true
        }
    }
    
    func markReviewRequestedNow() {
        UserDefaults.standard.set(Date(), forKey: "lastReviewRequestKey")
    }
    
    func needShowRateUsAfterTappedReactions() -> Bool {
        if defaults.bool(forKey: "needShowRateUsAfterTappedReactions") {
            return false
        } else {
            defaults.set(true, forKey: "needShowRateUsAfterTappedReactions")
            return true
        }
    }
}
