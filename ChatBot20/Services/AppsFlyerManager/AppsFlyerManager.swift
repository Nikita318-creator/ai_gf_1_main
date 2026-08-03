//
//  AppsFlyerManager.swift
//  ChatBot20
//
//  Created by Mikita on 03/08/2026.
//

import Foundation
import AppsFlyerLib

final class AppsFlyerManager: NSObject {
    
    static let shared = AppsFlyerManager()
    
    private override init() {
        super.init()
    }
    
    /// Конфигурация SDK (вызывается в didFinishLaunchingWithOptions)
    func configure() {
        // ПЕРЕДАЕМ APP ID СТРОГО БЕЗ "id" (чистые цифры) — это фиксит ошибку "App ID is incorrect"
        AppsFlyerLib.shared().initialize(devKey: "tQLziFNpZCcfBArtWrKNzM", appId: "6748720543")
        AppsFlyerLib.shared().delegate = self
        
        // Ожидание ответа пользователя в окне ATT перед отправкой первого ивента (до 60 сек)
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif

        print("[AppsFlyer] Configured successfully")
    }
    
    /// Запуск отправки сессии (вызывается в applicationDidBecomeActive)
    func start() {
        AppsFlyerLib.shared().start()
        print("[AppsFlyer] Started")
    }
    
    // MARK: - Tracking Events
    
    func trackEvent(name: String, values: [String: Any]? = nil) {
        AppsFlyerLib.shared().logEvent(name, withValues: values)
    }
    
    func trackSubscriptionPurchase(price: Double, currency: String, productId: String) {
        let values: [String: Any] = [
            AFEventParamRevenue: price,
            AFEventParamCurrency: currency,
            AFEventParamContentId: productId,
            AFEventParamContentType: "subscription"
        ]
        trackEvent(name: AFEventPurchase, values: values)
        print("[AppsFlyer] trackSubscriptionPurchase: price = \(price), currency = \(currency), productId = \(productId)")
    }
}

// MARK: - AppsFlyerLibDelegate
extension AppsFlyerManager: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("[AppsFlyer] Conversion Data: \(conversionInfo)")
        
        let status = conversionInfo["af_status"] as? String ?? "unknown"
        let afMessage = conversionInfo["af_message"] as? String ?? "unknown"
        let mediaSource = conversionInfo["media_source"] as? String ?? "unknown"
        let campaign = conversionInfo["campaign"] as? String ?? "unknown"
        
        let isFirstLaunch = conversionInfo["is_first_launch"] != nil ? "\(conversionInfo["is_first_launch"]!)" : "unknown"
        let isCache = conversionInfo["iscache"] != nil ? "\(conversionInfo["iscache"]!)" : "unknown"
        
        let adset = conversionInfo["adset"] as? String ?? "unknown"
        let adsetId = conversionInfo["adset_id"] as? String ?? "unknown"
        let adgroup = conversionInfo["adgroup"] as? String ?? "unknown"
        let adgroupId = conversionInfo["adgroup_id"] as? String ?? "unknown"
        let ad = conversionInfo["ad"] as? String ?? "unknown"
        let adId = conversionInfo["ad_id"] as? String ?? "unknown"
                
        AnalyticService.shared.logEvent(
            name: "appsflyer_conversion_success",
            properties: [
                "af_status": status,
                "af_message": afMessage,
                "media_source": mediaSource,
                "campaign": campaign,
                "is_first_launch": isFirstLaunch,
                "iscache": isCache,
                "adset": adset,
                "adset_id": adsetId,
                "adgroup": adgroup,
                "adgroup_id": adgroupId,
                "ad": ad,
                "ad_id": adId
            ]
        )
    }
    
    func onConversionDataFail(_ error: Error) {
        print("[AppsFlyer] Conversion Error: \(error.localizedDescription)")
        
        AnalyticService.shared.logEvent(
            name: "appsflyer_conversion_fail",
            properties: [
                "error_description": error.localizedDescription
            ]
        )
    }
}
