import UIKit

final class RandomAIGFViewModel {
    
    // MARK: - Inputs / Outputs
    var onStateChanged: ((Step) -> Void)?
    var onAvatarUpdated: ((String) -> Void)?
    var onMatchCompleted: ((AIGirlfriendsConfig) -> Void)?
    
    enum Step {
        case welcome
        case poll
        case matching
    }
    
    // MARK: - Properties
    private(set) var currentStep: Step = .welcome {
        didSet { onStateChanged?(currentStep) }
    }
    
    let communicationStyles = [
        "Roulette_Style_Option1".localize(),
        "Roulette_Style_Option2".localize(),
        "Roulette_Style_Option3".localize()
    ]

    let interests = [
        "Roulette_Interest_Anime".localize(),
        "Roulette_Interest_Gaming".localize(),
        "Roulette_Interest_Sports".localize(),
        "Roulette_Interest_Movies".localize(),
        "Roulette_Interest_Music".localize(),
        "Roulette_Interest_Cosplay".localize(),
        "Roulette_Interest_KPop".localize(),
        "Roulette_Interest_Reading".localize(),
        "Roulette_Interest_Tech".localize(),
        "Roulette_Interest_Art".localize(),
        "Roulette_Interest_Cooking".localize(),
        "Roulette_Interest_Travel".localize(),
        "Roulette_Interest_Fitness".localize(),
        "Roulette_Interest_History".localize(),
        "Roulette_Interest_Fashion".localize(),
        "Roulette_Interest_Memes".localize(),
        "Roulette_Interest_Crypto".localize(),
        "Roulette_Interest_BoardGames".localize(),
        "Roulette_Interest_Mythology".localize(),
        "Roulette_Interest_ASMR".localize()
    ]

    let ageThemes = [
        "Roulette_Age_Option2".localize(),
        "Roulette_Age_Option1".localize(),
        "Roulette_Age_Option3".localize()
    ]

    private let gfImages: [String] = {
        let combined: [String] = APIManager.shared.isABTestRandom ? (1...87).map { "swipeModeAvatar\($0)" } : SearchAIGFFeatureViewModel.avatarsA
        return combined
    }()

    var selectedStyleIndex = 0
    var selectedInterestIndex = 0
    var selectedAdultIndex = 0

    private var matchTimer: Timer?
    private var matchDurationTimer: Timer?
    private var currentAvatarImageName = ""

    // MARK: - Actions
    func startPoll() {
        currentStep = .poll
    }
    
    func launchMatch() {
        currentStep = .matching
        startSimulation()
    }
    
    func handleBackNavigation() -> Bool {
        switch currentStep {
        case .welcome:
            return true // Должен закрыть контроллер
        case .poll:
            currentStep = .welcome
            return false
        case .matching:
            stopTimers()
            currentStep = .poll
            return false
        }
    }
    
    func resetState() {
        selectedStyleIndex = 0
        selectedInterestIndex = 0
        selectedAdultIndex = 0
        stopTimers()
        currentAvatarImageName = ""
        currentStep = .welcome
    }

    private func startSimulation() {
        matchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let randomImage = self.gfImages.randomElement() else { return }
            self.currentAvatarImageName = randomImage
            self.onAvatarUpdated?(randomImage)
        }

        matchDurationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.completeMatch()
        }
    }

    private func completeMatch() {
        stopTimers()

        let selectedStyle = communicationStyles[selectedStyleIndex]
        let selectedInterest = interests[selectedInterestIndex]
        let selectedAge = APIManager.shared.isABTestRandom ? ageThemes[selectedAdultIndex] : "Roulette_Age_Option2".localize()

        let gfNameKeys = (1...87).map { "swipeModeName\($0)" }
        let randomGfName = (gfNameKeys.randomElement() ?? "swipeModeName2").localize()
        
        AmplitudeManager.shared.logEvent(
            name: "ChatRoulette gf found",
            properties: [
                "selectedStyle": selectedStyle,
                "selectedInterest": selectedInterest,
                "selectedAge": selectedAge,
                "matchingAvatarImageName": currentAvatarImageName,
                "randomGfName": randomGfName
            ]
        )

        let promptForAI = " This is a chat roulette mode, you are randomly selected to communicate with the user because your profiles matched, you strictly use the \(selectedStyle) communication style in communication! All your topics one way or another come down to the discussion of \(selectedInterest), ask the user questions, talk about why it fascinates you, develop the thought -- involve the user in a conversation on this topic! The user was asked if he wants the conversation to be mostly focused on 18+ themes and discussions of adults topics and he answered \(selectedAge) -- this was the most important condition for the current chat. "

        let selectedAssistantID = UUID().uuidString
        let selectedAssistant = AIGirlfriendsConfig(
            id: selectedAssistantID,
            assistantName: randomGfName,
            assistantInfo: promptForAI,
            avatarImageName: currentAvatarImageName
        )
        
        AIGirlfriendsManager().addConfig(selectedAssistant)

        let welcomeMessageKeys = (1...10).map { "Roulette_Welcome_\($0)" }
        let randomWelcomeMessage = (welcomeMessageKeys.randomElement() ?? "Roulette_Welcome_1").localize()

        let messageId = UUID().uuidString
        AIGirlfriendMessagesManager().addMessage(
            AIGFMessageModel(
                role: "assistant",
                content: randomWelcomeMessage,
                id: messageId
            ),
            assistantId: selectedAssistantID,
            messageId: messageId
        )
        
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        
        onMatchCompleted?(selectedAssistant)
    }

    private func stopTimers() {
        matchTimer?.invalidate()
        matchDurationTimer?.invalidate()
        matchTimer = nil
        matchDurationTimer = nil
    }
}
