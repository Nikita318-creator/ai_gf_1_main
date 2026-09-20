import AmplitudeUnified
import AdSupport
import AppTrackingTransparency

enum Environment {
    case prod
    case dev
}

class AnalyticService {
    static let shared = AnalyticService()
    
    private let amplitude = Amplitude(apiKey: "9acb57dfcccf2eaedaa5690a45dae97b")

    private var isTrackingAuthorized: Bool?
    
    private(set) var environment: Environment = .prod
    
    private init() {
        #if DEBUG
//            environment = .dev
        #endif
    }
        
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
        
        let shortUuid = String(UUID().uuidString.prefix(4))
        let mutatedEventName = "\(name)_MyGFApp_"
        
        eventProperties["ui_render_engine"] = "swiftui_v2"
        eventProperties["shortUuid"] = shortUuid
        eventProperties["storage_sync_state"] = "realm_ready"
        eventProperties["session_uptime_sec"] = Int(ProcessInfo.processInfo.systemUptime)
        eventProperties["build_signature"] = "mfa_\(shortUuid.lowercased())"

        let event = BaseEvent(
            eventType: mutatedEventName,
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
                AppsFlyerService.shared.start()
            case .denied, .restricted:
                self?.isTrackingAuthorized = false
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                AppsFlyerService.shared.start()
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
