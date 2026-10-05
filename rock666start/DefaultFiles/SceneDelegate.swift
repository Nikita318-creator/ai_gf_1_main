import UIKit
import ApphudSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let _ = AppHudAdapter.shared
        
        Task {
            let _ = await BackendService.shared.fetchBaseData()
        }
        
        Apphud.start(apiKey: "app_9PKzB1Ykt7DDAY6X1NDhZMZ89dPkRJ")
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: idfv)
        
        // Настройка окна
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = BasePalitColors.background
        
        // Запускаем со сплеш скрина
        let splashVC = SplashViewController()
        splashVC.onFinish = { [weak self] in
            self?.showMainFlow()
        }
        
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
        self.window = window
    }

    private func showMainFlow() {
        guard let window = window else { return }
        
        let mainVC = UINavigationController(rootViewController: HomeViewController())
        
        // Плавная анимация смены rootViewController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = mainVC
        } completion: { _ in
            // Запрос ATT делаем строго после того, как сплеш скрылся и показался главный экран
//            AFManeger.requestTrackingAuthorization()
        }
    }
}
