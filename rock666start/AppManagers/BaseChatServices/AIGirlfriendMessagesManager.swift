
import Foundation
import UIKit
import RealmSwift

enum SchemaVersion {
    static let currentSchemaVersion: UInt64 = 1
}

class MessageHistoryServiceObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var assistantId: String
    @Persisted var role: String
    @Persisted var content: String
    @Persisted var isLoading: Bool
    @Persisted var isVoiceMessage: Bool
    @Persisted var photoID: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var reaction: String?

    convenience init(message: ChatRockStarDataModel, assistantId: String, id: String) {
        self.init()
        self.id = id
        self.assistantId = assistantId
        self.role = message.authoreRole
        self.content = message.theMessage
        self.isLoading = message.isWaiting
        self.isVoiceMessage = message.isAudio
        self.photoID = message.mediaFileID
        self.createdAt = Date()
        self.updatedAt = Date()
        self.reaction = message.emogi
    }
    
    func toMessage() -> ChatRockStarDataModel {
        return ChatRockStarDataModel(id: id, isAudio: isVoiceMessage, emogi: reaction, authoreRole: role, theMessage: content, isWaiting: isLoading, mediaFileID: photoID)
    }
}

class AIGirlfriendMessagesManager {
    
    private let config: Realm.Configuration
    
    init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: MessageHistoryServiceObject.className()) { oldObject, newObject in
                        if oldObject?["assistantId"] == nil || (oldObject?["assistantId"] as? String)?.isEmpty == true {
                            newObject?["assistantId"] = ""
                        }
                        if oldObject?["photoID"] == nil || (oldObject?["photoID"] as? String)?.isEmpty == true {
                            newObject?["photoID"] = ""
                        }
                    }
                    
                    migration.enumerateObjects(ofType: AIGirlfriendsConfigObject.className()) { oldObject, newObject in
                        if oldObject?["avatarImageName"] == nil || (oldObject?["avatarImageName"] as? String)?.isEmpty == true {
                            newObject?["avatarImageName"] = ""
                        }
                    }
                } else if oldSchemaVersion < 11 {
                    migration.enumerateObjects(ofType: AIGirlfriendsConfigObject.className()) { oldObject, newObject in
                        if oldObject?["isVoiceMessage"] == nil {
                            newObject?["isVoiceMessage"] = false
                        }
                    }
                }
            }
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMemoryWarning() {
        let _ = try? Realm().invalidate()
    }

    // MARK: - Безопасная инициализация Realm
    private func getRealm() -> Realm? {
        do {
            return try Realm(configuration: config)
        } catch {
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackMessageHistoryRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                let ultraID = "UltraHistoryFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    return nil
                }
            }
        }
    }
    
    // MARK: - CRUD Операции
    
    func addMessage(_ message: ChatRockStarDataModel, assistantId: String, messageId: String = UUID().uuidString) {
        guard let realm = getRealm() else {
            print("Failed to add message: Realm is unavailable (OOM)")
            return
        }
        
        let object = MessageHistoryServiceObject(message: message, assistantId: assistantId, id: messageId)
        
        do {
            try realm.write {
                let messages = realm.objects(MessageHistoryServiceObject.self)
                    .filter("assistantId == %@", assistantId)
                    .sorted(byKeyPath: "createdAt", ascending: true)

                if messages.count >= 100, let oldest = messages.first {
                    realm.delete(oldest)
                }

                realm.add(object)
            }
        } catch {
            print("Failed to add message write transaction: \(error)")
        }
    }
    
    func updateMessage(id: String, message: ChatRockStarDataModel, assistantId: String) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else {
            return
        }
        
        do {
            try realm.write {
                object.assistantId = assistantId
                object.role = message.authoreRole
                object.content = message.theMessage
                object.isLoading = message.isWaiting
                object.updatedAt = Date()
                object.reaction = message.emogi
            }
        } catch {
            print("Failed to update message: \(error)")
        }
    }
    
    func updateReaction(id: String, reaction: String?) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else { return }
        try? realm.write {
            object.reaction = reaction
        }
    }
    
    func deleteMessage(id: String) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else {
            return
        }
        
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            print("Failed to delete message: \(error)")
        }
    }
    
    func getAllMessages(forAssistantId assistantId: String) -> [ChatRockStarDataModel] {
        guard let realm = getRealm() else {
            return []
        }
        
        let objects = realm.objects(MessageHistoryServiceObject.self)
            .filter("assistantId == %@", assistantId)
            .sorted(byKeyPath: "createdAt", ascending: true)
            
        return objects.map { $0.toMessage() }
    }
    
    func getMessage(id: String) -> ChatRockStarDataModel? {
        guard let realm = getRealm() else { return nil }
        return realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id)?.toMessage()
    }
}
