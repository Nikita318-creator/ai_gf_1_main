import Foundation

final class RequestReviewManager {
    
    static let shared = RequestReviewManager()
    
    func shouldRequestReview() -> Bool {
        let defaults = UserDefaults.standard
        
        if let lastDate = defaults.object(forKey: "lastReviewRequestKey") as? Date {
            let daysPassed = Date().timeIntervalSince(lastDate) / (60 * 60 * 24)
            return daysPassed >= 30
        } else {
            return true
        }
    }
    
    func markReviewRequestedNow() {
        UserDefaults.standard.set(Date(), forKey: "lastReviewRequestKey")
    }
    
    func shouldRequestReviewAfterLikeTapped() -> Bool {
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: "requestedReviewAfterLikeTappedKey") {
            return false
        } else {
            defaults.set(true, forKey: "requestedReviewAfterLikeTappedKey")
            return true
        }
    }
}
