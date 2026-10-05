import UIKit
import SnapKit

final class SplashView: UIView {

    private let mainVisualContainer: UIView = {
        let baseElement = UIView()
        baseElement.backgroundColor = .clear
        baseElement.layer.shadowColor = BasePalitColors.primary.cgColor
        baseElement.layer.shadowOffset = CGSize(width: 0, height: 8)
        baseElement.layer.shadowRadius = 20
        baseElement.layer.shadowOpacity = 0.5
        return baseElement
    }()

    private let primaryAvatarImage: UIImageView = {
        let avatarWrapper = UIImageView(image: UIImage(named: "splashPhoto"))
        avatarWrapper.contentMode = .scaleAspectFill
        avatarWrapper.clipsToBounds = true
        avatarWrapper.layer.borderColor = BasePalitColors.primary.cgColor
        avatarWrapper.layer.borderWidth = 2
        avatarWrapper.layer.cornerRadius = 60
        return avatarWrapper
    }()

    private let mainHeaderTitle: UILabel = {
        let textContainer = UILabel()
        if let bundleAppTitle = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            textContainer.text = bundleAppTitle
        } else if let fallbackBundleTitle = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            textContainer.text = fallbackBundleTitle
        } else {
            textContainer.text = "Emma: AI GF"
        }
        
        textContainer.numberOfLines = 1
        textContainer.textColor = BasePalitColors.textPrimary
        textContainer.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        textContainer.textAlignment = .center

        textContainer.layer.shadowColor = BasePalitColors.primary.cgColor
        textContainer.layer.shadowRadius = 12.0
        textContainer.layer.shadowOpacity = 0.6
        textContainer.layer.shadowOffset = .zero
        textContainer.layer.masksToBounds = false
        
        return textContainer
    }()
    
    private let tagBadgePlate: UIView = {
        let plateView = UIView()
        plateView.backgroundColor = BasePalitColors.primary.withAlphaComponent(0.15)
        plateView.layer.cornerRadius = 10
        plateView.layer.borderWidth = 1
        plateView.layer.borderColor = BasePalitColors.primary.withAlphaComponent(0.3).cgColor
        return plateView
    }()
    
    private let tagBadgeCaption: UILabel = {
        let captionElement = UILabel()
        captionElement.text = "YOUR AI COMPANION"
        captionElement.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        captionElement.textColor = BasePalitColors.primary
        captionElement.textAlignment = .center
        return captionElement
    }()
    
    private let activitySpinnerView: UIActivityIndicatorView = {
        let spinnerInstance = UIActivityIndicatorView(style: .medium)
        spinnerInstance.color = BasePalitColors.primary
        spinnerInstance.startAnimating()
        return spinnerInstance
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviewsHierarchy()
        applyConstraintLayouts()
        iPadCheck()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviewsHierarchy() {
        backgroundColor = BasePalitColors.background

        addSubview(mainVisualContainer)
        mainVisualContainer.addSubview(primaryAvatarImage)
        addSubview(mainHeaderTitle)
        
        addSubview(tagBadgePlate)
        tagBadgePlate.addSubview(tagBadgeCaption)
        
        addSubview(activitySpinnerView)
    }
    
    private func applyConstraintLayouts() {
        mainVisualContainer.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.centerY.equalToSuperview().offset(-60)
            constraintMaker.size.equalTo(120)
        }

        primaryAvatarImage.snp.makeConstraints { constraintMaker in
            constraintMaker.edges.equalToSuperview()
        }
        
        mainHeaderTitle.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.top.equalTo(mainVisualContainer.snp.bottom).offset(24)
            constraintMaker.horizontalEdges.equalToSuperview().inset(20)
        }
        
        tagBadgePlate.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.top.equalTo(mainHeaderTitle.snp.bottom).offset(12)
        }
        
        tagBadgeCaption.snp.makeConstraints { constraintMaker in
            constraintMaker.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
        }
        
        activitySpinnerView.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-40)
        }
    }
}

extension SplashView {
    func iPadCheck() {
        guard isIPad() else { return }

        mainHeaderTitle.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        tagBadgeCaption.font = UIFont.systemFont(ofSize: 18, weight: .bold)

        primaryAvatarImage.layer.cornerRadius = 90
        tagBadgePlate.layer.cornerRadius = 16

        mainVisualContainer.snp.updateConstraints { constraintScope in
            constraintScope.size.equalTo(180)
        }

        tagBadgeCaption.snp.updateConstraints { constraintScope in
            constraintScope.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))
        }

        activitySpinnerView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }
}
