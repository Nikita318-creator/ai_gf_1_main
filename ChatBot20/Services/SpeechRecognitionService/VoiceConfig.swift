//
//  VoiceConfig.swift
//  ChatBot20
//
//  Created by Mikita on 05/06/2026.
//


import Foundation

struct VoiceConfig {
    let langTag: String
    let voiceName: String
    let pitch: Double? // Делаем опциональным!
}

struct VoiceMapping {
    static func getConfig(for rawLanguage: String) -> VoiceConfig {
        let normalized = rawLanguage.lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = normalized.components(separatedBy: "-")
        let baseCode = components.first ?? ""
        
        // --- 1. ПРОВЕРКА СПЕЦИФИЧЕСКИХ ЛОКАЛЕЙ ---
        if components.contains("tw") || components.contains("hk") || components.contains("hant") {
            return VoiceConfig(langTag: "zh-TW", voiceName: "zh-TW-Neural2-A", pitch: 1.6)
        }
        if components.contains("mx") || components.contains("419") || (baseCode == "es" && components.contains("us")) {
            return VoiceConfig(langTag: "es-MX", voiceName: "es-MX-Neural2-A", pitch: 1.8)
        }
        if components.contains("br") || (baseCode == "pt" && !components.contains("pt")) {
            return VoiceConfig(langTag: "pt-BR", voiceName: "pt-BR-Neural2-A", pitch: 1.8)
        }
        if baseCode == "fil" {
            return VoiceConfig(langTag: "fil-PH", voiceName: "fil-PH-Neural2-A", pitch: 1.8)
        }
        
        // --- 2. СЕГМЕНТАЦИЯ ПО БАЗОВОМУ ЯЗЫКУ ---
        switch baseCode {
        case "en": // Journey НЕ поддерживает pitch -> ставим nil
            return VoiceConfig(langTag: "en-US", voiceName: "en-US-Journey-F", pitch: nil)
        case "ja":
            return VoiceConfig(langTag: "ja-JP", voiceName: "ja-JP-Neural2-B", pitch: 1.8)
        case "zh":
            return VoiceConfig(langTag: "cmn-CN", voiceName: "cmn-CN-Neural2-F", pitch: 1.8)
        case "de":
            return VoiceConfig(langTag: "de-DE", voiceName: "de-DE-Neural2-C", pitch: 1.5)
        case "fr": // Journey НЕ поддерживает pitch -> ставим nil
            return VoiceConfig(langTag: "fr-FR", voiceName: "fr-FR-Journey-F", pitch: nil)
        case "es":
            return VoiceConfig(langTag: "es-ES", voiceName: "es-ES-Neural2-C", pitch: 1.8)
        case "ko":
            return VoiceConfig(langTag: "ko-KR", voiceName: "ko-KR-Neural2-A", pitch: 1.6)
        case "it": // Если решишь оставить / добавить Италию
            return VoiceConfig(langTag: "it-IT", voiceName: "it-IT-Journey-F", pitch: nil)
            
        // --- TIER 2 ---
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
            return VoiceConfig(langTag: "en-US", voiceName: "en-US-Journey-F", pitch: nil)
        }
    }
}
