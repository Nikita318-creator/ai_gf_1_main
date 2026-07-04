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
    
    func loadChats() {
        chats = assistantsService.getAllConfigs().map {
            let lastMessage = MessageHistoryService().getAllMessages(
                forAssistantId: $0.id ?? ""
            ).last?.content ?? $0.expertise.rawValue.localize()

            return ChatModel(
                id: $0.id ?? "",
                assistantName: $0.assistantName,
                lastMessage: lastMessage,
                lastMessageTime: "",
                assistantAvatar: $0.avatarImageName,
                isPremium: $0.style == .premium
            )
        }
        onChatsUpdated?()
        setUnreadChat()
    }

    func filterChats(for filter: ChatFilterType) {
        chats = assistantsService.getAllConfigs().map {
            let lastMessage = MessageHistoryService().getAllMessages(
                forAssistantId: $0.id ?? ""
            ).last?.content ?? $0.expertise.rawValue.localize()

            return ChatModel(
                id: $0.id ?? "",
                assistantName: $0.assistantName,
                lastMessage: lastMessage,
                lastMessageTime: "",
                assistantAvatar: $0.avatarImageName,
                isPremium: $0.style == .premium
            )
        }

        if filter != .allChats {
            AnalyticService.shared.logEvent(name: "filter chats: \(filter)", properties: ["":""])
        }
        
        switch filter {
        case .allChats:
            print() // do nothing
        case .createdByUser:
            chats = chats.filter { !["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "audio1", "audio2", "audio3", "ex1", "exAsion67", "roleplay1", "roleplay2", "roleplay3", "roleplay4", "roleplay5", "roleplay6", "roleplay7", "roleplay8", "roleplay9", "roleplay10", "roleplay11", "roleplay12", "arab6", "ind6", "latina16", "asion27", "arab1", "ind1", "latina3", "asion29", "asion37", "asion41", "asion54", "asion58", "asion74", "asion49", "asion72", "asion89", "asion35", "asion36", "milfAvatar1", "milfAvatar2", "milfAvatar3", "milfAvatar4", "milfAvatar5"].contains($0.assistantAvatar) } // todo не забудь добавить сюда в фильтр если добавишь новую ролплей АИ ГФ
        case .premium:
            chats = chats.filter { $0.isPremium }
        case .defaultChats:
            chats = chats.filter { ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "audio1", "audio2", "audio3", "ex1", "exAsion67", "arab6", "ind6", "latina16", "asion27", "arab1", "ind1", "latina3", "asion29", "asion37", "asion41", "asion54", "asion58", "milfAvatar1", "milfAvatar2", "milfAvatar3", "milfAvatar4", "milfAvatar5"].contains($0.assistantAvatar) }
        case .voiceChats:
            chats = chats.filter { ["audio1", "audio2", "audio3"].contains($0.assistantAvatar) }
        case .ex:
            chats = chats.filter { ["ex1", "exAsion67"].contains($0.assistantAvatar) }
        case .roleplay:
            chats = chats.filter { ["roleplay1", "roleplay2", "roleplay3", "roleplay4", "roleplay5", "roleplay6", "roleplay7", "roleplay8", "roleplay9", "roleplay10", "roleplay11", "roleplay12", "asion74", "asion49", "asion72", "asion89", "asion35", "asion36"].contains($0.assistantAvatar) }
        case .milf:
            chats = chats.filter { ["milfAvatar1", "milfAvatar2", "milfAvatar3", "milfAvatar4", "milfAvatar5"].contains($0.assistantAvatar) }
            
        }
        
        self.onChatsUpdated?()
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        guard chats.indices.contains(indexPath.row) else {
            return chats.first ?? ChatModel(id: "", assistantName: "", lastMessage: "", lastMessageTime: "", assistantAvatar: "", isPremium: false)
        }
        
        return chats[indexPath.row]
    }
    
    func setUnreadChat() {
        guard
            UnreadMessagesService.shared.needAddUnreadMessage(), 
            let assistantConfig = assistantsService.getAllConfigs().filter({
                $0.tone != .audio &&
                ($0.style != .premium || ($0.style == .premium && IAPService.shared.hasActiveSubscription))
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
            filterChats(for: UnreadMessagesService.shared.currentFilter ?? .allChats) // костыль для апдейта UI
        }
        
        aiModel.sendMessageViaCustomServer("unreadMessage.promt1ForNewText".localize(), isNeedOnlyReply: true)
    }
    
    @objc private func handleAppDidBecomeActive() {
        setUnreadChat()
    }
}
