import UIKit

class MyGovnoSingltone {
    static let shared = MyGovnoSingltone()
    
    var selectedAICompanion: AIGirlfriendsConfig?
    var isExpectedPaywall: Bool = false
    var currentMessageFirst: Bool = false
    var voiceChatToggleOn: Bool = false
    var userLang = ""
    var countOfMessagesInOngoingChat: Int = 0
}
