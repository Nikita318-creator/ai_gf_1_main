import Foundation
import UIKit

struct ChannelModel {
    let name: String
    let avatarName: String
}

class ChannelViewModel {
    
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?

    let assistantsService = AIGirlfriendsManager()
    let messageHistoryService = AIGirlfriendMessagesManager()
    
    init() {
        setupGroupChats()
        loadGroupChats()
    }
    
    func loadGroupChats() {
        let groupChats: [ChatModel] = assistantsService.getAllConfigs()
            .filter { $0.id?.contains("_group") == true }
            .map { config in
                let lastMessage = messageHistoryService.getAllMessages(
                    forAssistantId: config.id ?? ""
                ).last?.content ?? "Hi".localize()
                
                return ChatModel(
                    id: config.id ?? "",
                    assistantName: config.assistantName,
                    lastMessage: lastMessage,
                    lastMessageTime: "",
                    assistantAvatar: config.avatarImageName
                )
            }
        chats = groupChats
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        return chats[indexPath.row]
    }
    
    private func setupGroupChats() {
        guard !assistantsService.getAllConfigs().contains(where: {
            $0.id?.contains("_group") == true
        }) else { return }
        
        struct GroupPreset {
            let idSuffix: String
            let name: String
            let info: String
            let avatar: String
            let initialMessage: String
            let avatarName: String
        }
        
        let presets: [GroupPreset] = [
            GroupPreset(
                idSuffix: "volleyball_group",
                name: "chat_volleyball_title".localize(),
                info: "chat_volleyball_desc".localize(),
                avatar: "groupChat5",
                initialMessage: "chat_volleyball_text".localize(),
                avatarName: "MyGF1"
            ),
            GroupPreset(
                idSuffix: "summercamp_group",
                name: "chat_summercamp_title".localize(),
                info: "chat_summercamp_desc".localize(),
                avatar: "groupChat4",
                initialMessage: "chat_summercamp_text".localize(),
                avatarName: "mainAvatar1"
            ),
            GroupPreset(
                idSuffix: "roommates_group",
                name: "chat_roommates_title".localize(),
                info: "chat_roommates_desc".localize(),
                avatar: "groupChat3",
                initialMessage: "chat_roommates_text".localize(),
                avatarName: "MyGF4_1"
            ),
            GroupPreset(
                idSuffix: "office_group",
                name: "chat_office_title".localize(),
                info: "chat_office_desc".localize(),
                avatar: "groupChat2",
                initialMessage: "chat_office_text".localize(),
                avatarName: "mainAvatar19"
            ),
            GroupPreset(
                idSuffix: "council_group",
                name: "chat_council_title".localize(),
                info: "chat_council_desc".localize(),
                avatar: "groupChat1",
                initialMessage: "chat_council_text".localize(),
                avatarName: "mainAvatar18"
            )
        ]
        
        for preset in presets {
            let groupID = preset.idSuffix
            
            let groupConfig = AIGirlfriendsConfig(
                id: groupID,
                assistantName: preset.name,
                assistantInfo: preset.info + "A guy surrounded by beautiful anime young women in this group.",
                avatarImageName: preset.avatar
            )
            
            assistantsService.addConfig(groupConfig)
            
            let messageId = UUID().uuidString
            AIGirlfriendMessagesManager().addMessage(
                AIGFMessageModel(
                    role: "assistant",
                    content: preset.initialMessage,
                    photoID: "",
                    id: messageId,
                    avatarName: preset.avatarName
                ),
                assistantId: groupID,
                messageId: messageId
            )
        }
    }
}
