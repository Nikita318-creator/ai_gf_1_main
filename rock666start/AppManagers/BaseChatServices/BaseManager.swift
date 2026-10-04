import UIKit

class BaseManager {
    static let shared = BaseManager()
    
    var currentAssistant: AIGirlfriendsConfig?
    var notFriendProfileAvatar: UIImage?
    var needOpenPaywall: Bool = false
    var isFirstMessageInChat: Bool = false
    var isAudioMessagesMode: Bool = false
    var is3daysPass: Bool = false
    var currentLanguage = ""
    var viewedStoriesId: [String] = []
    var currentAIMessageType: AIMessageType = .typing
    var needOpenChatWithId: String?
    var messagesSendCount: Int = 0
}
