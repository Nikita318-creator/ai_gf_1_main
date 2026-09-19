import Foundation
import UIKit
import RealmSwift

struct AIGirlfriendsConfig: Codable {
    var id: String?
    var assistantName: String = ""
    var assistantInfo: String = ""
    var avatarImageName: String = ""
}

// MARK: - Модель для Realm
class AIGirlfriendsConfigObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var assistantName: String
    @Persisted var assistantInfo: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var avatarImageName: String
    
    // Инициализатор
    convenience init(id: String, config: AIGirlfriendsConfig, isPremium: Bool = false) {
        self.init()
        self.id = id
        self.assistantName = config.assistantName
        self.assistantInfo = config.assistantInfo
        self.createdAt = Date()
        self.updatedAt = Date()
        self.avatarImageName = config.avatarImageName
    }
    
    // Конвертация в AssistantConfig
    func toAssistantConfig() -> AIGirlfriendsConfig {
        return AIGirlfriendsConfig(
            id: id,
            assistantName: assistantName,
            assistantInfo: assistantInfo,
            avatarImageName: avatarImageName
        )
    }
}

// MARK: - Сервис управления конфигурациями
class AIGirlfriendsManager {
    
    private let config: Realm.Configuration
    
    init() {
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: AIGirlfriendsConfigObject.className()) { oldObject, newObject in
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
    func addConfig(_ config: AIGirlfriendsConfig) {
        guard let realm = getRealm() else {
            print("Failed to add config: Realm is unavailable (OOM)")
            return
        }
        
        let id = config.id ?? UUID().uuidString
        var newConfig = config
        newConfig.id = id
        let object = AIGirlfriendsConfigObject(id: id, config: newConfig)
        
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("Failed to add config write transaction: \(error)")
        }
    }
    
    // Обновление конфигурации по ID
    func updateConfig(id: String, config: AIGirlfriendsConfig) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: AIGirlfriendsConfigObject.self, forPrimaryKey: id) else {
            print("Config with ID \(id) not found")
            return
        }
        
        do {
            try realm.write {
                object.assistantName = config.assistantName
                object.assistantInfo = config.assistantInfo
                object.updatedAt = Date()
            }
        } catch {
            print("Failed to update config: \(error)")
        }
    }
    
    // Удаление конфигурации по ID
    func deleteConfig(id: String) {
        guard let realm = getRealm() else { return }
        guard let object = realm.object(ofType: AIGirlfriendsConfigObject.self, forPrimaryKey: id) else {
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
    func getAllConfigs() -> [AIGirlfriendsConfig] {
        guard let realm = getRealm() else {
            // При жестком сбое возвращаем пустой список, чтобы UI остался стабилен
            return []
        }
        
        let objects = realm.objects(AIGirlfriendsConfigObject.self)
            .sorted(byKeyPath: "updatedAt", ascending: false)
        
        return objects.map { $0.toAssistantConfig() }
    }
    
    // Получение конфигурации по ID
    func getConfig(id: String) -> AIGirlfriendsConfig? {
        guard let realm = getRealm() else { return nil }
        return realm.object(ofType: AIGirlfriendsConfigObject.self, forPrimaryKey: id)?.toAssistantConfig()
    }
}
