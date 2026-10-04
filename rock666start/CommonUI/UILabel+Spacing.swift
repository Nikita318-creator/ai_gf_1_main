import UIKit

extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = self.text else { return }
        let attr = NSMutableAttributedString(string: text)
        attr.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: text.count))
        attributedText = attr
    }

    func lineSpacing(_ spacing: CGFloat) {
        guard let text = self.text else { return }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = spacing
        style.alignment = textAlignment
        let attr = NSMutableAttributedString(string: text, attributes: [
            .paragraphStyle: style,
            .font: font as Any,
            .foregroundColor: textColor as Any
        ])
        attributedText = attr
    }
}

extension UILabel {
    func setLineSpacing(lineSpacing: CGFloat) {
        guard let text = self.text else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        self.attributedText = attributedString
    }
}
