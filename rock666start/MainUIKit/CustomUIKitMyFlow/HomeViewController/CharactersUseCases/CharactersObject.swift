import Foundation
import RealmSwift

final class CharactersObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String
    @Persisted var baseInfo: String
    @Persisted var dateOfCreation: Date
    @Persisted var dateOfUpdation: Date
    @Persisted var authorIcon: String

    convenience init(id: String, config: CharactersDataModel, isPremium: Bool = false) {
        self.init()
        self.id = id
        self.name = config.name
        self.baseInfo = config.baseInfo
        self.dateOfCreation = Date()
        self.dateOfUpdation = Date()
        self.authorIcon = config.authorIcon
    }

    func toAssistantConfig() -> CharactersDataModel {
        return CharactersDataModel(
            id: id,
            name: name,
            baseInfo: baseInfo,
            authorIcon: authorIcon
        )
    }
}
