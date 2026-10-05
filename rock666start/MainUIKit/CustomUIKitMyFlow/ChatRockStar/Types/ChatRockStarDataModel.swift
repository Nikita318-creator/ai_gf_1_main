import Foundation

struct ChatRockStarDataModel {
    var id: String?
    var isAudio: Bool = false
    var emogi: String? = nil
    let authoreRole: String
    let theMessage: String
    var isWaiting: Bool = false
    var mediaFileID: String = ""
}
