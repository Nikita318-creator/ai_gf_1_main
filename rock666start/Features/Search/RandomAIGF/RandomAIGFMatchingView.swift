import UIKit
import SnapKit

final class RandomAIGFMatchingView: UIView {
    
    private let topLabel = UILabel()
    private let cardView = UIView()
    private let avatarImageView = UIImageView()
    private let statusPill = UIView()
    private let statusLabel = UILabel()
    private let hintsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAvatar(named name: String) {
        avatarImageView.image = UIImage(named: name)
    }

    func startStatusAnimation() {
        statusLabel.alpha = 1.0
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse]) {
            self.statusLabel.alpha = 0.4
        }
    }

    func stopStatusAnimation() {
        statusLabel.layer.removeAllAnimations()
        statusLabel.alpha = 1.0
    }

    private func setupViews() {
        topLabel.text = "Roulette_Step3_SearchingTitle".localize()
        topLabel.font = .systemFont(ofSize: 18, weight: .bold)
        topLabel.textColor = MyColors.textPrimary
        topLabel.textAlignment = .center

        cardView.backgroundColor = MyColors.cardBackground
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = MyColors.separator.cgColor

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = MyColors.messageBackground

        cardView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in make.edges.equalToSuperview().inset(12) }

        statusPill.backgroundColor = MyColors.cardBackground
        statusPill.layer.cornerRadius = 14
        statusPill.layer.borderWidth = 1
        statusPill.layer.borderColor = MyColors.separator.cgColor

        statusLabel.text = "Roulette_Step3_StatusText".localize()
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = MyColors.textSecondary
        statusLabel.textAlignment = .center

        let dotIndicator = UIActivityIndicatorView(style: .medium)
        dotIndicator.color = MyColors.primary
        dotIndicator.startAnimating()

        let pillStack = UIStackView(arrangedSubviews: [dotIndicator, statusLabel])
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.alignment = .center

        statusPill.addSubview(pillStack)
        pillStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        hintsStack.axis = .horizontal
        hintsStack.spacing = 8
        hintsStack.distribution = .fillProportionally

        let hints = [
            "Roulette_Chip_Style".localize(),
            "Roulette_Chip_Interest".localize(),
            "Roulette_Chip_Vibe".localize()
        ]
        
        for hint in hints {
            let chip = UIView()
            chip.backgroundColor = MyColors.cardBackground
            chip.layer.cornerRadius = isNeedBigTextForIPad() ? 16 : 10
            chip.layer.borderWidth = 1
            chip.layer.borderColor = MyColors.separator.cgColor

            let chipLabel = UILabel()
            chipLabel.text = hint
            chipLabel.font = isNeedBigTextForIPad() ? .systemFont(ofSize: 20, weight: .medium) : .systemFont(ofSize: 12, weight: .medium)
            chipLabel.textColor = MyColors.textSecondary
            chip.addSubview(chipLabel)
            chipLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: isNeedBigTextForIPad() ? 10 : 6,
                                                                 left: isNeedBigTextForIPad() ? 18 : 12,
                                                                 bottom: isNeedBigTextForIPad() ? 10 : 6,
                                                                 right: isNeedBigTextForIPad() ? 18 : 12))
            }
            hintsStack.addArrangedSubview(chip)
        }

        [topLabel, cardView, statusPill, hintsStack].forEach { addSubview($0) }

        topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(260)
            make.height.equalTo(320)
        }

        statusPill.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        hintsStack.snp.makeConstraints { make in
            make.top.equalTo(statusPill.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }
}

extension RandomAIGFMatchingView {
    private func updateForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }

        topLabel.font = .systemFont(ofSize: 28, weight: .bold)
        
        cardView.layer.cornerRadius = 36
        avatarImageView.layer.cornerRadius = 28
        cardView.snp.updateConstraints { make in
            make.width.equalTo(380)
            make.height.equalTo(460)
        }

        statusPill.layer.cornerRadius = 22
        statusLabel.font = .systemFont(ofSize: 20, weight: .medium)
        statusPill.snp.updateConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(32)
        }
    }
}
