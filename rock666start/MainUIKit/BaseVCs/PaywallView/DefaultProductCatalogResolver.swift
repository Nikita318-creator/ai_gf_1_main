import ApphudSDK

final class DefaultProductCatalogResolver: ProductCatalogProviding {
    
    func resolveAvailableProducts() async -> [ApphudProduct] {
        let placements = await Apphud.placements(maxAttempts: 3)
        guard let primaryPlacement = placements.first,
              let targetPaywall = primaryPlacement.paywall,
              !targetPaywall.products.isEmpty else {
            return []
        }
        return targetPaywall.products
    }
}
