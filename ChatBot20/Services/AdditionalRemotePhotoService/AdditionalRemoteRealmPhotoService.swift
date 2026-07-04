//
//  AdditionalRemoteRealmPhotoService.swift
//  ChatBot20
//
//  Created by Mikita on 21/03/2026.
//

import RealmSwift
import UIKit

class AdditionalRemoteRealmPhotoService {
    
    static let shared = AdditionalRemoteRealmPhotoService()
    
    // Убираем глобальное свойство realm, чтобы избежать проблем с потоками
    private var config: Realm.Configuration
    
    private init() {
        self.config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 { }
            }
        )
    }

    // Вспомогательный метод для получения инстанса в текущем потоке
    private func getRealm() -> Realm {
        do {
            return try Realm(configuration: config)
        } catch {
            // Если основной Realm не инициализировался — падаем в Memory Fallback
            AnalyticService.shared.logEvent(name: "realm_fallback_activated", properties: ["error": "\(error)"])
            
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "FallbackAdditionalRemoteRealm")
            return try! Realm(configuration: fallbackConfig)
        }
    }
    
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        let realm = getRealm() // Получаем инстанс для текущего потока
        let cachedImage = CachedImage()
        cachedImage.urlString = urlString
        cachedImage.imageName = imageName
        cachedImage.imageData = data
        
        do {
            try realm.write {
                // Используем modified, чтобы не плодить дубликаты, если модель позволяет
                realm.add(cachedImage)
            }
        } catch {
            print("Realm Write Error: \(error)")
        }
    }
    
    func getImage(by name: String) -> UIImage? {
        // Фильтрация через Realm быстрее, чем через Swift Array
        let object = getRealm().objects(CachedImage.self).filter("imageName == %@", name).first
        guard let data = object?.imageData else { return nil }
        return UIImage(data: data)
    }
    
    func isImageCached(by name: String) -> Bool {
        // .isEmpty работает быстрее, чем поиск первого объекта
        return !getRealm().objects(CachedImage.self).filter("imageName == %@", name).isEmpty
    }
}
