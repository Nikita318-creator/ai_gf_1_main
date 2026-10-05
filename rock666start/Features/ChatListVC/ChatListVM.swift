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

    init() {
        loadChats()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadChats() {
        chats = assistantsService.getAllConfigs()
            .filter { $0.id?.contains("_group") == false }
            .compactMap { config in
                let messages = AIGirlfriendMessagesManager().getAllMessages(forAssistantId: config.id ?? "")
                
                // Если сообщений нет — не добавляем чат в список
                guard let lastMessage = messages.last?.content, !lastMessage.isEmpty else {
                    return nil
                }

                return ChatModel(
                    id: config.id ?? "",
                    assistantName: config.assistantName,
                    lastMessage: lastMessage,
                    lastMessageTime: "",
                    assistantAvatar: config.avatarImageName
                )
            }
        onChatsUpdated?()
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        guard chats.indices.contains(indexPath.row) else {
            return ChatModel(id: "", assistantName: "", lastMessage: "", lastMessageTime: "", assistantAvatar: "")
        }
        return chats[indexPath.row]
    }
}
