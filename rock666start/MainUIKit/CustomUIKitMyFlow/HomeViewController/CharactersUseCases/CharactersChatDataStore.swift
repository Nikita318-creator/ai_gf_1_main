import Foundation
import RealmSwift

final class CharactersChatDataStore: CharactersChatDataStoreProtocol {
    private let realmProvider: RealmProviderProtocol

    init(realmProvider: RealmProviderProtocol) {
        self.realmProvider = realmProvider
    }

    func persistChatMessage(_ message: ChatRockStarDataModel, assistantId: String, messageId: String) {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return }

        let chatItem = CharactersChatObject(message: message, assistantId: assistantId, id: messageId)

        do {
            try activeRealm.write {
                let storedMessages = activeRealm.objects(CharactersChatObject.self)
                    .filter("authorId == %@", assistantId)
                    .sorted(byKeyPath: "dateOfCriation", ascending: true)

                if storedMessages.count >= 100, let oldestMessage = storedMessages.first {
                    activeRealm.delete(oldestMessage)
                }

                activeRealm.add(chatItem)
            }
        } catch {
            print("Failed write transaction: \(error)")
        }
    }

    func modifyChatMessage(id: String, message: ChatRockStarDataModel, assistantId: String) {
        guard let activeRealm = realmProvider.provideRealmInstance(),
              let targetEntity = activeRealm.object(ofType: CharactersChatObject.self, forPrimaryKey: id) else { return }

        do {
            try activeRealm.write {
                targetEntity.authorId = assistantId
                targetEntity.authorRole = message.authoreRole
                targetEntity.theMessage = message.theMessage
                targetEntity.isWaiting = message.isWaiting
                targetEntity.dateOfUpdation = Date()
                targetEntity.emogi = message.emogi
            }
        } catch {
            print("Failed update transaction: \(error)")
        }
    }

    func updateReaction(id: String, reaction: String?) {
        guard let activeRealm = realmProvider.provideRealmInstance(),
              let targetEntity = activeRealm.object(ofType: CharactersChatObject.self, forPrimaryKey: id) else { return }

        try? activeRealm.write {
            targetEntity.emogi = reaction
        }
    }

    func removeChatMessage(id: String) {
        guard let activeRealm = realmProvider.provideRealmInstance(),
              let targetEntity = activeRealm.object(ofType: CharactersChatObject.self, forPrimaryKey: id) else { return }

        do {
            try activeRealm.write {
                activeRealm.delete(targetEntity)
            }
        } catch {
            print("Failed delete transaction: \(error)")
        }
    }

    func fetchAllMessages(forAssistantId assistantId: String) -> [ChatRockStarDataModel] {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return [] }

        let fetchedEntities = activeRealm.objects(CharactersChatObject.self)
            .filter("authorId == %@", assistantId)
            .sorted(byKeyPath: "dateOfCriation", ascending: true)

        return fetchedEntities.map { $0.toMessage() }
    }

    func fetchSingleMessage(id: String) -> ChatRockStarDataModel? {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return nil }
        return activeRealm.object(ofType: CharactersChatObject.self, forPrimaryKey: id)?.toMessage()
    }
}
