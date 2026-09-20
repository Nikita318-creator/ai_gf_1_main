import UIKit
import SnapKit

final class RandomAIGFTagCell: UICollectionViewCell {
    static let identifier = "SelectableTagCell"
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.layer.cornerRadius = 14
        contentView.layer.borderWidth = 1
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14))
        }
    }
    
    func configure(text: String, isSelected: Bool) {
        titleLabel.text = text
        if isSelected {
            contentView.backgroundColor = MyColors.selectedOption
            contentView.layer.borderColor = MyColors.primary.cgColor
            titleLabel.textColor = MyColors.textPrimary
        } else {
            contentView.backgroundColor = MyColors.cardBackground
            contentView.layer.borderColor = MyColors.separator.cgColor
            titleLabel.textColor = MyColors.textSecondary
        }
    }
}
