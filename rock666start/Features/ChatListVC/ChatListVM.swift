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
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        guard chats.indices.contains(indexPath.row) else {
            return ChatModel(id: "", assistantName: "", lastMessage: "", lastMessageTime: "", assistantAvatar: "")
        }
        return chats[indexPath.row]
    }
}
