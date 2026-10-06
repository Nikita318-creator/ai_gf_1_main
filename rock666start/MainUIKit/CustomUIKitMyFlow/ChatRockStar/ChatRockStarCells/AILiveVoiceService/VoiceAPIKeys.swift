import Foundation

enum VoiceAPIKeys {
    static let baseHost = "https://texttospeech.googleapis.com/v1/text:synthesize"
    
    enum Payload {
        static let encoding = "audioEncoding"
        static let rate = "speakingRate"
        static let pitch = "pitch"
        static let input = "input"
        static let text = "text"
        static let voice = "voice"
        static let langCode = "languageCode"
        static let name = "name"
        static let audioConfig = "audioConfig"
        static let content = "audioContent"
    }
}
