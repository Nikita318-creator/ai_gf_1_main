import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        TrackingAuthorizationManager.requestTrackingAuthorization()
        
        let _ = NetworkMonitorManager.shared
        let _ = BaseManager.shared
        let _ = SubscriptionManager.shared
        let _ = GiftRealmPhotoService.shared
        let _ = GiftsPhotoService.shared
      
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = MyColors.background
        
        let rootNavController = UINavigationController(rootViewController: HomeViewController())
        window.rootViewController = rootNavController
        window.makeKeyAndVisible()
        self.window = window
    }
}
