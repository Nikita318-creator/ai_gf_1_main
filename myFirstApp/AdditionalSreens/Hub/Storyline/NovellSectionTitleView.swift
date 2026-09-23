import UIKit
import SnapKit

class NovellSectionTitleView: UICollectionReusableView {
    static let identifier = "SectionTitleView"
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 24, weight: .black)
        label.textColor = MyColors.textPrimary
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}
