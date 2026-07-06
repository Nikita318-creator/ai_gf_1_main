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
    
    // 1. Выносим ссылки на уровне класса, чтобы они были доступны во всех методах
    private let tabBarController = UITabBarController()
    
    private var rootNavController: UINavigationController!
    private var roleplayNavController: UINavigationController!
    private var createGFNavController: UINavigationController!
    private var feedNavController: UINavigationController!
    private var swipeModeNavController: UINavigationController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let _ = NetworkMonitor.shared
            let _ = MainHelper.shared
            let _ = IAPService.shared
            let _ = AnalyticService.shared
            let _ = RemoteRealmPhotoService.shared
            let _ = RemotePhotoService.shared
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
        roleplayNavController = UINavigationController(rootViewController: RoleplayVC())
        createGFNavController = UINavigationController(rootViewController: CreateGFFromTabBarVC())
        feedNavController = UINavigationController(rootViewController: FeedVC())
        swipeModeNavController = UINavigationController(rootViewController: SwipeModeVC())
        
        feedNavController.setNavigationBarHidden(true, animated: false)
        roleplayNavController.setNavigationBarHidden(true, animated: false)
        swipeModeNavController.setNavigationBarHidden(true, animated: false)
        
        tabBarController.delegate = self
        
        rootNavController.tabBarItem = UITabBarItem(title: "Chats".localize(), image: UIImage(systemName: "message"), tag: 0)
        roleplayNavController.tabBarItem = UITabBarItem(title: "Roleplay".localize(), image: UIImage(systemName: "sparkles"), tag: 1)
        createGFNavController.tabBarItem = UITabBarItem(title: "Create".localize(), image: UIImage(systemName: "wand.and.stars"), tag: 2)
        feedNavController.tabBarItem = UITabBarItem(title: "Feed".localize(), image: UIImage(systemName: "play.rectangle.on.rectangle"), tag: 3)
        swipeModeNavController.tabBarItem = UITabBarItem(title: "Love".localize(), image: UIImage(systemName: "person.2.fill"), tag: 4) // Тег изменили на 4 для уникальности
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnMode),
            name: .modUpdated,
            object: nil
        )
        
        // Первичная установка контроллеров
        if MainHelper.shared.isMode {
            tabBarController.viewControllers = [rootNavController, roleplayNavController, createGFNavController, swipeModeNavController]
        } else {
            tabBarController.viewControllers = [rootNavController, roleplayNavController, createGFNavController, feedNavController, swipeModeNavController]
        }
        tabBarController.selectedIndex = 0
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = self.tabBarController
        }, completion: nil)
    }
    
    // MARK: - Динамическое обновление таббара
    @objc private func updateOnMode() {
        // Запоминаем текущий выбранный контроллер, чтобы после смены структуры сохранить вкладку юзера
        let currentSelectedVC = tabBarController.selectedViewController
        
        let targetViewControllers: [UIViewController]
        if MainHelper.shared.isMode {
            targetViewControllers = [rootNavController, roleplayNavController, createGFNavController, swipeModeNavController]
        } else {
            targetViewControllers = [rootNavController, roleplayNavController, createGFNavController, feedNavController, swipeModeNavController]
        }
        
        // 3. Чтобы перерисовка не сопровождалась резким скачком элементов UI, завернем это в деликатную анимацию
        UIView.transition(with: tabBarController.tabBar, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.tabBarController.setViewControllers(targetViewControllers, animated: false)
            
            // Пытаемся вернуть пользователя на ту же вкладку, где он и был
            if let currentVC = currentSelectedVC, targetViewControllers.contains(currentVC) {
                self.tabBarController.selectedViewController = currentVC
            } else {
                // Если его вкладка исчезла (например, он сидел в Feed, а режим включился), уводим на дефолтную первую
                self.tabBarController.selectedIndex = 0
            }
            
            // Принудительно заставляем таббар обновить фреймы и кнопки
            self.tabBarController.tabBar.layoutIfNeeded()
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
