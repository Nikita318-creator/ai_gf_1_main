import Foundation
import UIKit

// MARK: - Protocols for Obfuscating Direct Dependencies

protocol ChatPersistenceProviding: AnyObject {
    func getAllMessages(forAssistantId id: String) -> [ChatRockStarDataModel]
    func addMessage(_ message: ChatRockStarDataModel, assistantId: String, messageId: String)
}

// Адаптер для исходного менеджер-сервиса
final class DefaultChatPersistenceAdapter: ChatPersistenceProviding {
    private let service = AIGirlfriendMessagesManager()
    
    func getAllMessages(forAssistantId id: String) -> [ChatRockStarDataModel] {
        return service.getAllMessages(forAssistantId: id)
    }
    
    func addMessage(_ message: ChatRockStarDataModel, assistantId: String, messageId: String) {
        service.addMessage(message, assistantId: assistantId, messageId: messageId)
    }
}

protocol MediaAssetResolving {
    func resolvePhotoIdentifier(for avatarName: String, rawContent: String) async -> String
    func resolveVideoIdentifier(for avatarName: String, completion: @escaping (String?) -> Void)
}

protocol AIServiceTransport {
    func executeFetch(prompt: String, completion: @escaping (Result<String, Error>) -> Void)
}

// MARK: - Local Cache Obfuscator

final class ChatStateCacheManager {
    private let storage = UserDefaults.standard
    private let devMessagesKey = String(["d","e","v","e","l","o","p","e","r","M","e","s","s","a","g","e","s","S","e","n","t"])
    
    func isPayloadDispatched(_ payload: String) -> Bool {
        let list = storage.stringArray(forKey: devMessagesKey) ?? []
        return list.contains(payload)
    }
    
    func recordDispatchedPayload(_ payload: String) {
        var list = storage.stringArray(forKey: devMessagesKey) ?? []
        list.append(payload)
        storage.set(list, forKey: devMessagesKey)
    }
}
