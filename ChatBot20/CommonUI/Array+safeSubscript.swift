import UIKit

extension Array {
    func safeSubscript(_ index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
