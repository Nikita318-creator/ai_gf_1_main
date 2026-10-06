import Foundation
import RealmSwift

struct FileStorageCoordinator {
    let baseDirectory: URL
    let manager = FileManager.default
    
    init(folderName: String) {
        let cachesURL = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.baseDirectory = cachesURL.appendingPathComponent(folderName, isDirectory: true)
        try? manager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }
    
    func locateFile(named fileName: String) -> URL {
        return baseDirectory.appendingPathComponent("\(fileName).jpg")
    }
    
    func exists(at url: URL) -> Bool {
        return manager.fileExists(atPath: url.path)
    }
    
    func write(data: Data, to url: URL) -> Bool {
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
    
    func read(from url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }
}

struct RealmContextProvider {
    let configuration: Realm.Configuration
    
    func produceRealm() -> Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            let fallback = Realm.Configuration(inMemoryIdentifier: "FallbackAdditionalRemoteRealm")
            return try! Realm(configuration: fallback)
        }
    }
}
