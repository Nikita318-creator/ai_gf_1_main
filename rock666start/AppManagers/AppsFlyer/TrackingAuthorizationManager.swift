import AdSupport
import AppTrackingTransparency

class TrackingAuthorizationManager {
    static func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                AppsFlyerService.shared.start()
            case .denied, .restricted:
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                AppsFlyerService.shared.start()
            case .notDetermined:
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
            @unknown default:
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
            }
            
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            print("[IDFA] Мой тестовый айфон: \(idfa)")
        }
    }
}
