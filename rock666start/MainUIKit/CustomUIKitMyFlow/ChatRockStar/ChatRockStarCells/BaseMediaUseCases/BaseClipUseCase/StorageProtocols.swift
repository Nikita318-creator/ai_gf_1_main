import Foundation

protocol CacheDataPersisting: AnyObject {
    func storeMediaResource(sourceURL: String, entityIdentifier: String, rawPayload: Data)
    func resolveMediaDiskPath(entityIdentifier: String) -> URL?
    func fetchPreviewRepresentation(entityIdentifier: String) -> Data?
    func verifyPresence(entityIdentifier: String) -> Bool
    func purgeMediaResource(entityIdentifier: String)
}

protocol RealmDatabaseServicing: AnyObject {
    func executeStorageOperation(_ block: (Any) -> Void)
    func obtainDiskPath(for identifier: String) -> String?
    func obtainImageData(for identifier: String) -> Data?
    func removeEntityRecord(identifier: String) -> String?
}
