import Foundation
import UIKit

class ChatListVM {
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?

    let assistantsService = AIGirlfriendsManager()
    let aiModel = AIGFChatViewModel()

    init() {
        trackFirstLaunchDateIfNeeded()
        loadChats()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func trackFirstLaunchDateIfNeeded() {
        let key = "first_app_open_timestamp"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(Date(), forKey: key)
        }
    }
    
    func shouldShowAdsBanner() -> Bool {
        guard APIManager.shared.isABTestRandom,
              !APIManager.shared.testClips.isEmpty,
              SubscriptionManager.shared.hasActiveSubscription else {
            return false
        }
        
        if let firstOpenDate = UserDefaults.standard.object(forKey: "first_app_open_timestamp") as? Date {
            let secondsInDay: TimeInterval = 86400
            return Date().timeIntervalSince(firstOpenDate) >= secondsInDay // test111
        }

        return false
    }
    
    func loadChats() {
        chats = assistantsService.getAllConfigs()
            .filter { $0.id != "addsBannerID" && $0.id?.contains("_group") == false }
            .map {
                let lastMessage = AIGirlfriendMessagesManager().getAllMessages(
                    forAssistantId: $0.id ?? ""
                ).last?.content ?? "Hi".localize()

                return ChatModel(
                    id: $0.id ?? "",
                    assistantName: $0.assistantName,
                    lastMessage: lastMessage,
                    lastMessageTime: "",
                    assistantAvatar: $0.avatarImageName
                )
            }
        onChatsUpdated?()
        setUnreadChat()
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        guard chats.indices.contains(indexPath.row) else {
            return ChatModel(id: "", assistantName: "", lastMessage: "", lastMessageTime: "", assistantAvatar: "")
        }
        return chats[indexPath.row]
    }
    
    func setUnreadChat() {
        guard
            UnreadMessageManager.shared.needAddUnreadMessage(),
            let assistantConfig = assistantsService.getAllConfigs().filter({
                $0.id?.contains("_group") == false && $0.id != "addsBannerID" 
            }).randomElement()
        else {
            return
        }
        
        AmplitudeManager.shared.logEvent(name: "got unread message", properties: [:])

        assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        BaseManager.shared.currentAssistant = assistantConfig
        
        aiModel.systemPrompt = ""
        
        aiModel.onMessagesUpdated = { [weak self] _ in
            guard let self else { return }
            UnreadMessageManager.shared.lasChatUnreadID = assistantConfig.id
        }
        
        aiModel.sendMessageViaCustomServer("unreadMessage.promt1ForNewText".localize(), isNeedOnlyReply: true)
    }
    
    @objc private func handleAppDidBecomeActive() {
        setUnreadChat()
    }
}
