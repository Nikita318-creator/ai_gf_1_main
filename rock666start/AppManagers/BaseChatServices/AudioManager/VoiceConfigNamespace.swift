import Foundation

enum VoiceConfigNamespace {
    struct VoiceConfig {
        let langTag: String
        let voiceName: String
        let pitch: Double?
    }
}

typealias VoiceConfig = VoiceConfigNamespace.VoiceConfig
