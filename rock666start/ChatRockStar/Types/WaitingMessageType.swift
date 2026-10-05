import Foundation

enum WaitingMessageType: String {
    case typing = "typing..."
    case voice = "recording an audio..."
    case pic = "sending a photo..."
    case clip = "recording a video..."
}
