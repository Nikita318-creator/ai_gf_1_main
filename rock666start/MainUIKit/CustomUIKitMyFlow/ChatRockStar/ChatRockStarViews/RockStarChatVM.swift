import UIKit

@MainActor
final class RockStarChatVM {
    
    let repository = RockStarRepository()
    
    var isFirstMessageInChat = true
    
    var onMessagesUpdated: ((_ isSucceed: Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onShowAlert: ((BaseAlert.Types) -> Void)?
    var onShowToast: ((String) -> Void)?
    
    init() {
        configureDataBinders()
    }
    
    private func configureDataBinders() {
        repository.needUpdateHandler = { [weak self] stateFlag in
            self?.onMessagesUpdated?(stateFlag)
        }
        
        repository.gotAIRespoceHandler = { [weak self] in
            guard let self = self else { return }
            self.processIncomingPayload()
        }
    }
    
    func loadMessages() {
        repository.dataModel = repository.historyOfChatForActualAI
    }
    
    func getAvatarImage() -> UIImage? {
        guard let profilePicName = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon else { return nil }
        return UIImage(named: profilePicName)
    }
    
    func handleSendMessage(text: String, containerView: UIView, avatarView: UIView, tableView: UITableView) {
        evaluateRatingPrompt()
        
        guard AIRequestLimitManager.shared.canMakeRequest() else {
            onShowAlert?(.dailyLimitReached)
            return
        }
        
        // test111
        guard !BackendService.shared.currentData.isLimitesSpent else {
            return
        }
        
        let historicalContext = "\nFor context, I'm attaching our recent messages\n" + (repository.dataModel.suffix(8)
            .map { entryItem in
                let rolePrefix = (entryItem.authoreRole == "man") ? "user: " : "girlfriend: "
                return rolePrefix + entryItem.theMessage
            }
            .joined(separator: "\n")) + "\nAnd now I'm asking: "
        
        let photoNoticeInstruction: String
        if historicalContext.contains("[photo]") && MyGovnoSingltone.shared.selectedAICompanion?.authorIcon.contains("icon26") != true {
            photoNoticeInstruction = " If the user complains that the photo doesn’t match what he asked for, your task is to explain that this photo comes from your gallery, which you took earlier, and reassure them that next time you’ll find a more suitable photo. If the user likes the photo or doesn’t comment on it at all, simply ignore this instruction! "
        } else {
            photoNoticeInstruction = ""
        }
                    
        let appendedPromptRules = photoNoticeInstruction + "your answer must be written strictly in the language that is using by user and corresponds to the code: '\(MyGovnoSingltone.shared.userLang)'" + " Here is the user's question: "
        
        if BackendService.shared.currentData.aiText.isEmpty, let iconID = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon.integerValue {
            repository.baseTextToAI = RoleModel.makeSystemPrompt(for: iconID)
        } else {
            if MyGovnoSingltone.shared.selectedAICompanion?.authorIcon.contains("icon26") == true {
                repository.baseTextToAI = BackendService.shared.currentData.aiTextE + appendedPromptRules
            } else if let assetKey = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon,
                      (21...25).contains(where: { assetKey.contains("icon\($0)") }) {
                repository.baseTextToAI = BackendService.shared.currentData.aiTextM + appendedPromptRules
            } else if let assetKey = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon,
                      (11...20).contains(where: { assetKey.contains("icon\($0)") }) {
                repository.baseTextToAI = BackendService.shared.currentData.aiTextA + appendedPromptRules
            } else {
                repository.baseTextToAI = BackendService.shared.currentData.aiText + appendedPromptRules
            }
        }
        
        repository.historyAIMessages = historicalContext
        repository.send(text)
        
        dispatchOutgoingState()
    }
    
    private func processIncomingPayload() {
        onMessageReceived?()
        
        if isFirstMessageInChat {
            self.isFirstMessageInChat = false
        }
    }

    private func dispatchOutgoingState() {
        if MyGovnoSingltone.shared.currentMessageFirst {
            MyGovnoSingltone.shared.currentMessageFirst = false
            let helperRegistry = CharactersUseCase()
            let targetHelper = helperRegistry.getAllConfigs().first { $0.id == MyGovnoSingltone.shared.selectedAICompanion?.id }
            guard let validConfig = targetHelper else { return }
            helperRegistry.updateConfig(id: validConfig.id ?? "", config: validConfig)
        }
    }

    private func evaluateRatingPrompt() {
        MyGovnoSingltone.shared.countOfMessagesInOngoingChat += 1
        if RequestReviewManager.shared.needShowRateUs() && MyGovnoSingltone.shared.countOfMessagesInOngoingChat >= 2 {
            RequestReviewManager.shared.markReviewRequestedNow()
        }
    }
}

extension String {
    /// Извлекает число из строки (например: "icon30" -> 30, "icon1" -> 1)
    var integerValue: Int? {
        Int(compactMap { $0.wholeNumberValue }.map(String.init).joined())
    }
}
