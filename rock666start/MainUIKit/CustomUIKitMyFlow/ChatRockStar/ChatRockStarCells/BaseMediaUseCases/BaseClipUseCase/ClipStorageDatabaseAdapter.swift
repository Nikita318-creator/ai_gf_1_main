import Foundation
import RealmSwift

final class ClipStorageDatabaseAdapter: RealmDatabaseServicing {
    private let coreConfiguration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.coreConfiguration = configuration
    }

    private func createRealmInstance() -> Realm? {
        do {
            return try Realm(configuration: coreConfiguration)
        } catch {
            var secondaryConfig = Realm.Configuration(inMemoryIdentifier: "ClipStorageDatabaseAdapter")
            secondaryConfig.deleteRealmIfMigrationNeeded = true
            
            do {
                return try Realm(configuration: secondaryConfig)
            } catch {
                let token = "UltraVideoFallback_\(UUID().uuidString)"
                var emergencyConfig = Realm.Configuration(inMemoryIdentifier: token)
                emergencyConfig.deleteRealmIfMigrationNeeded = true
                
                return try? Realm(configuration: emergencyConfig)
            }
        }
    }

    func executeStorageOperation(_ block: (Any) -> Void) {
        guard let realm = createRealmInstance() else { return }
        block(realm)
    }

    func obtainDiskPath(for identifier: String) -> String? {
        guard let realm = createRealmInstance() else { return nil }
        return realm.objects(BaseClipObject.self).filter("videoName == %@", identifier).first?.fileName
    }

    func obtainImageData(for identifier: String) -> Data? {
        guard let realm = createRealmInstance() else { return nil }
        return realm.objects(BaseClipObject.self).filter("videoName == %@", identifier).first?.preview
    }

    func removeEntityRecord(identifier: String) -> String? {
        guard let realm = createRealmInstance() else { return nil }
        guard let entity = realm.objects(BaseClipObject.self).filter("videoName == %@", identifier).first else { return nil }
        let fileName = entity.fileName
        try? realm.write {
            realm.delete(entity)
        }
        return fileName
    }
}
