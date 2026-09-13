import AmplitudeUnified
import AdSupport
import AppTrackingTransparency

enum Environment {
    case prod
    case dev
}

class AnalyticService {
    static let shared = AnalyticService()
    
    let amplitude = Amplitude(apiKey: "e95b8d4c4a01c0c65bdcd38915b43e22", serverZone: .EU)

    private var isTrackingAuthorized: Bool?

    private init() {}
    
    let environment: Environment = .dev
    
    func logEvent(name: String, properties: [AnyHashable : Any]) {
        if isTrackingAuthorized == nil {
            requestTrackingAuthorization()
        }
        
        guard environment == .prod else { return }
        
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        var eventProperties = properties.reduce(into: [String: Any]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = pair.value
            } else {
                result["\(pair.key)"] = pair.value
            }
        }
        
        eventProperties["app_version"] = versionText

        let event = BaseEvent(
            eventType: name,
            eventProperties: eventProperties,
            userProperties: nil
        )
        
        amplitude.track(event: event)
    }
    
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            switch status {
            case .authorized:
                self?.isTrackingAuthorized = true
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                AppsFlyerManager.shared.start()
            case .denied, .restricted:
                self?.isTrackingAuthorized = false
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                AppsFlyerManager.shared.start()
            case .notDetermined:
                self?.isTrackingAuthorized = nil
            @unknown default:
                self?.isTrackingAuthorized = false
            }
            
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            print("[IDFA] Мой тестовый айфон: \(idfa)")
        }
    }
}
