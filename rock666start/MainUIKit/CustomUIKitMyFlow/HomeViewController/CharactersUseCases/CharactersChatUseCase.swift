import Foundation

final class CharactersChatUseCase {
    private let dataStore: CharactersChatDataStoreProtocol

    init(dataStore: CharactersChatDataStoreProtocol = CharactersChatDataStore(
        realmProvider: DefaultRealmProvider(configuration: CharactersSchemaMigrationFactory.buildConfiguration())
    )) {
        self.dataStore = dataStore
    }

    func addMessage(_ message: ChatRockStarDataModel, assistantId: String, messageId: String = UUID().uuidString) {
        dataStore.persistChatMessage(message, assistantId: assistantId, messageId: messageId)
    }

    func updateMessage(id: String, message: ChatRockStarDataModel, assistantId: String) {
        dataStore.modifyChatMessage(id: id, message: message, assistantId: assistantId)
    }

    func updateReaction(id: String, reaction: String?) {
        dataStore.updateReaction(id: id, reaction: reaction)
    }

    func deleteMessage(id: String) {
        dataStore.removeChatMessage(id: id)
    }

    func getAllMessages(forAssistantId assistantId: String) -> [ChatRockStarDataModel] {
        return dataStore.fetchAllMessages(forAssistantId: assistantId)
    }

    func getMessage(id: String) -> ChatRockStarDataModel? {
        return dataStore.fetchSingleMessage(id: id)
    }
}
