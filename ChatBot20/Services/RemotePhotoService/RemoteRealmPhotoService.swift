//
//  RemoteRealmPhotoService.swift
//  ChatBot20
//
//  Created by Mikita on 16.09.25.
//

import RealmSwift
import UIKit

// MARK: - Модель для Realm
class CachedImage: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var urlString: String = ""
    @Persisted var imageName: String = ""
    @Persisted var imageData: Data?
}

// MARK: - Сервис кэширования фотографий
class RemoteRealmPhotoService {
    
    static let shared = RemoteRealmPhotoService()
    
    private let config: Realm.Configuration
    
    private init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    // Твоя логика миграций (оставляем без изменений)
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
                name: "realm photo main init failed",
                properties: ["error": "\(error)"]
            )
            
            // 2. Фолбек: In-Memory база с защитой от ошибок миграции
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackRemoteRealmPhotoRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                // 3. Ультра-фолбек: База с уникальным ID, чтобы обойти конфликты старых потоков
                let ultraID = "UltraPhotoFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    // 4. Полный OOM: На девайсе физически нет оперативной памяти.
                    // Возвращаем nil, предотвращая критический краш приложения.
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL: Total OOM. Photo Realm disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }
    
    // MARK: - Публичные методы работы с кэшем
    
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        guard let realm = getRealm() else {
            print("Failed to save image: Realm is unavailable (OOM)")
            return
        }
        
        // Проверяем, нет ли уже такой картинки, чтобы не плодить дубликаты
        if realm.objects(CachedImage.self).filter("imageName == %@", imageName).isEmpty {
            let cachedImage = CachedImage()
            cachedImage.urlString = urlString
            cachedImage.imageName = imageName
            cachedImage.imageData = data
            
            do {
                try realm.write {
                    realm.add(cachedImage)
                }
            } catch {
                print("Failed to save image: \(error.localizedDescription)")
            }
        }
    }
    
    func getImage(by name: String) -> UIImage? {
        guard let realm = getRealm() else { return nil }
        
        let object = realm.objects(CachedImage.self).filter("imageName == %@", name).first
        guard let data = object?.imageData else { return nil }
        return UIImage(data: data)
    }
    
    /// Проверяет, пуст ли кэш (возвращает true, если есть хотя бы одна картинка)
    func hasAnyCachedImages() -> Bool {
        guard let realm = getRealm() else { return false }
        return !realm.objects(CachedImage.self).isEmpty
    }
    
    /// Возвращает только массив имен всех закэшированных картинок (без самих данных)
    func getAllCachedImageNames() -> [String] {
        guard let realm = getRealm() else { return [] }
        
        // .value(forKey:) на результатах запроса в Realm вытаскивает только конкретное поле
        // Это в разы быстрее и не грузит imageData в память
        let names = realm.objects(CachedImage.self).value(forKey: "imageName") as? [String]
        return names ?? []
    }
    
    func isImageCached(by name: String) -> Bool {
        guard let realm = getRealm() else { return false }
        
        // .isEmpty работает быстрее всего, так как не загружает сам объект в память
        return !realm.objects(CachedImage.self).filter("imageName == %@", name).isEmpty
    }
}
