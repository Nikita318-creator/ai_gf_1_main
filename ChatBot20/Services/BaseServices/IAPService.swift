

import ApphudSDK
import UIKit

enum SubsIDs {    
    static let weekly = "com.ostap.aigirlfriend.app.Week"
    static let monthly = "com.ostap.aigirlfriend.app.month"
    static let yearly = "com.ostap.aigirlfriend.app.year"
}

enum CoinsIDs {
    static let coins10   = "com.ostap.aigirlfriend.app.coins_20"
    static let coins50   = "com.ostap.aigirlfriend.app.coins_100"
    static let coins100  = "com.ostap.aigirlfriend.app.coins_1000"
}

enum InAppPurchaseResult {
    case purchased
    case failed
    case restored
}

struct SubscriptionStatus {
    let isActive: Bool
    let isTrialPeriod: Bool
    let remainingTrialDays: Int?
}

class IAPService: NSObject {
    static let shared = IAPService()
    
    var closure: ((InAppPurchaseResult) -> Void)?
    var products: [ApphudProduct] = []
//    var isActiveMOC = false
    
    var hasActiveSubscription: Bool {
        return false
//        return isActiveMOC
//        Apphud.hasActiveSubscription()
        AnalyticService.shared.environment == .prod
            ? (Apphud.hasActiveSubscription() || (ConfigService.shared.isFreeMode && UserDefaults.standard.bool(forKey: "is_free_premium_active")))
            : true
    }
    
    var hasRealPurchasedSubscription : Bool {
//                return false
        //        Apphud.hasActiveSubscription()
        AnalyticService.shared.environment == .prod ? Apphud.hasActiveSubscription() : true
    }
    
    private override init() {
        super.init()
        fetchProducts()
    }
    
    // Предварительная загрузка продуктов при инициализации
    private func fetchProducts() {
        Task {
            // Получаем placements с ожиданием загрузки SKProducts
            let placements = await Apphud.placements(maxAttempts: 3)
            if let placement = placements.first, let paywall = placement.paywall, !paywall.products.isEmpty {
                self.products = paywall.products
                print("Продукты загружены: \(self.products.map { $0.productId })")
                AnalyticService.shared.logEvent(name: "products fetched: \(self.products.map { $0.productId })", properties: ["":""])

            } else {
                AnalyticService.shared.logEvent(name: "ERROR fetch products", properties: ["":""])
                print("Нет доступных продуктов или paywall")
                self.products = []
            }
        }
    }
    
    // MARK: - Product Request
    func getProducts() -> [ApphudProduct] {
        return products
    }
    
    // MARK: - Purchases
    func purchase(productId: String, closure: @escaping (InAppPurchaseResult) -> Void) {
        self.closure = closure
        
        guard let product = products.first(where: { $0.productId == productId }) else {
            print("Продукт \(productId) не найден")
           
            AnalyticService.shared.logEvent(name: "ERROR product not found: \(productId)", properties: ["":""])

            closure(.failed)
            return
        }
        
        Task { @MainActor in
            Apphud.purchase(product, callback: { result in
                if let error = result.error {
                    print("Ошибка покупки: \(error.localizedDescription)")
                  
                    if error.localizedDescription.contains("The operation couldn’t be completed. (SKErrorDomain error 2.)") {
                        AnalyticService.shared.logEvent(name: "canceled purchase", properties: ["":""])
                    } else {
                        AnalyticService.shared.logEvent(name: "ERROR purchase: \(error.localizedDescription)", properties: ["":""])
                    }

                    closure(.failed)
                    return
                }
                
                if result.transaction != nil {
                    AnalyticService.shared.logEvent(name: "!!! Purchased: \(product.productId)", properties: ["":""])

                    var price: Double = 8.0
                    var currencyCode: String = "USD"
                    
                    if let skProduct = product.skProduct {
                        price = skProduct.price.doubleValue
                        if let currency = skProduct.priceLocale.currencyCode {
                            currencyCode = currency
                        }
                    }
                    
                    AppsFlyerManager.shared.trackSubscriptionPurchase(
                        price: price,
                        currency: currencyCode,
                        productId: product.productId
                    )
                    
                    closure(.purchased)
                } else {
                    
                    AnalyticService.shared.logEvent(name: "ERROR purchase - unknown?", properties: ["":""])

                    print("Покупка отменена или не завершена")
                    closure(.failed)
                }
            })
        }
    }
    
    func restorePurchases(closure: @escaping (InAppPurchaseResult) -> Void) {
        Task { @MainActor in
            let error = await Apphud.restorePurchases()
            if let error = error {
                print("Ошибка восстановления: \(error.localizedDescription)")
               
                closure(.failed)
                return
            }
            
            if hasActiveSubscription || (Apphud.subscriptions()?.isEmpty == false) {
               
                closure(.restored)
            } else {
                
                closure(.failed)
            }
        }
    }
}

// Обновление статуса подписки
extension IAPService {
    func apphudDidUpdateUserInfo(_ userInfo: ApphudUser) { }
}
