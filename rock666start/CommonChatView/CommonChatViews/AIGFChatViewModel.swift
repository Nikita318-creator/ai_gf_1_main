import UIKit
import StoreKit

final class AIGFChatViewModel {
    
    // MARK: - Properties
    
    let repository = CommonChatRepository()
    
    var streakCount: Int = 0
    var isFirstMessageInChat = true
    
    // Callbacks for View update
    var onMessagesUpdated: ((_ isSucceed: Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onShowStreakNotification: ((FlameType) -> Void)?
    var onShowAlert: ((BasePopupView.BasePopupType) -> Void)?
    var onShowToast: ((String) -> Void)?
    var onShowInternetError: (() -> Void)?
    var onShowSubs: (() -> Void)?
    
    init() {
        setupRepositoryHandlers()
    }
    
    // MARK: - ViewModel Setup & Initial Checks
    
    private func setupRepositoryHandlers() {
        repository.onMessagesUpdated = { [weak self] isSucceed in
            self?.onMessagesUpdated?(isSucceed)
        }
        
        repository.onMessageReceived = { [weak self] in
            guard let self = self else { return }
            self.handleMessageReceived()
        }
    }
    
    func checkForeStreak() {
        let currentID = BaseManager.shared.currentAssistant?.id ?? ""
        streakCount = FlameManager.shared.getStreakCount(for: currentID)
    }
    
    func loadMessages() {
        repository.messagesAI = repository.currentMessagesAI
    }
    
    func shouldHideStreak() -> Bool {
        return streakCount == 0
    }
    
    // MARK: - Avatar & Profile Support
    
    func getAvatarImage() -> UIImage? {
        guard let avatarName = BaseManager.shared.currentAssistant?.avatarImageName else { return nil }
        
        if avatarName.contains("waifuInOutfit_") {
            return MiniGamesPhotoCacheService.shared.getImage(named: avatarName)
        }
        
        let targetName = BackendService.shared.currentData.isABTestRandom ? (avatarName + "_") : avatarName
        return UIImage(named: targetName) ?? UIImage(named: avatarName) ?? BaseManager.shared.notFriendProfileAvatar
    }
    
    func getAssistantProfile() -> AssistantProfile? {
        guard let assistant = BaseManager.shared.currentAssistant else { return nil }
        
        let profileDict: [String: Any]?
        
        if assistant.avatarImageName.contains("waifuInOutfit_") {
            profileDict = SampleProfiles.items.indices.contains(55) ? SampleProfiles.items[55] : SampleProfiles.items.last
        } else {
            let allAssistantAvatarIDs = (1...28).map { "mainAvatar\($0)" }
            let index = allAssistantAvatarIDs.firstIndex(of: assistant.avatarImageName) ?? (SampleProfiles.items.indices.randomElement() ?? 0)
            profileDict = SampleProfiles.items.indices.contains(index) ? SampleProfiles.items[index] : SampleProfiles.items.randomElement()
        }
        
        guard let targetProfile = profileDict,
              let age = targetProfile["age"] as? Int,
              let country = targetProfile["country"] as? String,
              let city = targetProfile["city"] as? String,
              let bio = targetProfile["bio"] as? String else {
            return nil
        }
        
        return AssistantProfile(
            id: assistant.id ?? "",
            avatarImageName: assistant.avatarImageName,
            name: assistant.assistantName,
            age: age,
            country: country,
            city: city,
            bio: bio
        )
    }
    
    // MARK: - Message Actions
    
    func handleSendMessage(text: String, containerView: UIView, avatarView: UIView, tableView: UITableView) {
        PranksUseCase.shared.checkAndExecute(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            in: containerView,
            avatarView: avatarView,
            tableView: tableView,
            toastHandler: { [weak self] message, alpha in
                self?.onShowToast?(message)
            }
        )
        
        requestReviewIfNeeded()
        
        guard AIRequestLimitManager.shared.canMakeRequest() else {
            onShowAlert?(.dailyLimitReached)
            return
        }
        
        let previousMessages = "\nFor context, I'm attaching our recent messages\n" + (repository.messagesAI.suffix(8)
            .map { message in
                let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                return prefix + message.content
            }
            .joined(separator: "\n")) + "\nAnd now I'm asking: "
        
        let complainOnPhotoTextPrompt: String
        if (previousMessages.contains("[photo]") || previousMessages.contains("[new pic]")) && BaseManager.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") != true {
            complainOnPhotoTextPrompt = " If the user complains that the photo doesn’t match what he asked for, your task is to explain that this photo comes from your gallery, which you took earlier, and reassure them that next time you’ll find a more suitable photo. If the user likes the photo or doesn’t comment on it at all, simply ignore this instruction! "
        } else {
            complainOnPhotoTextPrompt = ""
        }
                    
        let promptTail = complainOnPhotoTextPrompt + "your answer must be written strictly in the language that is using by user and corresponds to the code: '\(BaseManager.shared.currentLanguage)'" + " Here is the user's question: "
        
        if BaseManager.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == true {
            repository.systemPrompt = BackendService.shared.currentData.userPromptE + promptTail
        } else if let imageName = BaseManager.shared.currentAssistant?.avatarImageName,
                  (21...25).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.userPromptM + promptTail
        } else if let imageName = BaseManager.shared.currentAssistant?.avatarImageName,
                  (11...20).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.userPromptA + promptTail
        } else {
            repository.systemPrompt = BackendService.shared.currentData.userPromptMain + promptTail
        }
        
