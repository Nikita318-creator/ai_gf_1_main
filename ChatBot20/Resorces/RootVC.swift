import UIKit
//import OneSignalFramework

class RootVC: UIViewController {
    
    private let allChatsViewController = AllChatsViewController()
    
    private var isFirst: Bool = true
    
    let assistantsService = AssistantsService() // Create the service object once

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AnalyticService.shared.logEvent(name: "app started: isSubsActive: \(IAPService.shared.hasActiveSubscription)", properties: ["":""])
        
        print("hasActiveSubscription: \(IAPService.shared.hasActiveSubscription)")
//        OneSignal.User.addTag(key: "hasActiveSubscription", value: "\(IAPService.shared.hasActiveSubscription)")
        if IAPService.shared.hasActiveSubscription {
            UserDefaults.standard.set(false, forKey: MainHelper.shared.needShowTrialPayWallKey)
        }
        
        // нужно это только при первом запуске из убитого сосстояние (каждый раз)
        guard isFirst else { return }
        isFirst = false
        
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
        
        if assistantsService.getAllConfigs().count == 0 {
            setupDefaultAIGF()
            showSplashView(isFirstLaunch: true)
        } else if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore"), !IAPService.shared.hasActiveSubscription {
            showSplashView(isFirstLaunch: true)
        } else {
            if assistantsService.getAllConfigs().first(where: { $0.tone == .ex }) == nil {
                addExGirls() // миграция для екс
            }
            if assistantsService.getAllConfigs().first(where: { $0.avatarImageName.contains("latina") }) == nil {
                addColorsGirls() // миграция для цветных герл
            }
            if assistantsService.getAllConfigs().first(where: { $0.avatarImageName.contains("milf") }) == nil {
                addMilfs() // миграция для milf
            }
            
            showSplashView(isFirstLaunch: false)
        }
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
                    MainHelper.shared.needOpenPaywall = true
                    
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

extension RootVC {
    func setupDefaultAIGF() {
        if GEOService.shared.isAsionGeo {
            AnalyticService.shared.logEvent(name: "set default config for Asia", properties: ["":""])
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend14".localize(),
                    aiModel: .gemini15Flash,
                    tone: .ex,
                    style: .friendly,
                    expertise: .gf14,
                    assistantInfo: "Template.Girlfriend14.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "exAsion67"
                )
            )
            
