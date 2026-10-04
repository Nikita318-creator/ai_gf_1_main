

import ApphudSDK
import UIKit

enum StoreIDs {    
    static let weekly = "com.ostap.aigirlfriend.app.Week"
    static let yearly = "com.ostap.aigirlfriend.app.year"
}

enum StoreCoinsIDs {
    static let coins10   = "com.ostap.aigirlfriend.app.coins_20"
    static let coins50   = "com.ostap.aigirlfriend.app.coins_100"
    static let coins100  = "com.ostap.aigirlfriend.app.coins1000"
}

enum IAPResult {
    case purchased
    case failed
    case restored
}

class SubscriptionManager: NSObject {
    
    var hasActiveSubscription: Bool {
#if DEBUG
        return true
#endif
        (Apphud.hasActiveSubscription() || (UserDefaults.standard.bool(forKey: "is_free_premium_active")))
    }
    
    var hasRealPurchasedSubscription : Bool {
//                return false
        Apphud.hasActiveSubscription()
    }
    
    static let shared = SubscriptionManager()
    
    var closure: ((IAPResult) -> Void)?
    var products: [ApphudProduct] = []
    
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

            } else {
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
    func purchase(productId: String, closure: @escaping (IAPResult) -> Void) {
        self.closure = closure
        
        guard let product = products.first(where: { $0.productId == productId }) else {
            print("Продукт \(productId) не найден")
           
            closure(.failed)
            return
        }
        
        Task { @MainActor in
            Apphud.purchase(product, callback: { result in
                if let error = result.error {
                    print("Ошибка покупки: \(error.localizedDescription)")
                    closure(.failed)
                    return
                }
                
                if result.transaction != nil {
                    var price: Double = 8.0
                    var currencyCode: String = "USD"
                    
                    if let skProduct = product.skProduct {
                        price = skProduct.price.doubleValue
                        if let currency = skProduct.priceLocale.currencyCode {
                            currencyCode = currency
                        }
                    }
                    
                    AppsFlyerService.shared.trackSubscriptionPurchase(
                        price: price,
                        currency: currencyCode,
                        productId: product.productId
                    )
                    
                    closure(.purchased)
                } else {
                    closure(.failed)
                }
            })
        }
    }
    
    func restorePurchases(closure: @escaping (IAPResult) -> Void) {
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
