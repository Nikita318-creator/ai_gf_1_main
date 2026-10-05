import UIKit

class MyGovnoSingltone {
    static let shared = MyGovnoSingltone()
    
    var currentAssistant: AIGirlfriendsConfig?
    var notFriendProfileAvatar: UIImage?
    var needOpenPaywall: Bool = false
    var isFirstMessageInChat: Bool = false
    var isAudioMessagesMode: Bool = false
    var currentLanguage = ""
    var viewedStoriesId: [String] = []
    var currentAIMessageType: AIMessageType = .typing
    var messagesSendCount: Int = 0
}
