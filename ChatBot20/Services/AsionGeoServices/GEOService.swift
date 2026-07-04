//
//  GEOService.swift
//  ChatBot20
//
//  Created by Mikita on 17.09.25.
//


import UIKit

class GEOService {
    
    static let shared = GEOService()
    
    let eastAsiaAndSEA: [String] = [
        // Восточная Азия
        "CN", // Китай
        "JP", // Япония
        "KR", // Южная Корея
        "KP", // Северная Корея (если вдруг)
        "TW", // Тайвань
        "HK", // Гонконг
        "MO", // Макао
        
        // Юго-Восточная Азия
        "TH", // Таиланд
        "VN", // Вьетнам
        "PH", // Филиппины
        "ID", // Индонезия
        "MY", // Малайзия
        "SG", // Сингапур
        "KH", // Камбоджа
        "LA", // Лаос
        "MM", // Мьянма
        "BN"  // Бруней
    ]

    var isAsionGeo: Bool {
        guard !MainHelper.shared.isMode else { return false } // todo если мод включен то не нужно для азии ничего адаптировать оставляем как у всех
        let region = Locale.current.regionCode
        let localeID = Locale(identifier: Locale.preferredLanguages.first ?? "en-US").identifier

        return eastAsiaAndSEA.contains(region ?? "US") || localeID.range(of: "^(zh|ja|ko)", options: .regularExpression) != nil
    }
    
    private init() {}
    
    
}