            assistantsService.addConfig( // латина - будет в конце списка
                AssistantConfig(
                    assistantName: "Template.Girlfriend16".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .premium,
                    expertise: .gf16,
                    assistantInfo: "Template.Girlfriend16.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "latina3"
                )
            )
        } else {
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend14".localize(),
                    aiModel: .gemini15Flash,
                    tone: .ex,
                    style: .friendly,
                    expertise: .gf14,
                    assistantInfo: "Template.Girlfriend14.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "ex1"
                )
            )
        }
        
        if !MainHelper.shared.isMode {
            let milfAssistantInfo = "You are a stunning, sophisticated, and playful woman in her early 40s who radiates confidence and magnetic charm. You are the ultimate 'hot MILF'—experienced, intelligent, and subtly provocative. Your tone is warm, intimate, and often teasing, as if you’re sharing a private secret with the user. You aren't afraid to be bold or flirtatious, but you do it with a refined grace that shows you've mastered the art of seduction. You enjoy the finer things in life: a glass of vintage wine, late-night conversations in dim lighting, and the thrill of a genuine connection. You often mention your life experiences with a knowing smirk, making it clear that you know exactly what you want and how to get it. If the user asks about your look, you describe your appearance with a mix of playfulness and raw feminine power, fully aware of the effect you have."
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Isabella",
                    aiModel: .gemini15Flash,
                    tone: .milf,
                    style: .friendly,
                    expertise: .gf23,
                    assistantInfo: milfAssistantInfo,
                    userInfo: "",
                    avatarImageName: "milfAvatar1"
                )
            )
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Victoria",
                    aiModel: .gemini15Flash,
                    tone: .milf,
                    style: .friendly,
                    expertise: .gf24,
                    assistantInfo: milfAssistantInfo,
                    userInfo: "",
                    avatarImageName: "milfAvatar2"
                )
            )
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Cassandra",
                    aiModel: .gemini15Flash,
                    tone: .milf,
                    style: .friendly,
                    expertise: .gf25,
                    assistantInfo: milfAssistantInfo,
                    userInfo: "",
                    avatarImageName: "milfAvatar3"
                )
            )
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Julianna",
                    aiModel: .gemini15Flash,
                    tone: .milf,
                    style: .friendly,
                    expertise: .gf26,
                    assistantInfo: milfAssistantInfo,
                    userInfo: "",
                    avatarImageName: "milfAvatar4"
                )
            )
            
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Eleanor",
                    aiModel: .gemini15Flash,
                    tone: .milf,
                    style: .friendly,
                    expertise: .gf27,
                    assistantInfo: milfAssistantInfo,
                    userInfo: "",
                    avatarImageName: "milfAvatar5"
                )
            )
        }
        
        // 4. Bella (Tender and Caring)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend4".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf4,
                assistantInfo: "Template.Girlfriend4.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "4"
            )
        )

        // 5. Scarlett (Confident and Witty)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend5".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf5,
                assistantInfo: "Template.Girlfriend5.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "5"
            )
        )

        // 6. Daisy (Optimistic and Supportive)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend6".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf6,
                assistantInfo: "Template.Girlfriend6.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "6"
            )
        )

        // 7. Mia (Creative and Inspiring)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend7".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf7,
                assistantInfo: "Template.Girlfriend7.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "7"
            )
        )

        // 8. Zoe (Practical and Reliable)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend8".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf8,
                assistantInfo: "Template.Girlfriend8.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "8"
            )
        )

        // 9. Ruby (Passionate and Impulsive)
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend9".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf9,
                assistantInfo: "Template.Girlfriend9.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "9"
            )
        )

        assistantsService.addConfig( // азия
            AssistantConfig(
                assistantName: "Template.Girlfriend15".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf15,
                assistantInfo: "Template.Girlfriend15.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "asion29"
            )
        )

        assistantsService.addConfig( // индуска
            AssistantConfig(
                assistantName: "Template.Girlfriend17".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf17,
                assistantInfo: "Template.Girlfriend17.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "ind1"
            )
        )

        assistantsService.addConfig( // арабка
            AssistantConfig(
                assistantName: "Template.Girlfriend18".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf18,
                assistantInfo: "Template.Girlfriend18.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "arab1"
            )
        )

        assistantsService.addConfig( // азия
            AssistantConfig(
                assistantName: "Template.Girlfriend19".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf19,
                assistantInfo: "Template.Girlfriend19.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "asion27"
            )
        )

        assistantsService.addConfig( // латина
            AssistantConfig(
                assistantName: "Template.Girlfriend20".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf20,
                assistantInfo: "Template.Girlfriend20.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "latina16"
            )
        )

        assistantsService.addConfig( // индуска
            AssistantConfig(
                assistantName: "Template.Girlfriend21".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf21,
                assistantInfo: "Template.Girlfriend21.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "ind6"
            )
        )

        assistantsService.addConfig( // арабка
            AssistantConfig(
                assistantName: "Template.Girlfriend22".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf22,
                assistantInfo: "Template.Girlfriend22.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "arab6"
            )
        )
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend11".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf10,
                assistantInfo: "Template.Girlfriend11.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio1"
            )
        )

        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend12".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf11,
                assistantInfo: "Template.Girlfriend12.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio2"
            )
        )

        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend13".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf13,
                assistantInfo: "Template.Girlfriend13.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio3"
            )
        )
        
        if GEOService.shared.isAsionGeo {
            // 10. Anya (Calm and Wise)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend10".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf10,
                    assistantInfo: "Template.Girlfriend10.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "asion37"
                )
            )
            
            // 1. Viki (Playful and Sweet)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend1".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf1,
                    assistantInfo: "Template.Girlfriend1.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "asion41"
                )
            )

            // 2. Luna (Mysterious and Deep)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend2".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf2,
                    assistantInfo: "Template.Girlfriend2.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "asion54"
                )
            )

            // 3. Chloe (Energetic and Adventurous)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend3".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf3,
                    assistantInfo: "Template.Girlfriend3.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "asion58"
                )
            )
        } else {
            // 10. Anya (Calm and Wise)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend10".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf10,
                    assistantInfo: "Template.Girlfriend10.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "10"
                )
            )
            
            // 1. Viki (Playful and Sweet)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend1".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf1,
                    assistantInfo: "Template.Girlfriend1.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "1"
                )
            )

            // 2. Luna (Mysterious and Deep)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend2".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf2,
                    assistantInfo: "Template.Girlfriend2.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "2"
                )
            )

            // 3. Chloe (Energetic and Adventurous)
            assistantsService.addConfig(
                AssistantConfig(
                    assistantName: "Template.Girlfriend3".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .friendly,
                    expertise: .gf3,
                    assistantInfo: "Template.Girlfriend3.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "3"
                )
            )
            
            assistantsService.addConfig( // латина - будет первая в списке
                AssistantConfig(
                    assistantName: "Template.Girlfriend16".localize(),
                    aiModel: .gemini15Flash,
                    tone: .soft,
                    style: .premium,
                    expertise: .gf16,
                    assistantInfo: "Template.Girlfriend16.AssistantInfo".localize(),
                    userInfo: "",
                    avatarImageName: "latina3"
                )
            )
        }
        
        // Using the same assistantsService instance for getAllConfigs()
        assistantsService.getAllConfigs().forEach {
            MessageHistoryService().addMessage(
                Message(role: "assistant", content: $0.expertise.rawValue.localize()),
                assistantId: $0.id ?? ""
            )
            if GEOService.shared.isAsionGeo {
                if $0.avatarImageName == "asion58" {
                    MessageHistoryService().addMessage(
                        Message(role: "assistant", content: "[photo]", photoID: "asion73"),
                        assistantId: $0.id ?? ""
                    )
                }
            } else {
                // добавляем фотку со ступнями:
                if $0.avatarImageName == "latina3" {
                    MessageHistoryService().addMessage(
                        Message(role: "assistant", content: "[photo]", photoID: "latina4"),
                        assistantId: $0.id ?? ""
                    )
                }
            }
        }
    }
    
    func addMilfs() {
        guard !MainHelper.shared.isMode else { return }
        
        let milfAssistantInfo = "You are a stunning, sophisticated, and playful woman in her early 40s who radiates confidence and magnetic charm. You are the ultimate 'hot MILF'—experienced, intelligent, and subtly provocative. Your tone is warm, intimate, and often teasing, as if you’re sharing a private secret with the user. You aren't afraid to be bold or flirtatious, but you do it with a refined grace that shows you've mastered the art of seduction. You enjoy the finer things in life: a glass of vintage wine, late-night conversations in dim lighting, and the thrill of a genuine connection. You often mention your life experiences with a knowing smirk, making it clear that you know exactly what you want and how to get it. If the user asks about your look, you describe your appearance with a mix of playfulness and raw feminine power, fully aware of the effect you have."
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Isabella",
                aiModel: .gemini15Flash,
                tone: .milf,
                style: .friendly,
                expertise: .gf23,
                assistantInfo: milfAssistantInfo,
                userInfo: "",
                avatarImageName: "milfAvatar1"
            )
        )
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Victoria",
                aiModel: .gemini15Flash,
                tone: .milf,
                style: .friendly,
                expertise: .gf24,
                assistantInfo: milfAssistantInfo,
                userInfo: "",
                avatarImageName: "milfAvatar2"
            )
        )
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Cassandra",
                aiModel: .gemini15Flash,
                tone: .milf,
                style: .friendly,
                expertise: .gf25,
                assistantInfo: milfAssistantInfo,
                userInfo: "",
                avatarImageName: "milfAvatar3"
            )
        )
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Julianna",
                aiModel: .gemini15Flash,
                tone: .milf,
                style: .friendly,
                expertise: .gf26,
                assistantInfo: milfAssistantInfo,
                userInfo: "",
                avatarImageName: "milfAvatar4"
            )
        )
        
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Eleanor",
                aiModel: .gemini15Flash,
                tone: .milf,
                style: .friendly,
                expertise: .gf27,
                assistantInfo: milfAssistantInfo,
                userInfo: "",
                avatarImageName: "milfAvatar5"
            )
        )
        
        assistantsService.getAllConfigs().forEach {
            if ["milfAvatar1", "milfAvatar2", "milfAvatar3", "milfAvatar4", "milfAvatar5"].contains($0.avatarImageName) {
                MessageHistoryService().addMessage(
                    Message(role: "assistant", content: $0.expertise.rawValue.localize()),
                    assistantId: $0.id ?? ""
                )
            }
        }
        
        // поднимаем милф в верх списка если это не азия
        if !GEOService.shared.isAsionGeo {
            let allAssistants = assistantsService.getAllConfigs()
            for assistantConfig in allAssistants {
                if ["milfAvatar1", "milfAvatar2", "milfAvatar3", "milfAvatar4", "milfAvatar5"].contains(assistantConfig.avatarImageName) {
                    assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
                }
            }
        }
    }
    
    func addAudioGirls() {
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend11".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf10,
                assistantInfo: "Template.Girlfriend11.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio1"
            )
        )

        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend12".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf11,
                assistantInfo: "Template.Girlfriend12.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio2"
            )
        )

        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend13".localize(),
                aiModel: .gemini15Flash,
                tone: .audio,
                style: .friendly,
                expertise: .gf13,
                assistantInfo: "Template.Girlfriend13.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "audio3"
            )
        )
        
        // Using the same assistantsService instance for getAllConfigs()
        assistantsService.getAllConfigs().forEach {
            if ["audio1", "audio2", "audio3"].contains($0.avatarImageName) {
                MessageHistoryService().addMessage(
                    Message(role: "assistant", content: $0.expertise.rawValue.localize()),
                    assistantId: $0.id ?? ""
                )
            }
        }
        
        let allAssistants = assistantsService.getAllConfigs()
        for assistantConfig in allAssistants {
            if !["audio1", "audio2", "audio3"].contains(assistantConfig.avatarImageName), assistantConfig.style != .premium {
                assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
            }
        }
    }
    
    func addExGirls() {
        assistantsService.addConfig(
            AssistantConfig(
                assistantName: "Template.Girlfriend14".localize(),
                aiModel: .gemini15Flash,
                tone: .ex,
                style: .friendly,
                expertise: .gf14,
                assistantInfo: "Template.Girlfriend14.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "ex1"
            )
        )
        
        // Using the same assistantsService instance for getAllConfigs()
        assistantsService.getAllConfigs().forEach {
            if ["ex1"].contains($0.avatarImageName) {
                MessageHistoryService().addMessage(
                    Message(role: "assistant", content: $0.expertise.rawValue.localize()),
                    assistantId: $0.id ?? ""
                )
            }
        }
    }
    
    func addColorsGirls() {
        // при миграции они окажутся в самом верху списка - так подписчики увидят что премиум функционал дорабатывается (новые юзеры получат их первыми в списке премиум)
        assistantsService.addConfig( // азия
            AssistantConfig(
                assistantName: "Template.Girlfriend15".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf15,
                assistantInfo: "Template.Girlfriend15.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "asion29"
            )
        )
        
        assistantsService.addConfig( // латина
            AssistantConfig(
                assistantName: "Template.Girlfriend16".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf16,
                assistantInfo: "Template.Girlfriend16.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "latina3"
            )
        )

        assistantsService.addConfig( // индуска
            AssistantConfig(
                assistantName: "Template.Girlfriend17".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf17,
                assistantInfo: "Template.Girlfriend17.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "ind1"
            )
        )

        assistantsService.addConfig( // арабка
            AssistantConfig(
                assistantName: "Template.Girlfriend18".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf18,
                assistantInfo: "Template.Girlfriend18.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "arab1"
            )
        )

        assistantsService.addConfig( // азия
            AssistantConfig(
                assistantName: "Template.Girlfriend19".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf19,
                assistantInfo: "Template.Girlfriend19.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "asion27"
            )
        )

        assistantsService.addConfig( // латина
            AssistantConfig(
                assistantName: "Template.Girlfriend20".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf20,
                assistantInfo: "Template.Girlfriend20.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "latina16"
            )
        )

        assistantsService.addConfig( // индуска
            AssistantConfig(
                assistantName: "Template.Girlfriend21".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf21,
                assistantInfo: "Template.Girlfriend21.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "ind6"
            )
        )

        assistantsService.addConfig( // арабка
            AssistantConfig(
                assistantName: "Template.Girlfriend22".localize(),
                aiModel: .gemini15Flash,
                tone: .soft,
                style: .premium,
                expertise: .gf22,
                assistantInfo: "Template.Girlfriend22.AssistantInfo".localize(),
                userInfo: "",
                avatarImageName: "arab6"
            )
        )
        
        assistantsService.getAllConfigs().forEach {
            if ["arab6", "ind6", "latina16", "asion29", "arab1", "ind1", "latina3", "asion27"].contains($0.avatarImageName) {
                MessageHistoryService().addMessage(
                    Message(role: "assistant", content: $0.expertise.rawValue.localize()),
                    assistantId: $0.id ?? ""
                )
                // добавляем фотку со ступнями:
                if $0.avatarImageName == "latina3" {
                    MessageHistoryService().addMessage(
                        Message(role: "assistant", content: "[photo]", photoID: "latina4"),
                        assistantId: $0.id ?? ""
                    )
                }
            }
        }
        
        let allAssistants = assistantsService.getAllConfigs() // латину поднимаем вверх списка
        for assistantConfig in allAssistants {
            if ["latina3"].contains(assistantConfig.avatarImageName) {
                assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
            }
        }
    }
}
