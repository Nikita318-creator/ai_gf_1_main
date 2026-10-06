import Foundation

protocol VoiceConfigurationProviding {
    associatedtype Output
    func resolve(for rawLanguage: String, animeFlag: Bool) -> Output
}

struct VoiceMappingProvider: VoiceConfigurationProviding {
    func resolve(for rawLanguage: String, animeFlag: Bool = false) -> VoiceConfig {
        let localizedTag = rawLanguage.lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let pathComponents = localizedTag.components(separatedBy: "-")
        let primaryCode = pathComponents.first ?? ""
        
        if pathComponents.contains("tw") || pathComponents.contains("hk") || pathComponents.contains("hant") {
            return VoiceConfig(langTag: "zh-TW", voiceName: "zh-TW-Neural2-A", pitch: 1.6)
        }
        if pathComponents.contains("mx") || pathComponents.contains("419") || (primaryCode == "es" && pathComponents.contains("us")) {
            return VoiceConfig(langTag: "es-MX", voiceName: "es-MX-Neural2-A", pitch: 1.8)
        }
        if pathComponents.contains("br") || (primaryCode == "pt" && !pathComponents.contains("pt")) {
            return VoiceConfig(langTag: "pt-BR", voiceName: "pt-BR-Neural2-A", pitch: 1.8)
        }
        if primaryCode == "fil" {
            return VoiceConfig(langTag: "fil-PH", voiceName: "fil-PH-Neural2-A", pitch: 1.8)
        }
        
        switch primaryCode {
        case "en":
            return animeFlag ? VoiceConfig(langTag: "en-US", voiceName: "en-US-Neural2-F", pitch: 4.0)
                             : VoiceConfig(langTag: "en-US", voiceName: "en-US-Journey-F", pitch: nil)
        case "fr":
            return animeFlag ? VoiceConfig(langTag: "fr-FR", voiceName: "fr-FR-Neural2-A", pitch: 3.0)
                             : VoiceConfig(langTag: "fr-FR", voiceName: "fr-FR-Journey-F", pitch: nil)
        case "it":
            return animeFlag ? VoiceConfig(langTag: "it-IT", voiceName: "it-IT-Neural2-A", pitch: 3.0)
                             : VoiceConfig(langTag: "it-IT", voiceName: "it-IT-Journey-F", pitch: nil)
        case "ja":
            return VoiceConfig(langTag: "ja-JP", voiceName: "ja-JP-Neural2-B", pitch: 1.8)
        case "zh":
            return VoiceConfig(langTag: "cmn-CN", voiceName: "cmn-CN-Neural2-F", pitch: 1.8)
        case "de":
            return VoiceConfig(langTag: "de-DE", voiceName: "de-DE-Neural2-C", pitch: 1.5)
        case "es":
            return VoiceConfig(langTag: "es-ES", voiceName: "es-ES-Neural2-C", pitch: 1.8)
        case "ko":
            return VoiceConfig(langTag: "ko-KR", voiceName: "ko-KR-Neural2-A", pitch: 1.6)
        case "ru":
            return VoiceConfig(langTag: "ru-RU", voiceName: "ru-RU-Wavenet-A", pitch: 2.2)
        case "id":
            return VoiceConfig(langTag: "id-ID", voiceName: "id-ID-Neural2-B", pitch: 1.8)
        case "tr":
            return VoiceConfig(langTag: "tr-TR", voiceName: "tr-TR-Wavenet-A", pitch: 1.8)
        case "vi":
            return VoiceConfig(langTag: "vi-VN", voiceName: "vi-VN-Wavenet-A", pitch: 1.8)
        case "th":
            return VoiceConfig(langTag: "th-TH", voiceName: "th-TH-Neural2-C", pitch: 1.6)
        case "nl":
            return VoiceConfig(langTag: "nl-NL", voiceName: "nl-NL-Wavenet-A", pitch: 1.8)
        case "pl":
            return VoiceConfig(langTag: "pl-PL", voiceName: "pl-PL-Wavenet-A", pitch: 2.0)
        case "sv":
            return VoiceConfig(langTag: "sv-SE", voiceName: "sv-SE-Neural2-C", pitch: 1.8)
        case "no":
            return VoiceConfig(langTag: "no-NO", voiceName: "no-NO-Neural2-A", pitch: 1.6)
        case "da":
            return VoiceConfig(langTag: "da-DK", voiceName: "da-DK-Neural2-A", pitch: 1.6)
        case "cs":
            return VoiceConfig(langTag: "cs-CZ", voiceName: "cs-CZ-Neural2-A", pitch: 1.8)
        case "hu":
            return VoiceConfig(langTag: "hu-HU", voiceName: "hu-HU-Neural2-A", pitch: 1.6)
        case "fi":
            return VoiceConfig(langTag: "fi-FI", voiceName: "fi-FI-Wavenet-A", pitch: 1.8)
        default:
            return animeFlag ? VoiceConfig(langTag: "en-US", voiceName: "en-US-Neural2-F", pitch: 2.0)
                             : VoiceConfig(langTag: "en-US", voiceName: "en-US-Journey-F", pitch: nil)
        }
    }
}

struct VoiceMapping {
    static func getConfig(for rawLanguage: String, isAnime: Bool = false) -> VoiceConfig {
        VoiceMappingProvider().resolve(for: rawLanguage, animeFlag: isAnime)
    }
}
