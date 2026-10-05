import UIKit

extension UIView {
    func isIPad() -> Bool {
        let isRegularHorizontal = traitCollection.horizontalSizeClass == .regular
        return UIDevice.current.userInterfaceIdiom == .pad && isRegularHorizontal
    }
}
