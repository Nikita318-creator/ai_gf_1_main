import UIKit
import SnapKit

final class SplashView: UIView {

    // MARK: - Subviews
    
    /// Наше основное изображение, содержащее весь текст и фон.
    /// Важно закинуть картинку с графическим планшетом и текстами в Assets как "openning".
    private let backgroundImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "openning"))
        imageView.contentMode = .scaleAspectFill
        // Clamping bounds to ignore safe area and fill screen completely
        imageView.clipsToBounds = true
        return imageView
    }()

    private let activitySpinnerView: UIActivityIndicatorView = {
        // Делаем его большим, чтобы хорошо читался поверх картинки
        let spinnerInstance = UIActivityIndicatorView(style: .large)
        spinnerInstance.color = BasePalitColors.primary
        spinnerInstance.startAnimating()
        return spinnerInstance
    }()

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviewsHierarchy()
        applyConstraintLayouts()
        // iPadCheck() убрали, так как теперь нет лейблов для масштабирования.
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    
    private func configureSubviewsHierarchy() {
        backgroundColor = BasePalitColors.background

        // Изображение идет самым первым слоем, чтобы заполнить весь фон
        addSubview(backgroundImage)
        
        // Спиннер идет вторым слоем, поверх изображения
        addSubview(activitySpinnerView)
    }
    
    private func applyConstraintLayouts() {
        
        // Картинка заполняет весь экран полностью, игнорируя safeArea
        backgroundImage.snp.makeConstraints { constraintMaker in
            constraintMaker.edges.equalToSuperview()
        }
        
        // Лоадинг индикатор размещаем строго по центру экрана
        activitySpinnerView.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.centerY.equalToSuperview()
        }
    }
}
