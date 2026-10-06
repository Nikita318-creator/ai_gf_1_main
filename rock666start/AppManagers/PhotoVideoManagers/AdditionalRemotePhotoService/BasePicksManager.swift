import Foundation
import RealmSwift
import UIKit

class BasePicksObject: Object {
    @Persisted(primaryKey: true) var picName: String = ""
    @Persisted var filePath: String = ""
}

class BasePicksManager {
    
    static let shared = BasePicksManager()
    
    private let storageCoordinator: FileStorageCoordinator
    private let realmProvider: RealmContextProvider
    
    private init() {
        self.storageCoordinator = FileStorageCoordinator(folderName: "AdditionalRemotePhotos")
        
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldVersion in
                if oldVersion < 4 { }
            }
        )
        self.realmProvider = RealmContextProvider(configuration: config)
    }

    func saveImage(for urlString: String, with imageName: String, data: Data) {
        let targetURL = storageCoordinator.locateFile(named: imageName)
        
        guard storageCoordinator.write(data: data, to: targetURL) else { return }
        
        let realm = realmProvider.produceRealm()
        let record = BasePicksObject()
        record.picName = imageName
        record.filePath = urlString
        
        try? realm.write {
            realm.add(record, update: .modified)
        }
    }
    
    func getImage(by name: String) -> UIImage? {
        let fileURL = storageCoordinator.locateFile(named: name)
        
        guard storageCoordinator.exists(at: fileURL),
              let binaryData = storageCoordinator.read(from: fileURL) else {
            return nil
        }
        
        return UIImage(data: binaryData)
    }
    
    func isImageCached(by name: String) -> Bool {
        let fileURL = storageCoordinator.locateFile(named: name)
        guard storageCoordinator.exists(at: fileURL) else { return false }
        
        let realm = realmProvider.produceRealm()
        return realm.object(ofType: BasePicksObject.self, forPrimaryKey: name) != nil
    }
}
