import UIKit
import SnapKit

final class RandomAIGFHeaderView: UICollectionReusableView {
    static let identifier = "RandomAIGFHeaderView"
    
    private let titleLabel = UILabel()
    private let stepBadgeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stepBadgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        stepBadgeLabel.textColor = MyColors.primary
        stepBadgeLabel.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        stepBadgeLabel.layer.cornerRadius = 6
        stepBadgeLabel.layer.masksToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        
        let stack = UIStackView(arrangedSubviews: [stepBadgeLabel, titleLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
    }
    
    func configure(title: String, step: Int) {
        stepBadgeLabel.text = " STEP \(step) "
        titleLabel.text = title
    }
}

extension RandomAIGFHeaderView {
    func updateForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        stepBadgeLabel.font = .systemFont(ofSize: 18, weight: .bold)
        stepBadgeLabel.layer.cornerRadius = 10
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
    }
}
