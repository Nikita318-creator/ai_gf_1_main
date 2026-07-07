//
//  AdditionalVideosService.swift
//  ChatBot20
//
//  Created by Mikita on 07/07/2026.
//

import UIKit
import RealmSwift

class LocalVideoModel: Object {
    @Persisted(primaryKey: true) var id: Int // Порядковый номер видео (1, 2, 3...)
    @Persisted var localPath: String        // Путь к файлу в папке Library
}

class AdditionalVideosService {
    
    static let shared = AdditionalVideosService()
    private let config: Realm.Configuration
    private let lastDownloadedKey = "last_downloaded_video_index"
    
    // Геттер для Realm на текущем потоке (без try!)
    private var realm: Realm? {
        return try? Realm(configuration: config)
    }
    
    private init() {
        // Настройка миграций и конфига
        let mainConfig = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 { /* Логика миграции */ }
            }
        )
        
        // Проверка валидности конфига
        do {
            _ = try Realm(configuration: mainConfig)
            self.config = mainConfig
        } catch {
            print("Realm error: \(error). Using fallback.")
            self.config = Realm.Configuration(inMemoryIdentifier: "AdditionalVideoServiceFallback")
        }
        
        createLibraryFolderIfNeeded()
    }
    
    // MARK: - Internal Interface
    
    /// ТЕПЕРЬ ВОЗВРАЩАЕТ String? (имя файла, например "1.mp4")
    func getNextVideo() async -> String? {
        let lastIndex = UserDefaults.standard.integer(forKey: lastDownloadedKey)
        
        if lastIndex >= ConfigService.shared.additionalVideosCount {
            return getRandomCachedVideoName()
        }
        
        let nextIndex = lastIndex + 1
        return await downloadAndSaveVideo(index: nextIndex)
    }
    
    /// Тот самый метод для UI: собирает полный актуальный путь из имени файла
    func getFullUrl(for fileName: String) -> URL {
        return getLibraryDirectory().appendingPathComponent(fileName)
    }
    
    // MARK: - Private Logic
    
    private func downloadAndSaveVideo(index: Int) async -> String? {
        let fileName = "\(index).mp4"
        guard let url = URL(string: ConfigService.shared.additionalVideos + fileName) else { return nil }
        
        do {
            let tempLocation: URL
            if #available(iOS 15.0, *) {
                let (tempLocationURL, _) = try await URLSession.shared.download(from: url)
                tempLocation = tempLocationURL
            } else {
                tempLocation = try await withCheckedThrowingContinuation { continuation in
                    let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let localURL = localURL {
                            continuation.resume(returning: localURL)
                        } else {
                            continuation.resume(throwing: URLError(.unknown))
                        }
                    }
                    task.resume()
                }
            }
            let destinationURL = getLibraryDirectory().appendingPathComponent(fileName)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempLocation, to: destinationURL)
            
            // Отключаем iCloud Sync
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableURL = destinationURL
            try mutableURL.setResourceValues(resourceValues)
            
            // Сохранение в Realm (Потокобезопасно)
            let currentConfig = self.config
            try await Task.detached {
                let backgroundRealm = try Realm(configuration: currentConfig)
                let model = LocalVideoModel()
                model.id = index
                model.localPath = fileName
                
                try backgroundRealm.write {
                    backgroundRealm.add(model, update: .modified)
                }
            }.value
            
            UserDefaults.standard.set(index, forKey: lastDownloadedKey)
            return fileName // Возвращаем только имя
            
        } catch {
            print("Failed to process video \(index): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getRandomCachedVideoName() -> String? {
        guard let allVideos = realm?.objects(LocalVideoModel.self), !allVideos.isEmpty else { return nil }
        guard let randomVideo = allVideos.randomElement() else { return nil }
        
        return randomVideo.localPath // Возвращаем только имя из базы
    }
    
    // MARK: - Helpers
    
    private func getLibraryDirectory() -> URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AdditionalVideos")
    }
    
    private func createLibraryFolderIfNeeded() {
        let folderURL = getLibraryDirectory()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableURL = folderURL
            try? mutableURL.setResourceValues(values)
        }
    }
}
