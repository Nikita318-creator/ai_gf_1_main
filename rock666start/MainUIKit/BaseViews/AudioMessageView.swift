import UIKit
import SnapKit

class AudioMessageView: UIView {
    
    var onProgressChanged: ((Float, _ isDragging: Bool) -> Void)?
    
    private let trackContainer = UIStackView()
    private var levelIndicators: [UIView] = []
    
    var progress: Float = 0 {
        didSet {
            renderActiveState()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViewHierarchy()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initViewHierarchy()
    }
    
    private func initViewHierarchy() {
        trackContainer.axis = .horizontal
        trackContainer.alignment = .center
        trackContainer.distribution = .equalSpacing
        trackContainer.spacing = 3
        
        addSubview(trackContainer)
        trackContainer.snp.makeConstraints { makeConstraint in
            makeConstraint.edges.equalToSuperview()
        }
        
        for _ in 0..<30 {
            let indicator = UIView()
            indicator.backgroundColor = .white.withAlphaComponent(0.3)
            indicator.layer.cornerRadius = 1.5
            trackContainer.addArrangedSubview(indicator)
            
            indicator.snp.makeConstraints { makeConstraint in
                makeConstraint.height.equalTo(CGFloat.random(in: 8...28))
                makeConstraint.width.equalTo(3)
            }
            levelIndicators.append(indicator)
        }
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanAction(_:)))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
        
        addGestureRecognizer(panRecognizer)
        addGestureRecognizer(tapRecognizer)
    }
    
    private func renderActiveState() {
        let highlightedAmount = Int(Float(levelIndicators.count) * progress)
        for (itemIndex, indicator) in levelIndicators.enumerated() {
            if itemIndex < highlightedAmount {
                indicator.backgroundColor = .white
            } else {
                indicator.backgroundColor = .white.withAlphaComponent(0.3)
            }
        }
    }
    
    @objc private func onTapAction(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self)
        let calculatedProgress = max(0, min(1, Float(touchPoint.x / bounds.width)))
        progress = calculatedProgress
        onProgressChanged?(calculatedProgress, false)
    }
    
    @objc private func onPanAction(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self)
        let calculatedProgress = max(0, min(1, Float(touchPoint.x / bounds.width)))
        progress = calculatedProgress
        
        switch sender.state {
        case .began, .changed:
            onProgressChanged?(calculatedProgress, true)
        case .ended, .cancelled:
            onProgressChanged?(calculatedProgress, false)
        default:
            break
        }
    }
}
