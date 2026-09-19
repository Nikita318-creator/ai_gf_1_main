import UIKit

class StartViewController: UIViewController {
    
    private let allChatsViewController = AllChatsViewController()
        
    let assistantsService = AssistantsService() // Create the service object once

    private var isFirstOpen = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AnalyticService.shared.logEvent(name: "app started: isSubsActive: \(IAPService.shared.hasActiveSubscription)", properties: ["":""])
        
        view.backgroundColor = .black

        DispatchQueue.main.async {
            let textField = UITextField()
            UIApplication.shared.windows.first?.addSubview(textField)
            textField.becomeFirstResponder()
            textField.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textField.removeFromSuperview()
            }
        }
        
        if (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).count == 0 {
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "character.name1".localize(),
                    assistantInfo: "GFBaseInfo1".localize(),
                    avatarImageName: "mainAvatar1"
                )
            )
            
            (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).forEach {
                MessageHistoryService().addMessage(
                    Message(role: "assistant", content: "StartMessage1".localize()),
                    assistantId: $0.id ?? ""
                )
                
                if $0.avatarImageName == "mainAvatar1" {
                    MessageHistoryService().addMessage(
                        Message(role: "assistant", content: "[photo]", photoID: "firstFoto"),
                        assistantId: $0.id ?? ""
                    )
                }
            }
            
            showSplashView(isFirstLaunch: true)
        } else if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") && isFirstOpen {
            showSplashView(isFirstLaunch: true)
        } else if isFirstOpen {
            showSplashView(isFirstLaunch: false)
        }
        
        isFirstOpen = false
    }
    
    private func startChat() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(allChatsViewController, animated: false)

//        allChatsViewController.modalPresentationStyle = .fullScreen
//        allChatsViewController.isModalInPresentation = true
//        present(allChatsViewController, animated: false)
    }
    
    private func showSplashView(isFirstLaunch: Bool) {
        let splashView = SplashScreenView()
        view.addSubview(splashView)
        splashView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.5, animations: {
                splashView.alpha = 0.0
            }) { [weak self] _ in
                guard let self else { return }
                splashView.removeFromSuperview()
                
                if !isFirstLaunch {
                    startChat()
                } else {
                    BaseManager.shared.needOpenPaywall = true
                    
                    let onbordingVC = OnboardingVC()
                    onbordingVC.modalPresentationStyle = .fullScreen
                    onbordingVC.isModalInPresentation = true
                    
                    onbordingVC.onbordingFinishedHandler = { [weak self] in
                        self?.startChat()
                    }
                    
                    self.present(onbordingVC, animated: false)
                }
            }
        }
    }
}
