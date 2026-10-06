import Foundation
import UIKit

class InstChatsViewModel {
    var instContacts: [InstChatDataModel] = [] {
        didSet {
            contactUpdatedHandler?()
        }
    }

    var contactUpdatedHandler: (() -> Void)?

    let assistantsService = CharactersUseCase()

    init() {
        fetchContacts()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func fetchContacts() {
        instContacts = assistantsService.getAllConfigs()
            .compactMap { config in
                let messages = CharactersChatUseCase().getAllMessages(forAssistantId: config.id ?? "")
                
                guard let lastMessage = messages.last?.theMessage, !lastMessage.isEmpty else {
                    return nil
                }

                return InstChatDataModel(
                    id: config.id ?? "",
                    assistantName: config.name,
                    lastMessage: lastMessage,
                    lastMessageTime: "",
                    assistantAvatar: config.authorIcon
                )
            }
        contactUpdatedHandler?()
    }
    
    func instContact(at indexPath: IndexPath) -> InstChatDataModel {
        guard instContacts.indices.contains(indexPath.row) else {
            return InstChatDataModel(id: "", assistantName: "", lastMessage: "", lastMessageTime: "", assistantAvatar: "")
        }
        return instContacts[indexPath.row]
    }
}
