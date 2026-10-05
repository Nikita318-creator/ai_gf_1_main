import UIKit

enum ChatMessageReaction: String, CaseIterable {
    case heart = "heart"
    case up = "up"
    case down = "down"
    case laugh = "laugh"
    case cry = "cry"
    case angry = "angry"

    var symbol: String {
        switch self {
        case .heart: return "❤️"
        case .up: return "👍"
        case .down: return "👎"
        case .laugh: return "😂"
        case .cry: return "😭"
        case .angry: return "😡"
        }
    }

    var isPositive: Bool {
        switch self {
        case .heart, .up, .laugh: return true
        default: return false
        }
    }
}
