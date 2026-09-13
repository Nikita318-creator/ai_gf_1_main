import Foundation
import UIKit

class AllChatsViewModel {
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?

    let assistantsService = AssistantsService()
    let aiModel = AIChatViewModel()

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
    
    // Сохраняем точное время первого запуска для проверки "прошли ли 1 сутки"
    private func trackFirstLaunchDateIfNeeded() {
        let key = "first_app_open_timestamp"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(Date(), forKey: key)
        }
    }
    
    func shouldShowAdsBanner() -> Bool {
//        guard !MainHelper.shared.isMode,
//              !ConfigService.shared.additionalVideos.isEmpty,
//              IAPService.shared.hasActiveSubscription else {
//            return false
//        }
        
        // 2. Проверка времени: прошло ли 24 часа (86400 секунд) с первого открытия
        if let firstOpenDate = UserDefaults.standard.object(forKey: "first_app_open_timestamp") as? Date {
            let secondsInDay: TimeInterval = 86400
            return Date().timeIntervalSince(firstOpenDate) >= secondsInDay
        }

        return false
    }
    
    func loadChats() {
        // Исключаем баннер из общего списка чатов (.filter)
        chats = assistantsService.getAllConfigs()
            .filter { $0.id != "addsBannerID" }
            .map {
                let lastMessage = MessageHistoryService().getAllMessages(
                    forAssistantId: $0.id ?? ""
                ).last?.content ?? "test111 приветственное сообщение" //test111 приветственное сообщение

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
            UnreadMessagesService.shared.needAddUnreadMessage(),
            let assistantConfig = assistantsService.getAllConfigs().filter({
                $0.id != "addsBannerID" // Чтобы пуши случайно не прилетали от рекламного баннера
            }).randomElement()
        else {
            return
        }
        
        AnalyticService.shared.logEvent(name: "got unread message", properties: [:])

        assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        MainHelper.shared.currentAssistant = assistantConfig
        
        aiModel.systemPrompt = ""
        
        aiModel.onMessagesUpdated = { [weak self] _ in
            guard let self else { return }
            UnreadMessagesService.shared.lasChatUnreadID = assistantConfig.id
        }
        
        aiModel.sendMessageViaCustomServer("unreadMessage.promt1ForNewText".localize(), isNeedOnlyReply: true)
    }
    
    @objc private func handleAppDidBecomeActive() {
        setUnreadChat()
    }
}
