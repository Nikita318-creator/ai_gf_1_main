//
//  GroupChatListViewModel.swift
//  ChatBot20
//
//  Created by Mikita on 05/06/2026.
//

import Foundation
import UIKit

struct GroupChatModel {
    let name: String
    let avatarName: String
}

class GroupChatListViewModel {
    
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?

    let assistantsService = AssistantsService()
    let messageHistoryService = MessageHistoryService()
    
    init() {
//        assistantsService.getAllConfigs().forEach {
//            if $0.id?.contains("_group") == true {
//                assistantsService.deleteConfig(id: $0.id ?? "")
//            }
//        } // это пока тесчу не трггай потом выпилю удалялку
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
                name: "group_volleyball_name".localize(),
                info: "group_volleyball_info".localize(),
                avatar: "groupChat5",
                initialMessage: "group_volleyball_message".localize(),
                avatarName: "mainAvatar11"
            ),
            GroupPreset(
                idSuffix: "summercamp_group",
                name: "group_summercamp_name".localize(),
                info: "group_summercamp_info".localize(),
                avatar: "groupChat4",
                initialMessage: "group_summercamp_message".localize(),
                avatarName: "mainAvatar12"
            ),
            GroupPreset(
                idSuffix: "roommates_group",
                name: "group_roommates_name".localize(),
                info: "group_roommates_info".localize(),
                avatar: "groupChat3",
                initialMessage: "group_roommates_message".localize(),
                avatarName: "mainAvatar13"
            ),
            GroupPreset(
                idSuffix: "office_group",
                name: "group_office_name".localize(),
                info: "group_office_info".localize(),
                avatar: "groupChat2",
                initialMessage: "group_office_message".localize(),
                avatarName: "mainAvatar14"
            ),
            GroupPreset(
                idSuffix: "council_group",
                name: "group_council_name".localize(),
                info: "group_council_info".localize(),
                avatar: "groupChat1",
                initialMessage: "group_council_message".localize(),
                avatarName: "mainAvatar15"
            )
        ]
        
        for preset in presets {
            let groupID = preset.idSuffix
            
            let groupConfig = AssistantConfig(
                id: groupID,
                assistantName: preset.name,
                assistantInfo: preset.info + "A guy surrounded by beautiful anime young women in this group.",
                avatarImageName: preset.avatar
            )
            
            assistantsService.addConfig(groupConfig)
            
            let messageId = UUID().uuidString
            MessageHistoryService().addMessage(
                Message(
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
