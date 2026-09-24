import UIKit

extension UIView {
    func isCurrentDeviceiPad() -> Bool {
        let isRegularHorizontal = traitCollection.horizontalSizeClass == .regular
        return UIDevice.current.userInterfaceIdiom == .pad && isRegularHorizontal
    }
}
