//
//  SceneDelegate.swift
//  ChatBot20
//
//  Created by Mikita on 4.06.25.
//

import UIKit
//import OneSignalFramework

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1. Создаем окно СРАЗУ
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        
        // 2. Уводим "тяжелый" и опасный прогрев в следующий цикл Main Thread
        // Это гарантирует, что UI уже готов принимать вызовы bounds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Твои прогревы, которые теперь не крашнут инит
            let _ = NetworkMonitor.shared
            let _ = MainHelper.shared
            let _ = IAPService.shared
            let _ = AnalyticService.shared
            let _ = RemoteRealmPhotoService.shared
            let _ = RemotePhotoService.shared
            let _ = GEOService.shared
            
            // Обработка диплинка (если вдруг оживет)
            if let urlContext = connectionOptions.urlContexts.first {
                self.handleDeepLink(url: urlContext.url)
            }
            
            // Настраиваем интерфейс, когда сервисы готовы
            self.setupMainInterface(window: window)
        }
        
        // Показываем пустое темное окно, пока идет микро-задержка инита
        window.makeKeyAndVisible()
        self.window = window
    }

    private func setupMainInterface(window: UIWindow) {
        // Создаем Tab Bar Controller
        let tabBarController = UITabBarController()
        
        // Создаем и настраиваем UITabBarAppearance
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
        
        // Создаем контроллеры (теперь их иниты безопасны)
        let rootVC = RootVC()
        let roleplayVC = RoleplayVC()
        let createGFVC = CreateGFFromTabBarVC()
        let feedVC  = FeedVC()
        let swipeModeVC  = SwipeModeVC()
        
        let rootNavController = UINavigationController(rootViewController: rootVC)
        let roleplayNavController = UINavigationController(rootViewController: roleplayVC)
        let createGFNavController = UINavigationController(rootViewController: createGFVC)
        let feedNavController = UINavigationController(rootViewController: feedVC)
        let swipeModeNavController = UINavigationController(rootViewController: swipeModeVC)
        
        feedNavController.setNavigationBarHidden(true, animated: false)
        roleplayNavController.setNavigationBarHidden(true, animated: false)
        swipeModeNavController.setNavigationBarHidden(true, animated: false)
        
        tabBarController.delegate = self
        
        rootNavController.tabBarItem = UITabBarItem(title: "Chats".localize(), image: UIImage(systemName: "message"), tag: 0)
        roleplayNavController.tabBarItem = UITabBarItem(title: "Roleplay".localize(), image: UIImage(systemName: "sparkles"), tag: 1)
        createGFNavController.tabBarItem = UITabBarItem(title: "Create".localize(), image: UIImage(systemName: "wand.and.stars"), tag: 2)
        feedNavController.tabBarItem = UITabBarItem(title: "Feed".localize(), image: UIImage(systemName: "play.rectangle.on.rectangle"), tag: 3)
        swipeModeNavController.tabBarItem = UITabBarItem(title: "Love".localize(), image: UIImage(systemName: "person.2.fill"), tag: 3)
        
        tabBarController.viewControllers = [rootNavController, roleplayNavController, createGFNavController, feedNavController, swipeModeNavController]
        tabBarController.selectedIndex = 0
        
        // Плавная замена рута, чтобы не было моргания
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            handleDeepLink(url: urlContext.url)
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    private func handleDeepLink(url: URL) {
        AnalyticService.shared.logEvent(name: "handleDeepLink: \(url)", properties: ["":""])
    }
}

//extension SceneDelegate: OSNotificationClickListener {
//    func onClick(event: OSNotificationClickEvent) {
//        AnalyticService.shared.logEvent(name: "OSNotificationClickEvent: \(event.notification.additionalData?["data"] as? String ?? "")", properties: ["":""])
//
//        if let data = (event.notification.additionalData?["data"] as? String), data == "openPayWall" {
//            MainHelper.shared.needOpenPaywall = true
//        }
//    }
//}

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
