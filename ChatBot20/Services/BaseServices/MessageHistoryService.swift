//
//  MessageHistoryService.swift
//  ChatBot20
//
//  Created by Mikita on 6.06.25.
//

import Foundation
import UIKit
import RealmSwift

enum SchemaVersion {
    static let currentSchemaVersion: UInt64 = 14
}

// MARK: - Модель для Realm
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
    
    convenience init(message: Message, assistantId: String, id: String) {
        self.init()
        self.id = id
        self.assistantId = assistantId
        self.role = message.role
        self.content = message.content
        self.isLoading = message.isLoading
        self.isVoiceMessage = message.isVoiceMessage
        self.photoID = message.photoID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func toMessage() -> Message {
        return Message(role: role, content: content, isLoading: isLoading, photoID: photoID, isVoiceMessage: isVoiceMessage, id: id)
    }
}

// MARK: - Сервис истории сообщений
class MessageHistoryService {
    
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
                    
                    migration.enumerateObjects(ofType: AssistantConfigObject.className()) { oldObject, newObject in
                        if oldObject?["avatarImageName"] == nil || (oldObject?["avatarImageName"] as? String)?.isEmpty == true {
                            newObject?["avatarImageName"] = ""
                        }
                    }
                } else if oldSchemaVersion < 11 {
                    migration.enumerateObjects(ofType: AssistantConfigObject.className()) { oldObject, newObject in
                        if oldObject?["isVoiceMessage"] == nil {
                            newObject?["isVoiceMessage"] = false
                        }
                    }
                }
            }
        )
        
        // Подписка на уведомление о нехватке памяти (OOM защита)
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
        // Сбрасываем неиспользуемые кэши Realm, чтобы помочь системе освободить RAM
        let _ = try? Realm().invalidate()
    }

    // MARK: - Безопасная инициализация Realm
    private func getRealm() -> Realm? {
        // 1. Пробуем открыть основную дисковую базу
        do {
            return try Realm(configuration: config)
        } catch {
            AnalyticService.shared.logEvent(
                name: "realm inMemoryIdentifier fallback",
                properties: ["networkError": "\(error)"]
            )
            
            WebHookAnaliticksService.shared.sendErrorReport(
                messageText: "History fallback\n user: \(WebHookAnaliticksService.shared.randomID)"
            )
            
            // 2. Фолбек: In-Memory база со сбросом схем
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackMessageHistoryRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                // 3. Ультра-фолбек: База со случайным ID против конфликтов потоков/блокировок
                let ultraID = "UltraHistoryFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    // 4. Полный OOM: Памяти на девайсе вообще нет. Возвращаем nil, спасая приложение от краша.
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL: Total OOM. History Realm disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }
    
    // MARK: - CRUD Операции
    
    func addMessage(_ message: Message, assistantId: String, messageId: String = UUID().uuidString) {
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
    
    func updateMessage(id: String, message: Message, assistantId: String) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else {
            return
        }
        
        do {
            try realm.write {
                object.assistantId = assistantId
                object.role = message.role
                object.content = message.content
                object.isLoading = message.isLoading
                object.updatedAt = Date()
            }
        } catch {
            print("Failed to update message: \(error)")
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
    
    func getAllMessages(forAssistantId assistantId: String) -> [Message] {
        guard let realm = getRealm() else {
            // Возвращаем пустую историю, если база лежит из-за OOM — UI не упадет
            return []
        }
        
        let objects = realm.objects(MessageHistoryServiceObject.self)
            .filter("assistantId == %@", assistantId)
            .sorted(byKeyPath: "createdAt", ascending: true)
            
        return objects.map { $0.toMessage() }
    }
    
    func getMessage(id: String) -> Message? {
        guard let realm = getRealm() else { return nil }
        return realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id)?.toMessage()
    }
}
