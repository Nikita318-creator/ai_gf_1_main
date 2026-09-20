import UIKit

final class BubbleView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bubbleColor = MyColors.cardBackground
        let strokeColor = MyColors.separator
        let cornerRadius: CGFloat = 20
        let tailWidth: CGFloat = 20
        let tailHeight: CGFloat = 12
        
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: cornerRadius),
                         controlPoint: CGPoint(x: rect.width, y: 0))
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - tailHeight - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.width - cornerRadius, y: rect.height - tailHeight),
                         controlPoint: CGPoint(x: rect.width, y: rect.height - tailHeight))
        
        let tailStartX = rect.width / 2 - tailWidth / 2
        path.addLine(to: CGPoint(x: tailStartX + tailWidth, y: rect.height - tailHeight))
        
        path.addCurve(to: CGPoint(x: tailStartX, y: rect.height - tailHeight),
                      controlPoint1: CGPoint(x: tailStartX + tailWidth * 0.8, y: rect.height - tailHeight * 0.3),
                      controlPoint2: CGPoint(x: tailStartX + tailWidth * 0.2, y: rect.height))
        
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - tailHeight))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - tailHeight - cornerRadius),
                         controlPoint: CGPoint(x: 0, y: rect.height - tailHeight))
        
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                         controlPoint: CGPoint(x: 0, y: 0))
        
        path.close()
        
        bubbleColor.setFill()
        path.fill()
        
        strokeColor.setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}
