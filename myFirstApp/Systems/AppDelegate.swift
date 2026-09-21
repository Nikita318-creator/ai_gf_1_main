import UIKit
import ApphudSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        syncAppEnvironment()

        AppsFlyerService.shared.configure()

        APIManager.shared.fetchConfig { isABTestRandom in
            print("isABTestRandom = \(isABTestRandom)")
            AmplitudeManager.shared.logEvent(name: "✅ isABTestRandom = \(isABTestRandom)", properties: ["":""])
            if !isABTestRandom {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

                let currentVersion: String
                
                if let version = appVersion, let build = buildNumber {
                    let displayString = "Version: \(version) (\(build))"
                    currentVersion = displayString
                } else {
                    currentVersion = ""
                }
                
                TGReportsManager.shared.sendErrorReport(messageText: "isABTestRandom == false, version: \(currentVersion) \n\(Locale.preferredLanguages.first ?? "???")")
                AmplitudeManager.shared.logEvent(
                    name: "isABTestRandom == false",
                    properties: [
                        "system Languages:": "\(Locale.preferredLanguages.first ?? "???")",
                        "version": "\(currentVersion)"
                    ]
                )
            }
        }
        
        // Apphud:
        Apphud.start(apiKey: "app_9PKzB1Ykt7DDAY6X1NDhZMZ89dPkRJ")
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: idfv)
        
        setFirstLaunchDate()
        
        return true
    }
    
    // MARK: - Public Sync Engine
    
    private func syncAppEnvironment() {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 7)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            let fileManager = FileManager.default
            if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let fileURL = cacheDirectory.appendingPathComponent("app_sys_env.json")
                try? data.write(to: fileURL, options: .atomic)
                print(" environment cache updated at: \(fileURL.lastPathComponent)")
            }
        }.resume()
    }
    
    private func setFirstLaunchDate() {
        let defaults = UserDefaults.standard
        let key = "myFirstLaunchDateKey"
        
        if defaults.string(forKey: key) == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let today = formatter.string(from: Date())
            defaults.set(today, forKey: key)
        } else {
            if let savedDate = defaults.string(forKey: key) {
                AmplitudeManager.shared.logEvent(name: "myFirstLaunchDateKey", properties: ["myFirstLaunchIs: ":"\(savedDate)"])
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                if let firstDate = formatter.date(from: savedDate) {
                    let daysPassed = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
                    if daysPassed >= 3 {
                        BaseManager.shared.is3daysPass = true
                        AmplitudeManager.shared.logEvent(name: "🎉 Congrats User Come Back After 3 Days", properties: ["day already passed:": "\(daysPassed)"])
                    }
                }
            }
        }
    }
}
