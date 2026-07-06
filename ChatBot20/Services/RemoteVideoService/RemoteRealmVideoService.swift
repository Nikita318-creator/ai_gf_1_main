import Foundation
import RealmSwift
import UIKit

// MARK: - Обновленная модель для Realm
class CachedVideo: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var urlString: String
    @Persisted var videoName: String
    @Persisted var localFileName: String // Храним ТОЛЬКО имя файла на диске
    @Persisted var thumbnailData: Data?  // Маленькую превьюшку (до 100-200 КБ) в базе хранить можно
}

// MARK: - Сервис кэширования видео
class RemoteRealmVideoService {
    static let shared = RemoteRealmVideoService()
    
    private let config: Realm.Configuration
    
    // Директория для хранения видеофайлов (папка Caches очищается системой при нехватке места на диске)
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0] // именно cachesDirectory чтоб иос сам чистил за собой
    }
    
    private init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // При переходе на новую схему старые объекты лучше удалить/мигрировать,
                // так как поле videoData удалено.
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
            AnalyticService.shared.logEvent(name: "realm video main init failed", properties: ["error": "\(error)"])
            
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackRemoteVideoRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                let ultraID = "UltraVideoFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL OOM: RemoteVideoRealm completely disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }
    
    // MARK: - Save
    
    /// Сохраняет видео в файловую систему, а метаданные — в Realm
    func saveVideo(urlString: String, name: String, data: Data) {
        // 1. Генерируем уникальное имя файла на диске (чтобы избежать конфликтов спецсимволов)
        let fileExtension = (urlString as NSString).pathExtension.isEmpty ? "mp4" : (urlString as NSString).pathExtension
        let localFileName = "\(UUID().uuidString).\(fileExtension)"
        let fileURL = cachesDirectory.appendingPathComponent(localFileName)
        
        // 2. Пишем тяжелые данные напрямую в файловую систему (работает вне Realm и RAM-эффективно)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Не удалось записать видеофайл на диск: \(error)")
            return
        }
        
        // 3. Быстро делаем превью (оно маленькое, его можно в базу)
        let thumbnailImage = data.generateVideoThumbnail()
        let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.7)
        
        // 4. Записываем ссылку в Realm
        guard let realm = getRealm() else {
            print("⚠️ Realm недоступен. Файл на диске сохранен, но в базу не внесен.")
            return
        }
        
        let video = CachedVideo()
        video.urlString = urlString
        video.videoName = name
        video.localFileName = localFileName
        video.thumbnailData = thumbnailData
        
        do {
            try realm.write {
                realm.add(video)
            }
        } catch {
            print("❌ Ошибка сохранения метаданных в Realm: \(error)")
            // Если база легла, зачищаем сиротский файл с диска
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Read
    
    /// Возвращает локальный URL-путь к файлу для AVPlayer
    func getVideoLocalURL(name: String) -> URL? {
        guard let realm = getRealm() else { return nil }
        
        guard let videoObject = realm.objects(CachedVideo.self).filter("videoName == %@", name).first else {
            return nil
        }
        
        let fileURL = cachesDirectory.appendingPathComponent(videoObject.localFileName)
        
        // Проверяем, существует ли файл физически (iOS могла очистить папку Caches)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            // Если файл удален системой, убираем «битую» запись из Realm
            try? realm.write {
                realm.delete(videoObject)
            }
            return nil
        }
    }
    
    func getThumbnailData(name: String) -> Data? {
        guard let realm = getRealm() else { return nil }
        return realm.objects(CachedVideo.self).filter("videoName == %@", name).first?.thumbnailData
    }
    
    func isVideoCached(name: String) -> Bool {
        return getVideoLocalURL(name: name) != nil
    }
    
    // MARK: - Delete (Бонус)
    
    /// Правильное удаление кэша: и файл с диска, и запись из базы
    func deleteVideo(name: String) {
        guard let realm = getRealm() else { return }
        guard let videoObject = realm.objects(CachedVideo.self).filter("videoName == %@", name).first else { return }
        
        let fileURL = cachesDirectory.appendingPathComponent(videoObject.localFileName)
        try? FileManager.default.removeItem(at: fileURL) // Удаляем файл
        
        do {
            try realm.write {
                realm.delete(videoObject) // Удаляем запись
            }
        } catch {
            print("❌ Ошибка удаления из Realm: \(error)")
        }
    }
}
