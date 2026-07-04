import Foundation
import UIKit
import RealmSwift

// MARK: - Модель для Realm
class StreakObject: Object {
    @Persisted(primaryKey: true) var chatID: String
    @Persisted var count: Int = 0
    @Persisted var lastUpdateDate: Date?

    convenience init(chatID: String, count: Int, lastUpdateDate: Date?) {
        self.init()
        self.chatID = chatID
        self.count = count
        self.lastUpdateDate = lastUpdateDate
    }
}

enum StreakType {
    case streakStarted
    case streakEnded
    case streakContinued
}

// MARK: - Сервис стриков
class StreaksService {
    static let shared = StreaksService()
    
    private let config: Realm.Configuration

    private init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // Если понадобятся миграции для StreakObject — добавишь сюда
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
                name: "realm main init failed (streaks)",
                properties: ["error": "\(error)"]
            )
            
            // 2. Фолбек: In-Memory база с защитой от ошибок миграции
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackStreaksRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                // 3. Ультра-фолбек: База с уникальным ID, чтобы обойти конфликты старых потоков
                let ultraID = "UltraFallback_Streaks_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    // 4. Полный OOM: На девайсе физически нет оперативной памяти.
                    // Возвращаем nil, предотвращая критический краш приложения с try!
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL: Total OOM. Streaks Realm disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }

    // MARK: - Публичные методы
    
    @discardableResult
    func checkAndUpdateStreak(for chatID: String) -> StreakType? {
        // Если Realm полностью лег из-за OOM, мягко выходим без краша
        guard let realm = getRealm() else {
            print("Failed to check streak: Realm is unavailable (OOM)")
            return nil
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Ищем объект или создаем новый в памяти (пока не привязанный к Realm)
        let streak = realm.object(ofType: StreakObject.self, forPrimaryKey: chatID)
                     ?? StreakObject(chatID: chatID, count: 0, lastUpdateDate: nil)

        do {
            return try realm.write {
                var currentStreakType: StreakType?
                
                if let lastDate = streak.lastUpdateDate {
                    if calendar.isDateInToday(lastDate) {
                        // 1. Уже сегодня заходил.
                    } else if calendar.isDateInYesterday(lastDate) {
                        // 2. Стрик продолжается
                        streak.count += 1
                        streak.lastUpdateDate = now
                        currentStreakType = .streakContinued
                    } else {
                        // 3. Пропустил день
                        streak.count = 1
                        streak.lastUpdateDate = now
                        currentStreakType = .streakEnded
                    }
                } else {
                    // 4. Самое первое сообщение
                    streak.count = 1
                    streak.lastUpdateDate = now
                    currentStreakType = .streakStarted
                }
                
                realm.add(streak, update: .modified)
                return currentStreakType
            }
        } catch {
            print("Failed to write streak: \(error)")
            return nil
        }
    }

    func getStreakCount(for chatID: String) -> Int {
        guard let realm = getRealm() else { return 0 }
        return realm.object(ofType: StreakObject.self, forPrimaryKey: chatID)?.count ?? 0
    }
}
