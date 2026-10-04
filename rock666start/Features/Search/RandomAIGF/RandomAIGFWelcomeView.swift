import UIKit
import SnapKit

final class RandomAIGFWelcomeView: UIView {
    
    var onStartTapped: (() -> Void)?
    var onBackTapped: (() -> Void)?

    private let backButton       = UIButton(type: .system)
    private let heroContainer    = UIView()
    private let heroIcon         = UILabel()
    private let badgePill        = UIView()
    private let badgeLabel       = UILabel()
    private let titleLabel      = UILabel()
    private let descriptionLabel = UILabel()
    private var statsRow         = UIView()
    private let startButton     = AnimatedButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupBackButton()

        heroContainer.backgroundColor = MyColors.cardBackground
        heroContainer.layer.cornerRadius = 36
        heroContainer.layer.borderWidth = 1
        heroContainer.layer.borderColor = MyColors.separator.cgColor

        heroIcon.text = "💖"
        heroIcon.font = .systemFont(ofSize: 48)
        heroIcon.textAlignment = .center

        heroContainer.addSubview(heroIcon)
        heroIcon.snp.makeConstraints { make in make.center.equalToSuperview() }

        badgePill.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        badgePill.layer.cornerRadius = 12

        badgeLabel.text = "Roulette_Step1_Badge".localize()
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = MyColors.primary

        badgePill.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
        }

        titleLabel.text = "Roulette_Step1_Title".localize()
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center

        descriptionLabel.text = "Roulette_Step1_Description".localize()
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = MyColors.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        statsRow = makeStatsRow()

        let divider = UIView()
        divider.backgroundColor = MyColors.separator

        startButton.setTitle("Roulette_Step1_StartButton".localize(), for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startButton.setTitleColor(MyColors.textPrimary, for: .normal)
        startButton.backgroundColor = MyColors.primary
        startButton.layer.cornerRadius = 16
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)

        [backButton, heroContainer, badgePill, titleLabel, descriptionLabel, statsRow, divider, startButton].forEach {
            addSubview($0)
        }

        backButton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(40)
        }

        heroContainer.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }

        badgePill.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgePill.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        statsRow.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(statsRow.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        startButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    private func setupBackButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.cardBackground
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = MyColors.separator.cgColor
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
    }

    private func makeStatsRow() -> UIView {
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground
        container.layer.cornerRadius = isNeedBigTextForIPad() ? 28 : 18
        container.layer.borderWidth = 1
        container.layer.borderColor = MyColors.separator.cgColor

        let items = [
            ("Roulette_Stat1_Value".localize(), "Roulette_Stat1_Label".localize()),
            ("Roulette_Stat2_Value".localize(), "Roulette_Stat2_Label".localize()),
            ("Roulette_Stat3_Value".localize(), "Roulette_Stat3_Label".localize())
        ]
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually

        for (idx, item) in items.enumerated() {
            let col = makeStatColumn(value: item.0, label: item.1)
            stack.addArrangedSubview(col)

            if idx < items.count - 1 {
                let sepLine = UIView()
                sepLine.backgroundColor = MyColors.separator
                let sepContainer = UIView()
                sepContainer.addSubview(sepLine)
                sepLine.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(8)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(1)
                }
                stack.addArrangedSubview(sepContainer)
            }
        }

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return container
    }

    private func makeStatColumn(value: String, label: String) -> UIView {
        let col = UIView()
        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = isNeedBigTextForIPad() ? .systemFont(ofSize: 26, weight: .bold) : .systemFont(ofSize: 17, weight: .bold)
        valLabel.textColor = MyColors.primary
        valLabel.textAlignment = .center

        let lblLabel = UILabel()
        lblLabel.text = label
        lblLabel.font = isNeedBigTextForIPad() ? .systemFont(ofSize: 18, weight: .regular) : .systemFont(ofSize: 12, weight: .regular)
        lblLabel.textColor = MyColors.textSecondary
        lblLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valLabel, lblLabel])
        stack.axis = .vertical
        stack.spacing = isNeedBigTextForIPad() ? 6 : 2
        col.addSubview(stack)
        stack.snp.makeConstraints { make in make.center.equalToSuperview() }
        return col
    }

    @objc private func didTapStart() { onStartTapped?() }
    @objc private func didTapBack() { onBackTapped?() }
}

extension RandomAIGFWelcomeView {
    private func updateForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }

        let backConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: backConfig), for: .normal)
        backButton.layer.cornerRadius = 30
        backButton.snp.updateConstraints { make in make.size.equalTo(60) }

        heroContainer.layer.cornerRadius = 50
        heroIcon.font = .systemFont(ofSize: 72)
        heroContainer.snp.updateConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(24)
            make.width.height.equalTo(150)
        }

        badgePill.layer.cornerRadius = 18
        badgeLabel.font = .systemFont(ofSize: 18, weight: .bold)
        badgePill.snp.updateConstraints { make in make.top.equalTo(heroContainer.snp.bottom).offset(28) }
        badgeLabel.snp.updateConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 22, bottom: 10, right: 22))
        }

        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.snp.updateConstraints { make in make.top.equalTo(badgePill.snp.bottom).offset(20) }

        descriptionLabel.font = .systemFont(ofSize: 22, weight: .regular)
        descriptionLabel.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        statsRow.snp.updateConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.height.equalTo(96)
        }

        startButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        startButton.layer.cornerRadius = 24
        startButton.snp.updateConstraints { make in make.height.equalTo(72) }
    }
}