        repository.previousMessages = previousMessages
        repository.sendMessageViaCustomServer(text, isMessageFromTextChat: true)
        
        messageDidSend()
    }

    func handleSendGift(_ gift: GirlfriendGiftModel) {
        let giftMessage = AIGFMessageModel(role: "user", content: "[gift]", photoID: gift.imageName)
        repository.messagesAI.append(giftMessage)
        repository.messageService.addMessage(giftMessage, assistantId: BaseManager.shared.currentAssistant?.id ?? "")
        
        onMessagesUpdated?(true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.replyToGift()
        }
    }
    
    private func replyToGift() {
        let avatarName = BaseManager.shared.currentAssistant?.avatarImageName ?? ""
        let isAnimeAvatar: Bool = {
            guard avatarName.hasPrefix("mainAvatar"),
                  let number = Int(avatarName.replacingOccurrences(of: "mainAvatar", with: "")) else {
                return false
            }
            return (11...20).contains(number)
        }()

        let cachedNames = GiftRealmPhotoService.shared.getAllCachedImageNames().filter { name in
            if isAnimeAvatar {
                return name.hasPrefix("anime_")
            } else {
                return !name.hasPrefix("anime_")
            }
        }

        let alreadyShown = GiftsPhotoService.shared.alreadyShownPics
        var availableNames = cachedNames.filter { !alreadyShown.contains($0) }

        if availableNames.isEmpty {
            availableNames = cachedNames
        }

        if GiftsPhotoService.shared.isTestPhotosReady,
           let selectedName = availableNames.randomElement(),
           UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") {

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                GiftsPhotoService.shared.alreadyShownPics.append(selectedName)
                
                let aiMessage = AIGFMessageModel(role: "assistant", content: "[new pic]", photoID: selectedName)
                self.repository.messagesAI.append(aiMessage)
                self.repository.messageService.addMessage(aiMessage, assistantId: BaseManager.shared.currentAssistant?.id ?? "")
                
                self.onMessagesUpdated?(true)
            }
        }
    }
    
    private func handleMessageReceived() {
        onMessageReceived?()
        
        if isFirstMessageInChat,
           let chatID = BaseManager.shared.currentAssistant?.id {
            self.isFirstMessageInChat = false
            if let currentStreakType = FlameManager.shared.checkAndUpdateStreak(for: chatID) {
                self.onShowStreakNotification?(currentStreakType)
            }
        }
    }

    private func messageDidSend() {
        if BaseManager.shared.isFirstMessageInChat {
            BaseManager.shared.isFirstMessageInChat = false
            let assistantsService = AIGirlfriendsManager()
            let assistant = assistantsService.getAllConfigs().first { $0.id == BaseManager.shared.currentAssistant?.id }
            guard let assistantConfig = assistant else { return }
            assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        }
    }

    private func requestReviewIfNeeded() {
        BaseManager.shared.messagesSendCount += 1
        if RequestReviewManager.shared.shouldRequestReview() && BaseManager.shared.messagesSendCount >= 2 {
//            onShowAlert?(.giftFromUs)// test111
            RequestReviewManager.shared.markReviewRequestedNow()
        }
    }
}
