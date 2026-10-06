import Foundation
import RealmSwift

final class CharactersChatObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var authorId: String
    @Persisted var authorRole: String
    @Persisted var theMessage: String
    @Persisted var isWaiting: Bool
    @Persisted var isAudio: Bool
    @Persisted var mediaFileID: String
    @Persisted var emogi: String?
    @Persisted var dateOfCriation: Date
    @Persisted var dateOfUpdation: Date

    convenience init(message: ChatRockStarDataModel, assistantId: String, id: String) {
        self.init()
        self.id = id
        self.authorId = assistantId
        self.authorRole = message.authoreRole
        self.theMessage = message.theMessage
        self.isWaiting = message.isWaiting
        self.isAudio = message.isAudio
        self.mediaFileID = message.mediaFileID
        self.dateOfCriation = Date()
        self.dateOfUpdation = Date()
        self.emogi = message.emogi
    }

    func toMessage() -> ChatRockStarDataModel {
        return ChatRockStarDataModel(
            id: id,
            isAudio: isAudio,
            emogi: emogi,
            authoreRole: authorRole,
            theMessage: theMessage,
            isWaiting: isWaiting,
            mediaFileID: mediaFileID
        )
    }
}
