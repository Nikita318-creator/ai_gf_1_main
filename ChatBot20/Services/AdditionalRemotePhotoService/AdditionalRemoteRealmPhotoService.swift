//
//  AdditionalRemoteRealmPhotoService.swift
//  ChatBot20
//
//  Created by Mikita on 21/03/2026.
//

import RealmSwift
import UIKit

class CachedImageMetadata: Object {
    @Persisted(primaryKey: true) var imageName: String = ""
    @Persisted var urlString: String = ""
}

class AdditionalRemoteRealmPhotoService {
    
    static let shared = AdditionalRemoteRealmPhotoService()
    
    private var config: Realm.Configuration
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 { }
            }
        )
        
        // Настраиваем путь к папке кэша в Library/Caches
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesURL.appendingPathComponent("AdditionalRemotePhotos", isDirectory: true)
        
        // Создаем директорию, если её ещё нет
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func getRealm() -> Realm {
        do {
            return try Realm(configuration: config)
        } catch {
            AnalyticService.shared.logEvent(name: "realm_fallback_activated", properties: ["error": "\(error)"])
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackAdditionalRemoteRealm")
            return try! Realm(configuration: fallbackConfig)
        }
    }
    
    // Вспомогательный метод для получения полного пути к файлу картинки на диске
    private func getFilePath(for imageName: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(imageName).jpg")
    }
    
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        // 1. Сначала сохраняем бинарные данные на диск
        let fileURL = getFilePath(for: imageName)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("File System Write Error: \(error)")
            return // Если файл не записался, в Realm метаданные заносить бессмысленно
        }
        
        // 2. Затем сохраняем легкие метаданные в Realm
        let realm = getRealm()
        let metadata = CachedImageMetadata()
        metadata.imageName = imageName
        metadata.urlString = urlString
        
        do {
            try realm.write {
                // Используем .modified, чтобы перезаписать старый URL, если имя совпало
                realm.add(metadata, update: .modified)
            }
        } catch {
            print("Realm Write Error: \(error)")
        }
    }
    
    func getImage(by name: String) -> UIImage? {
        let fileURL = getFilePath(for: name)
        
        // Проверяем физическое наличие файла на диске
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        // Читаем данные только в момент вызова метода, не нагружая RAM заранее
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    func isImageCached(by name: String) -> Bool {
        let fileURL = getFilePath(for: name)
        
        // Для железной надежности проверяем и запись в Realm, и физический файл на диске
        guard fileManager.fileExists(atPath: fileURL.path) else { return false }
        
        let realm = getRealm()
        return realm.object(ofType: CachedImageMetadata.self, forPrimaryKey: name) != nil
    }
}
