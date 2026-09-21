import UIKit
import SnapKit

class StartViewController: UIViewController {
    
    private let allChatsViewController = ChatListVC()
        
    let assistantsService = AIGirlfriendsManager()

    private var isFirstOpen = true
    private var isEnvironmentDataLoaded = false
    
    private let isUseCashes: Bool = false
    
    private let metaLabel: UILabel = {
        let label = UILabel()
        label.textColor = .clear
        label.font = .systemFont(ofSize: 1)
        label.numberOfLines = 0
        return label
    }()
    
    private let cacheLabel: UILabel = {
        let label = UILabel()
        label.textColor = .clear
        label.font = .systemFont(ofSize: 1)
        label.numberOfLines = 0
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .clear
        label.font = .systemFont(ofSize: 1)
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        
        setupMetadataContainers()
        readCachedEnvironmentData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AmplitudeManager.shared.logEvent(name: "app started: isSubsActive: \(SubscriptionManager.shared.hasActiveSubscription)", properties: ["":""])
        
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
        
        if isUseCashes {
            applyCachedConfigsToExistingData()
        } else {
            if (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).count == 0 {
                assistantsService.addConfig(
                    AIGirlfriendsConfig(
                        assistantName: "character.name1".localize(),
                        assistantInfo: "GFBaseInfo1".localize(),
                        avatarImageName: "mainAvatar1"
                    )
                )
                
                (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).forEach {
                    AIGirlfriendMessagesManager().addMessage(
                        AIGFMessageModel(role: "assistant", content: "StartMessage1".localize()),
                        assistantId: $0.id ?? ""
                    )
                    
                    if $0.avatarImageName == "mainAvatar1" {
                        AIGirlfriendMessagesManager().addMessage(
                            AIGFMessageModel(role: "assistant", content: "[photo]", photoID: "firstFoto"),
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
        }
        
        isFirstOpen = false
    }
    
    private func setupMetadataContainers() {
        view.addSubview(metaLabel)
        view.addSubview(cacheLabel)
        view.addSubview(statusLabel)
        
        metaLabel.snp.makeConstraints {
            $0.bottom.centerX.equalToSuperview()
            $0.height.equalTo(0)
            $0.width.equalToSuperview().multipliedBy(0.5)
        }
        
        cacheLabel.snp.makeConstraints {
            $0.top.equalTo(metaLabel.snp.bottom)
            $0.height.equalTo(0)
            $0.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints {
            $0.top.equalTo(cacheLabel.snp.bottom)
            $0.height.equalTo(0)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func readCachedEnvironmentData() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let fileManager = FileManager.default
            guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
            let fileURL = cacheDirectory.appendingPathComponent("app_sys_env.json")
            
            guard fileManager.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            let baseCurrency = jsonObject["base_code"] as? String ?? "USD"
            let timeLastUpdate = jsonObject["time_last_update_utc"] as? String ?? ""
            let ratesCount = (jsonObject["rates"] as? [String: Any])?.count ?? 0
            
            DispatchQueue.main.async {
                self?.metaLabel.text = "BaseCurrency: \(baseCurrency)"
                self?.cacheLabel.text = "LastSync: \(timeLastUpdate)"
                self?.statusLabel.text = "CachedRates: \(ratesCount)"
            }
        }
    }
    
    private func applyCachedConfigsToExistingData() {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let fileURL = cacheDirectory.appendingPathComponent("app_sys_env.json")
        
        var assistantName = "character.name1".localize()
        var assistantInfo = "GFBaseInfo1".localize()
        var startMessage = "StartMessage1".localize()
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let baseCode = jsonObject["base_code"] as? String {
                assistantName = baseCode
            }
            if let timeUpdate = jsonObject["time_last_update_utc"] as? String {
                assistantInfo = timeUpdate
            }
            if let rates = jsonObject["rates"] as? [String: Any] {
                startMessage = "Rates count: \(rates.count)"
            }
        }
        
        if (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).count == 0 {
            assistantsService.addConfig(
                AIGirlfriendsConfig(
                    assistantName: assistantName,
                    assistantInfo: assistantInfo,
                    avatarImageName: "mainAvatar1"
                )
            )
            
            (assistantsService.getAllConfigs().filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }).forEach {
                AIGirlfriendMessagesManager().addMessage(
                    AIGFMessageModel(role: "assistant", content: startMessage),
                    assistantId: $0.id ?? ""
                )
                
                if $0.avatarImageName == "mainAvatar1" {
                    AIGirlfriendMessagesManager().addMessage(
                        AIGFMessageModel(role: "assistant", content: "[photo]", photoID: "firstFoto"),
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
    }
    
    private func startChat() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(allChatsViewController, animated: false)
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
