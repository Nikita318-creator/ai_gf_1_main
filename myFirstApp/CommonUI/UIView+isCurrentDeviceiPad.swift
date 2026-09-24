import UIKit

extension UIView {
    func isNeedBigTextForIPad() -> Bool {
        let isRegularHorizontal = traitCollection.horizontalSizeClass == .regular
        return UIDevice.current.userInterfaceIdiom == .pad && isRegularHorizontal
    }
}
