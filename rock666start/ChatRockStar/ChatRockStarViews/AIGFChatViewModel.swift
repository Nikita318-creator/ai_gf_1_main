import UIKit
import StoreKit

final class AIGFChatViewModel {
    
    // MARK: - Properties
    
    let repository = CommonChatRepository()
    
    var isFirstMessageInChat = true
    
    // Callbacks for View update
    var onMessagesUpdated: ((_ isSucceed: Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onShowAlert: ((BaseAlert.Types) -> Void)?
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
        guard let avatarName = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName else { return nil }
        
        let targetName = !BackendService.shared.currentData.aiText.isEmpty ? (avatarName + "_") : avatarName
        return UIImage(named: targetName) ?? UIImage(named: avatarName)
    }
    
    // MARK: - Message Actions
    
    func handleSendMessage(text: String, containerView: UIView, avatarView: UIView, tableView: UITableView) {
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
        if previousMessages.contains("[photo]") && MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("mainAvatar26") != true {
            complainOnPhotoTextPrompt = " If the user complains that the photo doesn’t match what he asked for, your task is to explain that this photo comes from your gallery, which you took earlier, and reassure them that next time you’ll find a more suitable photo. If the user likes the photo or doesn’t comment on it at all, simply ignore this instruction! "
        } else {
            complainOnPhotoTextPrompt = ""
        }
                    
        let promptTail = complainOnPhotoTextPrompt + "your answer must be written strictly in the language that is using by user and corresponds to the code: '\(MyGovnoSingltone.shared.userLang)'" + " Here is the user's question: "
        
        if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("mainAvatar26") == true {
            repository.systemPrompt = BackendService.shared.currentData.aiTextE + promptTail
        } else if let imageName = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName,
                  (21...25).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.aiTextM + promptTail
        } else if let imageName = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName,
                  (11...20).contains(where: { imageName.contains("mainAvatar\($0)") }) {
            repository.systemPrompt = BackendService.shared.currentData.aiTextA + promptTail
        } else {
            repository.systemPrompt = BackendService.shared.currentData.aiText + promptTail
        }
        
        repository.previousMessages = previousMessages
        repository.sendMessageViaCustomServer(text, isMessageFromTextChat: true)
        
        messageDidSend()
    }
    
    private func handleMessageReceived() {
        onMessageReceived?()
        
        if isFirstMessageInChat {
            self.isFirstMessageInChat = false
        }
    }

    private func messageDidSend() {
        if MyGovnoSingltone.shared.currentMessageFirst {
            MyGovnoSingltone.shared.currentMessageFirst = false
            let assistantsService = AIGirlfriendsManager()
            let assistant = assistantsService.getAllConfigs().first { $0.id == MyGovnoSingltone.shared.selectedAICompanion?.id }
            guard let assistantConfig = assistant else { return }
            assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        }
    }

    private func requestReviewIfNeeded() {
        MyGovnoSingltone.shared.countOfMessagesInOngoingChat += 1
        if RequestReviewManager.shared.needShowRateUs() && MyGovnoSingltone.shared.countOfMessagesInOngoingChat >= 2 {
            RequestReviewManager.shared.markReviewRequestedNow()
        }
    }
}
