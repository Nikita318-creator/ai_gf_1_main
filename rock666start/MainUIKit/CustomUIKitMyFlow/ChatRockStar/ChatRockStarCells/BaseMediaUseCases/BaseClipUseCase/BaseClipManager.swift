import Foundation
import RealmSwift
import UIKit

final class BaseClipManager: CacheDataPersisting {
    static let shared = BaseClipManager()

    private let databaseAdapter: RealmDatabaseServicing
    
    private var systemCachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private init(adapter: RealmDatabaseServicing? = nil) {
        let defaultConfig = Realm.Configuration(
            schemaVersion: RealmV.v,
            migrationBlock: { _, _ in }
        )
        self.databaseAdapter = adapter ?? ClipStorageDatabaseAdapter(configuration: defaultConfig)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLowMemoryEvent),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleLowMemoryEvent() {
        databaseAdapter.executeStorageOperation { instance in
            if let realm = instance as? Realm {
                realm.invalidate()
            }
        }
    }

    func storeMediaResource(sourceURL: String, entityIdentifier: String, rawPayload: Data) {
        let fileExtension = (sourceURL as NSString).pathExtension.isEmpty ? "mp4" : (sourceURL as NSString).pathExtension
        let generatedFileName = "\(UUID().uuidString).\(fileExtension)"
        let targetFileURL = systemCachesDirectory.appendingPathComponent(generatedFileName)

        do {
            try rawPayload.write(to: targetFileURL, options: .atomic)
        } catch {
            return
        }

        let previewImage = rawPayload.imagePreviewFromVideo()
        let compressedData = previewImage?.jpegData(compressionQuality: 0.7)

        databaseAdapter.executeStorageOperation { instance in
            guard let realm = instance as? Realm else { return }
            let entity = BaseClipObject()
            entity.path = sourceURL
            entity.clipName = entityIdentifier
            entity.fileName = generatedFileName
            entity.preview = compressedData

            do {
                try realm.write {
                    realm.add(entity)
                }
            } catch {
                try? FileManager.default.removeItem(at: targetFileURL)
            }
        }
    }

    func resolveMediaDiskPath(entityIdentifier: String) -> URL? {
        guard let localFileName = databaseAdapter.obtainDiskPath(for: entityIdentifier) else { return nil }
        let fullPath = systemCachesDirectory.appendingPathComponent(localFileName)

        if FileManager.default.fileExists(atPath: fullPath.path) {
            return fullPath
        } else {
            _ = databaseAdapter.removeEntityRecord(identifier: entityIdentifier)
            return nil
        }
    }

    func fetchPreviewRepresentation(entityIdentifier: String) -> Data? {
        return databaseAdapter.obtainImageData(for: entityIdentifier)
    }

    func verifyPresence(entityIdentifier: String) -> Bool {
        return resolveMediaDiskPath(entityIdentifier: entityIdentifier) != nil
    }

    func purgeMediaResource(entityIdentifier: String) {
        if let removedFileName = databaseAdapter.removeEntityRecord(identifier: entityIdentifier) {
            let targetURL = systemCachesDirectory.appendingPathComponent(removedFileName)
            try? FileManager.default.removeItem(at: targetURL)
        }
    }

    func saveVideo(urlString: String, name: String, data: Data) {
        storeMediaResource(sourceURL: urlString, entityIdentifier: name, rawPayload: data)
    }

    func getVideoLocalURL(name: String) -> URL? {
        return resolveMediaDiskPath(entityIdentifier: name)
    }

    func getThumbnailData(name: String) -> Data? {
        return fetchPreviewRepresentation(entityIdentifier: name)
    }

    func isVideoCached(name: String) -> Bool {
        return verifyPresence(entityIdentifier: name)
    }

    func deleteVideo(name: String) {
        purgeMediaResource(entityIdentifier: name)
    }
}
