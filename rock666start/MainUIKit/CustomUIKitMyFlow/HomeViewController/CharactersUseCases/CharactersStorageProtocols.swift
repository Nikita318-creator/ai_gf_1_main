import Foundation

protocol CharactersEntityRepresentable {
    var primaryIdentifier: String { get }
}

protocol CharactersRepositoryManageable: AnyObject {
    associatedtype Element
    func saveItem(_ item: Element)
    func updateItem(identifier: String, updateBlock: (inout Element) -> Void)
    func removeItem(withIdentifier identifier: String)
    func fetchItem(byIdentifier identifier: String) -> Element?
    func fetchAllItems() -> [Element]
}

protocol CharactersChatDataStoreProtocol: AnyObject {
    func persistChatMessage(_ model: ChatRockStarDataModel, assistantId: String, messageId: String)
    func modifyChatMessage(id: String, message: ChatRockStarDataModel, assistantId: String)
    func updateReaction(id: String, reaction: String?)
    func removeChatMessage(id: String)
    func fetchAllMessages(forAssistantId assistantId: String) -> [ChatRockStarDataModel]
    func fetchSingleMessage(id: String) -> ChatRockStarDataModel?
}

protocol CharactersConfigDataStoreProtocol: AnyObject {
    func storeConfiguration(_ config: CharactersDataModel)
    func modifyConfiguration(id: String, config: CharactersDataModel)
    func purgeConfiguration(id: String)
    func retrieveAllConfigurations() -> [CharactersDataModel]
    func retrieveConfiguration(id: String) -> CharactersDataModel?
}
