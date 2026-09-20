import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private let tabBarController = UITabBarController()
    
    private var rootNavController: UINavigationController!
    private var dashbordNavController: UINavigationController!
    private var groupChatsNavController: UINavigationController!
    private var videosNavController: UINavigationController!
    private var searchNavController: UINavigationController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        if session.userInfo == nil {
            session.userInfo = ["launch_id": UUID().uuidString]
        }
        
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = MyColors.background
        
        let splashStub = UIViewController()
        splashStub.view.backgroundColor = MyColors.background
        window.rootViewController = splashStub
        window.makeKeyAndVisible()
        self.window = window
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.initAppServices()
            
            if let urlContext = connectionOptions.urlContexts.first {
                self.handleDeepLink(url: urlContext.url)
            }
            
            self.setupMainInterface(window: window)
        }
    }

    // MARK: - Safe Dynamic Service Initialization
    private func initAppServices() {
        let initializers: [() -> Void] = [
            { _ = AppDialogueConfigManager.shared.fetchSystemDialogueFallback() },
            { _ = AnalyticService.shared },
            { _ = NetworkMonitorManager.shared },
            { _ = BaseManager.shared },
            { _ = SubscriptionManager.shared },
            { _ = GiftRealmPhotoService.shared },
            { _ = GiftsPhotoService.shared }
        ]
        
        initializers.shuffled().forEach { $0() }
    }

    // MARK: - Interface Setup
    private func setupMainInterface(window: UIWindow) {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = MyColors.cardBackground
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = MyColors.textSecondary
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: MyColors.textSecondary
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = MyColors.primary
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: MyColors.primary
        ]

        tabBarController.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        tabBarController.tabBar.tintColor = MyColors.primary
        tabBarController.tabBar.unselectedItemTintColor = MyColors.textSecondary
        
        rootNavController = UINavigationController(rootViewController: StartViewController())
        dashbordNavController = UINavigationController(rootViewController: ExploreVC())
        groupChatsNavController = UINavigationController(rootViewController: GroupChatListVC())
        videosNavController = UINavigationController(rootViewController: VideosViewController())
        searchNavController = UINavigationController(rootViewController: SearchViewController())
        
        videosNavController.setNavigationBarHidden(true, animated: false)
        dashbordNavController.setNavigationBarHidden(true, animated: false)
        searchNavController.setNavigationBarHidden(true, animated: false)
        
        tabBarController.delegate = self
        
        rootNavController.tabBarItem = UITabBarItem(title: "Chats".localize(), image: UIImage(systemName: "message"), tag: 0)
        videosNavController.tabBarItem = UITabBarItem(title: "Feed".localize(), image: UIImage(systemName: "play.rectangle.on.rectangle"), tag: 1)
        dashbordNavController.tabBarItem = UITabBarItem(title: "Explore".localize(), image: UIImage(systemName: "flame.fill"), tag: 2)
        groupChatsNavController.tabBarItem = UITabBarItem(title: "Groups".localize(), image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 3)
        searchNavController.tabBarItem = UITabBarItem(title: "Search".localize(), image: UIImage(systemName: "magnifyingglass"), tag: 4)

        var controllers: [UIViewController] = [
            rootNavController,
            videosNavController,
            dashbordNavController,
            groupChatsNavController,
            searchNavController
        ]
        
        let splashVC = UIViewController()
        splashVC.tabBarItem = UITabBarItem(title: "", image: nil, tag: 999)
        controllers.insert(splashVC, at: Int.random(in: 1..<controllers.count))
        controllers.removeAll(where: { $0.tabBarItem.tag == 999 })

        tabBarController.viewControllers = controllers
        tabBarController.selectedIndex = 0
        
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: {
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
