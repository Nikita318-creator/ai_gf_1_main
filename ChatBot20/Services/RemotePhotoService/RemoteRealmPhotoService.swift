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
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Потокобезопасная очередь для операций с диском, чтобы избежать состояния гонки (Race Condition)
    private let fileQueue = DispatchQueue(label: "com.app.photoCache.fileQueue", qos: .utility)
    
    private init() {
        // Настраиваем директорию в Library/Caches
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesURL.appendingPathComponent("RemoteRealmPhotos", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // ВЕРСИЮ СХЕМЫ НЕ МЕНЯЕМ. Блок миграции остается твоим.
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    // Твоя старая логика миграций (без изменений)
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
    
    private func getRealm() -> Realm? {
        do {
            return try Realm(configuration: config)
        } catch {
            AnalyticService.shared.logEvent(name: "realm photo main init failed", properties: ["error": "\(error)"])
            
            var fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackRemoteRealmPhotoRealm")
            fallbackConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: fallbackConfig)
            } catch {
                let ultraID = "UltraPhotoFallback_\(UUID().uuidString)"
                var ultraFallbackConfig = Realm.Configuration(inMemoryIdentifier: ultraID)
                ultraFallbackConfig.deleteRealmIfMigrationNeeded = true
                
                do {
                    return try Realm(configuration: ultraFallbackConfig)
                } catch {
                    WebHookAnaliticksService.shared.sendErrorReport(
                        messageText: "CRITICAL: Total OOM. Photo Realm disabled.\n user: \(WebHookAnaliticksService.shared.randomID)"
                    )
                    return nil
                }
            }
        }
    }
    
    private func getFilePath(for imageName: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(imageName).jpg")
    }
    
    // MARK: - Публичные методы контракта
    
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        guard let realm = getRealm() else { return }
        
        // Проверяем существование записи
        if realm.objects(CachedImage.self).filter("imageName == %@", imageName).isEmpty {
            
            // 1. Сначала сохраняем в Realm (как и раньше), чтобы UI сразу узнал, что картинка есть
            let cachedImage = CachedImage()
            cachedImage.id = ObjectId.generate()
            cachedImage.urlString = urlString
            cachedImage.imageName = imageName
            cachedImage.imageData = data // Временно пишем в БД, чтобы UI не поймал nil в момент загрузки
            
            do {
                try realm.write {
                    realm.add(cachedImage)
                }
            } catch {
                print("Failed to save image to Realm: \(error.localizedDescription)")
                return
            }
            
            // 2. Асинхронно переносим тяжелые данные на диск в отдельном потоке
            let fileURL = getFilePath(for: imageName)
            fileQueue.async { [weak self] in
                guard let self = self else { return }
                
                // Пишем на диск
                guard (try? data.write(to: fileURL, options: .atomic)) != nil else { return }
                
                // Как только файл железно записался на диск — очищаем imageData в Realm, чтобы база худела
                DispatchQueue.main.async {
                    guard let bgRealm = self.getRealm(),
                          let objectToClean = bgRealm.objects(CachedImage.self).filter("imageName == %@", imageName).first else { return }
                    
                    try? bgRealm.write {
                        objectToClean.imageData = nil // Вот теперь безопасно зануляем, файл уже на диске
                    }
                }
            }
        }
    }
    
    func getImage(by name: String) -> UIImage? {
        let fileURL = getFilePath(for: name)
        
        // Сценарий 1: Файл уже успешно перенесен и лежит на диске
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        
        // Сценарий 2: Файл еще пишется ИЛИ это старый юзер, у которого картинка внутри Realm
        guard let realm = getRealm(),
              let object = realm.objects(CachedImage.self).filter("imageName == %@", name).first,
              let dbData = object.imageData else {
            return nil
        }
        
        // Если это старый юзер (файла на диске нет, но в БД данные есть) — запускаем фоновый перенос на диск
        let fileURLForLegacy = getFilePath(for: name)
        if !fileManager.fileExists(atPath: fileURLForLegacy.path) {
            fileQueue.async { [weak self] in
                guard let self = self else { return }
                if (try? dbData.write(to: fileURLForLegacy, options: .atomic)) != nil {
                    DispatchQueue.main.async {
                        try? realm.write {
                            object.imageData = nil // Чистим БД после успешного переноса
                        }
                    }
                }
            }
        }
        
        return UIImage(data: dbData)
    }
    
    func hasAnyCachedImages() -> Bool {
        guard let realm = getRealm() else { return false }
        return !realm.objects(CachedImage.self).isEmpty
    }
    
    func getAllCachedImageNames() -> [String] {
        guard let realm = getRealm() else { return [] }
        let names = realm.objects(CachedImage.self).value(forKey: "imageName") as? [String]
        return names ?? []
    }
    
    func isImageCached(by name: String) -> Bool {
        guard let realm = getRealm() else { return false }
        return !realm.objects(CachedImage.self).filter("imageName == %@", name).isEmpty
    }
}
