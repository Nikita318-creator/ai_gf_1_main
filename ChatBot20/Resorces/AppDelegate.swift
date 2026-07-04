//
//  AppDelegate.swift
//  ChatBot20
//
//  Created by Mikita on 4.06.25.
//

import UIKit
import ApphudSDK
//import OneSignalFramework
import Amplitude

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ConfigService.shared.fetchConfig { check in
            print("✅ mode = \(check)")
//            CoinsService.shared.addCoins(2000)
            AnalyticService.shared.logEvent(name: "✅ mode = \(check)", properties: ["":""])
            if check {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

                let currentVersion: String
                
                if let version = appVersion, let build = buildNumber {
                    let displayString = "Version: \(version) (\(build))"
                    currentVersion = displayString
                } else {
                    currentVersion = ""
                }
                
                WebHookAnaliticksService.shared.sendErrorReport(messageText: "Opened for testAB currentVersion: \(currentVersion) \n\(Locale.preferredLanguages.first ?? "???")")
                AnalyticService.shared.logEvent(
                    name: "Open for testA",
                    properties: [
                        "preferredLanguages:":"\(Locale.preferredLanguages.first ?? "???")",
                        "currentVersion": "\(currentVersion)"
                    ]
                )
            }
            MainHelper.shared.isMode = check
        }
        
        // Apphud:
        Apphud.start(apiKey: "app_G7PPfRnsi4kqhQSxNrxiCuceorQZqo")
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: idfv)
        
        // Amplitude:
        let amp = Amplitude.instance()
        amp.initializeApiKey("2ffefeb42183d15261064c6a45b12fb6")
        amp.setServerZone(.EU)
        amp.trackingSessionEvents = true
        
        setFirstLaunchDate()

        // OneSignal:
//        OneSignal.initialize("8a4df324-463e-472b-b419-9605bd21f053", withLaunchOptions: launchOptions)
        
        return true
    }
    
    private func setFirstLaunchDate() {
        let defaults = UserDefaults.standard
        let key = "firstLaunchDate"
        
        if defaults.string(forKey: key) == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let today = formatter.string(from: Date())
            defaults.set(today, forKey: key)
            print("🔹 First launch date saved: \(today)")
        } else {
            if let savedDate = defaults.string(forKey: key) {
                AnalyticService.shared.logEvent(name: "FirstLaunchDate", properties: ["FirstLaunchDate: ":"\(savedDate)"])
                print("🔹 Already have first launch date: \(savedDate)")
                
                // ✅ Проверка на >=3 дня
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                if let firstDate = formatter.date(from: savedDate) {
                    let daysPassed = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
                    if daysPassed >= 3 {
                        MainHelper.shared.is3daysPass = true
                        AnalyticService.shared.logEvent(name: "🎉 UserReturnedAfter3Days", properties: ["daysPassed: ": "\(daysPassed)"])
                        print("🎉 User returned after \(daysPassed) days since first login")
                    }
                }
            }
        }
    }
}

