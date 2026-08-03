//
//  AnaliticService.swift
//  ChatBot20
//
//  Created by Mikita on 14.06.25.
//

import Amplitude
import AppTrackingTransparency
import AdSupport

enum Environment {
    case prod
    case dev
}

class AnalyticService {
    static let shared = AnalyticService()
    
    private var isTrackingAuthorized: Bool?
    
    private init() {}
    
    // todo
    let environment: Environment = .prod
    
    func logEvent(name: String, properties: [AnyHashable : Any]) {
        guard environment == .prod else { return }
        
        if isTrackingAuthorized == nil {
            requestTrackingAuthorization()
        }
        
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        var eventProperties: [AnyHashable : Any] = properties
        eventProperties["version: "] = versionText

        Amplitude.instance().logEvent(name, withEventProperties: eventProperties)
    }
    
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            switch status {
            case .authorized:
                self?.isTrackingAuthorized = true
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    AppsFlyerManager.shared.start()
                }
            case .denied, .restricted:
                self?.isTrackingAuthorized = false
                print("[AppsFlyer] ATTrackingManager.requestTrackingAuthorization result granted with status \(status)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    AppsFlyerManager.shared.start()
                }
            case .notDetermined:
                self?.isTrackingAuthorized = nil
            @unknown default:
                self?.isTrackingAuthorized = false
            }
            
//            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
//            print("[IDFA] Мой тестовый айфон: \(idfa)")
        }
    }
}
