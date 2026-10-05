import UIKit
import StoreKit

final class AIGFChatViewModel {
    
    // MARK: - Properties
    
    let repository = CommonChatRepository()
    
    var isFirstMessageInChat = true
    
    // Callbacks for View update
    var onMessagesUpdated: ((_ isSucceed: Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
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
    
    func loadMessages() {
        repository.messagesAI = repository.currentMessagesAI
    }
    
    // MARK: - Avatar & Profile Support
    
    func getAvatarImage() -> UIImage? {
        guard let avatarName = MyGovnoSingltone.shared.currentAssistant?.avatarImageName else { return nil }
        
        if avatarName.contains("waifuInOutfit_") {
            return MiniGamesPhotoCacheService.shared.getImage(named: avatarName)
        }
        
        let targetName = BackendService.shared.currentData.isABTestRandom ? (avatarName + "_") : avatarName
        return UIImage(named: targetName) ?? UIImage(named: avatarName) ?? MyGovnoSingltone.shared.notFriendProfileAvatar
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
        if previousMessages.contains("[photo]") && MyGovnoSingltone.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") != true {
            complainOnPhotoTextPrompt = " If the user complains that the photo doesn’t match what he asked for, your task is to explain that this photo comes from your gallery, which you took earlier, and reassure them that next time you’ll find a more suitable photo. If the user likes the photo or doesn’t comment on it at all, simply ignore this instruction! "
        } else {
            complainOnPhotoTextPrompt = ""
        }
                    
        let promptTail = complainOnPhotoTextPrompt + "your answer must be written strictly in the language that is using by user and corresponds to the code: '\(MyGovnoSingltone.shared.currentLanguage)'" + " Here is the user's question: "
        
        if MyGovnoSingltone.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == true {
            repository.systemPrompt = BackendService.shared.currentData.userPromptE + promptTail
        } else if let imageName = MyGovnoSingltone.shared.currentAssistant?.avatarImageName,
                  (21...25).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.userPromptM + promptTail
        } else if let imageName = MyGovnoSingltone.shared.currentAssistant?.avatarImageName,
                  (11...20).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.userPromptA + promptTail
        } else {
            repository.systemPrompt = BackendService.shared.currentData.userPromptMain + promptTail
        }
        
        repository.previousMessages = previousMessages
        repository.sendMessageViaCustomServer(text, isMessageFromTextChat: true)
        
        messageDidSend()
    }
    
    private func handleMessageReceived() {
        onMessageReceived?()
        
        if isFirstMessageInChat,
           let chatID = MyGovnoSingltone.shared.currentAssistant?.id {
            self.isFirstMessageInChat = false
        }
    }

    private func messageDidSend() {
        if MyGovnoSingltone.shared.isFirstMessageInChat {
            MyGovnoSingltone.shared.isFirstMessageInChat = false
            let assistantsService = AIGirlfriendsManager()
            let assistant = assistantsService.getAllConfigs().first { $0.id == MyGovnoSingltone.shared.currentAssistant?.id }
            guard let assistantConfig = assistant else { return }
            assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        }
    }

    private func requestReviewIfNeeded() {
        MyGovnoSingltone.shared.messagesSendCount += 1
        if RequestReviewManager.shared.shouldRequestReview() && MyGovnoSingltone.shared.messagesSendCount >= 2 {
//            onShowAlert?(.giftFromUs)// test111
            RequestReviewManager.shared.markReviewRequestedNow()
        }
    }
}
