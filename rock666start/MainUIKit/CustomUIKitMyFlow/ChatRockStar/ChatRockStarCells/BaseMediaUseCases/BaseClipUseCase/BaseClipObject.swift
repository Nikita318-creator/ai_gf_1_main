import Foundation
import RealmSwift

class BaseClipObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var path: String
    @Persisted var clipName: String
    @Persisted var fileName: String
    @Persisted var preview: Data?
}
