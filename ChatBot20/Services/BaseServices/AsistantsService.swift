//
//  AsistantsService.swift
//  ChatBot20
//
//  Created by Mikita on 5.06.25.
//

import Foundation
import UIKit
import RealmSwift

// MARK: - Модель для Realm
class AssistantConfigObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var assistantName: String
    @Persisted var aiModel: String
    @Persisted var tone: String
    @Persisted var style: String
    @Persisted var expertise: String
    @Persisted var assistantInfo: String
    @Persisted var userInfo: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var isPremium: Bool
    @Persisted var avatarImageName: String
    
    // Инициализатор
    convenience init(id: String, config: AssistantConfig, isPremium: Bool = false) {
        self.init()
        self.id = id
        self.assistantName = config.assistantName
        self.aiModel = config.aiModel.rawValue.localize()
        self.tone = config.tone.rawValue.localize()
        self.style = config.style.rawValue.localize()
        self.expertise = config.expertise.rawValue.localize()
        self.assistantInfo = config.assistantInfo
        self.userInfo = config.userInfo
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPremium = isPremium
        self.avatarImageName = config.avatarImageName
    }
    
    // Конвертация в AssistantConfig
    func toAssistantConfig() -> AssistantConfig {
        return AssistantConfig(
            id: id,
            assistantName: assistantName,
            aiModel: AIModels(rawValue: aiModel) ?? .gemini2,
            tone: Tone.convert(for: tone),
            style: Style.convert(for: style),
            expertise: Expertise.convert(for: expertise),
            assistantInfo: assistantInfo,
            userInfo: userInfo,
            avatarImageName: avatarImageName
        )
    }
}

// MARK: - Сервис управления конфигурациями
class AssistantsService {
    
    private let config: Realm.Configuration
    
    init() {
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: AssistantConfigObject.className()) { oldObject, newObject in
                        if newObject?["assistantName"] == nil {
                            newObject?["assistantName"] = "AI chat"
                        }
                        if newObject?["aiModel"] == nil {
                            newObject?["aiModel"] = ""
                        }
                        if newObject?["avatarImageName"] == nil {
                            newObject?["avatarImageName"] = ""
                        }
                    }
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
        self.config = config
        
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
        // Сбрасываем неиспользуемые кэши Realm, чтобы отдать память системе
        let _ = try? Realm().invalidate()
    }
    
    // MARK: - Безопасная инициализация Realm
    private func getRealm() -> Realm? {
        // 1. Пробуем открыть основную дисковую базу
        do {
            return try Realm(configuration: config)
        } catch {
            AnalyticService.shared.logEvent(
                name: "realm main init failed",
                properties: ["error": "\(error)"]
            )
            
            // 2. Фолбек: In-Memory база с защитой от ошибок миграции
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackAssistantsRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                // 3. Ультра-фолбек: База с уникальным ID, чтобы обойти конфликты старых потоков
                let ultraID = "UltraFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    // 4. Полный OOM: На девайсе физически нет оперативной памяти.
                    // Возвращаем nil, предотвращая критический краш приложения.
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL: Total OOM. Realm disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }
    
    // MARK: - CRUD Операции
    
    // Добавление новой конфигурации
    func addConfig(_ config: AssistantConfig) {
        guard let realm = getRealm() else {
            print("Failed to add config: Realm is unavailable (OOM)")
            return
        }
        
        let id = config.id ?? UUID().uuidString
        var newConfig = config
        newConfig.id = id
        let object = AssistantConfigObject(id: id, config: newConfig)
        
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("Failed to add config write transaction: \(error)")
        }
    }
    
    // Обновление конфигурации по ID
    func updateConfig(id: String, config: AssistantConfig) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id) else {
            print("Config with ID \(id) not found")
            return
        }
        
        do {
            try realm.write {
                object.assistantName = config.assistantName
                object.aiModel = config.aiModel.rawValue
                object.tone = config.tone.rawValue.localize()
                object.style = config.style.rawValue.localize()
                object.expertise = config.expertise.rawValue.localize()
                object.assistantInfo = config.assistantInfo
                object.userInfo = config.userInfo
                object.updatedAt = Date()
            }
        } catch {
            print("Failed to update config: \(error)")
        }
    }
    
    // Удаление конфигурации по ID
    func deleteConfig(id: String) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id) else {
            return
        }
        
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            print("Failed to delete config: \(error)")
        }
    }
    
    // Получение всех конфигураций, отсортированных по updatedAt
    func getAllConfigs() -> [AssistantConfig] {
        guard let realm = getRealm() else {
            // При жестком сбое возвращаем пустой список, чтобы UI остался стабилен
            return []
        }
        
        let objects = realm.objects(AssistantConfigObject.self)
            .sorted(byKeyPath: "updatedAt", ascending: false)
        
        return objects.map { $0.toAssistantConfig() }
    }
    
    // Получение конфигурации по ID
    func getConfig(id: String) -> AssistantConfig? {
        guard let realm = getRealm() else { return nil }
        return realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id)?.toAssistantConfig()
    }
}
