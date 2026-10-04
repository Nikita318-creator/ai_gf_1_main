import UIKit
import ApphudSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppsFlyerService.shared.configure()

        APIManager.shared.fetchConfig { isABTestRandom in

        }
        
        // Apphud:
        Apphud.start(apiKey: "app_9PKzB1Ykt7DDAY6X1NDhZMZ89dPkRJ")
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: idfv)
                
        return true
    }
}
