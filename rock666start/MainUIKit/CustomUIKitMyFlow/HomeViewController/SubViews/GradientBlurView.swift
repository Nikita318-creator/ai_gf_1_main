import UIKit

public final class GradientBlurView: UIView {
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    private let maskLayer = CAGradientLayer()
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Маска плавно растворяет верхний край блюра (от 0% до 25% высоты)
        maskLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        maskLayer.locations = [0.0, 0.3]
        layer.mask = maskLayer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
    }
}
