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
         
        Apphud.start(apiKey: "")
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
         
        // 1. Первый таб
        let firstNav = UINavigationController(rootViewController: HomeViewController())
        firstNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "flame"),
            selectedImage: UIImage(systemName: "flame.fill")
        )
         
        // 2. Второй таб
        let secondNav = UINavigationController(rootViewController: SecondTabVC())
        secondNav.tabBarItem = UITabBarItem(
            title: "AI Quiz",
            image: UIImage(systemName: "bolt"),
            selectedImage: UIImage(systemName: "bolt.fill")
        )
        
        // 3. 3 таб
        let thirdNav = UINavigationController(rootViewController: AIPlayVC())
        thirdNav.tabBarItem = UITabBarItem(
            title: "Play with AI",
            image: UIImage(systemName: "bubble.left.and.bubble.right.fill"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )
        
        // 3. Настройка UITabBarController
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [firstNav, secondNav, thirdNav]
        
        tabBarController.tabBar.tintColor = .systemPink
        tabBarController.tabBar.barTintColor = BasePalitColors.background
        tabBarController.tabBar.isTranslucent = false

        // Плавная анимация смены rootViewController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = tabBarController
        } completion: { _ in
//          AFManeger.requestTrackingAuthorization()
        }
    }
}
