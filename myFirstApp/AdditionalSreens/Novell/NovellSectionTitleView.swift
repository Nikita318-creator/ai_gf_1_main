import UIKit
import SnapKit

class NovellSectionTitleView: UICollectionReusableView {
    static let identifier = "NovellSectionTitleView"
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        label.font = .systemFont(ofSize: 24, weight: .black)
        label.textColor = MyColors.textPrimary
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
}

extension NovellSectionTitleView {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }
        
        label.font = .systemFont(ofSize: 34, weight: .black)
        
        label.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
        }
    }
}
