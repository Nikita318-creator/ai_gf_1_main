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
        
        // Настройка окна
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = BasePalitColors.background
        
        // 1. Первый таб
        let firstNav = UINavigationController(rootViewController: StoryIESVC())
        firstNav.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(systemName: "flame"),
            selectedImage: UIImage(systemName: "flame.fill")
        )
        
        // 2. Второй таб
        let secondNav = UINavigationController(rootViewController: BaseGridVC())
        secondNav.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(systemName: "bolt"),
            selectedImage: UIImage(systemName: "bolt.fill")
        )
        
        // 3. 3 таб
        let thirdNav = UINavigationController(rootViewController: SettingsVC())
        thirdNav.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(systemName: "bubble"),
            selectedImage: UIImage(systemName: "bubble.fill")
        )
        
        // 3. Настройка UITabBarController
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [firstNav, secondNav, thirdNav]
        
        tabBarController.tabBar.tintColor = .systemPink
        tabBarController.tabBar.barTintColor = BasePalitColors.background
        tabBarController.tabBar.isTranslucent = false
        
        window.rootViewController = tabBarController
        
        window.makeKeyAndVisible()
        self.window = window
    }
}
