
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // 1. Выносим ссылки на уровне класса, чтобы они были доступны во всех методах
    private let tabBarController = UITabBarController()
    
    private var rootNavController: UINavigationController!
    private var dashbordNavController: UINavigationController!
    private var groupChatsNavController: UINavigationController!
    private var feedNavController: UINavigationController!
    private var searchNavController: UINavigationController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            AppsFlyerManager.shared.configure()
            let _ = AppDialogueConfigManager.shared.fetchSystemDialogueFallback()
            let _ = AnalyticService.shared
            let _ = NetworkMonitor.shared
            let _ = BaseManager.shared
            let _ = IAPService.shared
            let _ = AnalyticService.shared
            let _ = GiftRealmPhotoService.shared
            let _ = GiftsPhotoService.shared
            let _ = GEOService.shared
            
            if let urlContext = connectionOptions.urlContexts.first {
                self.handleDeepLink(url: urlContext.url)
            }
            
            self.setupMainInterface(window: window)
        }
        
        window.makeKeyAndVisible()
        self.window = window
    }

    private func setupMainInterface(window: UIWindow) {
        // Настройка UITabBarAppearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)]

        tabBarController.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        // 2. Инициализируем свойства класса вместо локальных переменных
        rootNavController = UINavigationController(rootViewController: RootVC())
        dashbordNavController = UINavigationController(rootViewController: ExploreVC())
        groupChatsNavController = UINavigationController(rootViewController: GroupChatListVC())
        feedNavController = UINavigationController(rootViewController: FeedVC())
        searchNavController = UINavigationController(rootViewController: SearchViewController())
        
        feedNavController.setNavigationBarHidden(true, animated: false)
        dashbordNavController.setNavigationBarHidden(true, animated: false)
        searchNavController.setNavigationBarHidden(true, animated: false)
        
        tabBarController.delegate = self
        
        rootNavController.tabBarItem = UITabBarItem(title: "Chats".localize(), image: UIImage(systemName: "message"), tag: 0)
        feedNavController.tabBarItem = UITabBarItem(title: "Feed".localize(), image: UIImage(systemName: "play.rectangle.on.rectangle"), tag: 1)
        dashbordNavController.tabBarItem = UITabBarItem(title: "Explore".localize(), image: UIImage(systemName: "flame.fill"), tag: 2)
        groupChatsNavController.tabBarItem = UITabBarItem(title: "Groups".localize(), image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 3)
        searchNavController.tabBarItem = UITabBarItem(title: "Search".localize(), image: UIImage(systemName: "magnifyingglass"), tag: 4)

        tabBarController.viewControllers = [rootNavController, feedNavController, dashbordNavController, groupChatsNavController, searchNavController]
        tabBarController.selectedIndex = 0
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = self.tabBarController
        }, completion: nil)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            handleDeepLink(url: urlContext.url)
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    private func handleDeepLink(url: URL) {
        AnalyticService.shared.logEvent(name: "handleDeepLink: \(url)", properties: ["":""])
    }
}

extension SceneDelegate: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
         if let nav = tabBarController.selectedViewController as? UINavigationController,
            let selectedNav = viewController as? UINavigationController,
            nav == selectedNav,
            nav.viewControllers.count > 1 {
             return false
         }
         return true
     }
}
