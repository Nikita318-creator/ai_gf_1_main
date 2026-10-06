import Foundation
import RealmSwift

enum CharactersSchemaMigrationFactory {
    static var schemaVersion: UInt64 { 1 }

    static func buildConfiguration() -> Realm.Configuration {
        return Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldVersion in
                if oldVersion < 4 {
                    migration.enumerateObjects(ofType: CharactersChatObject.className()) { oldObj, newObj in
                        if oldObj?["authorId"] == nil || (oldObj?["authorId"] as? String)?.isEmpty == true {
                            newObj?["authorId"] = ""
                        }
                    }
                    migration.enumerateObjects(ofType: CharactersObject.className()) { oldObj, newObj in
                        if oldObj?["mediaFileID"] == nil || (oldObj?["mediaFileID"] as? String)?.isEmpty == true {
                            newObj?["mediaFileID"] = ""
                        }
                    }
                }
            }
        )
    }
}

