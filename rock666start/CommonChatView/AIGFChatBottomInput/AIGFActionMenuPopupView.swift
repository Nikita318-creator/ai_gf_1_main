import UIKit
import SnapKit

// MARK: - 2. Action Menu Popup (Всплывашка)
class AIGFActionMenuPopupView: UIView {
    let stackView = UIStackView()
    
    let giftButton = UIButton(type: .system)
    let photoPromptButton = UIButton(type: .system)
    let videoPromptButton = UIButton(type: .system)
    
    let audioContainer = UIView()
    let audioLabel = UILabel()
    let audioToggleSwitch = UISwitch()
    
    var onGiftTapped: (() -> Void)?
    var onPromptTapped: ((String) -> Void)?
    var onAudioToggled: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = MyColors.cardBackground
        layer.cornerRadius = 20
        layer.shadowColor = MyColors.background.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8
        layer.borderWidth = 1
        layer.borderColor = MyColors.primary.withAlphaComponent(0.3).cgColor
        
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        setupButton(giftButton, title: "SendGift".localize(), icon: "gift.fill", tag: 19)
        setupButton(photoPromptButton, title: "suggestedPrompt1".localize(), icon: "camera.fill", tag: 20)
        setupButton(videoPromptButton, title: "suggestedPromptVideo".localize(), icon: "video.fill", tag: 21)
        
        setupAudioRow()
        
        giftButton.addTarget(self, action: #selector(giftAction), for: .touchUpInside)
        photoPromptButton.addTarget(self, action: #selector(promptAction(_:)), for: .touchUpInside)
        videoPromptButton.addTarget(self, action: #selector(promptAction(_:)), for: .touchUpInside)
    }
    
    private func setupButton(_ button: UIButton, title: String, icon: String, tag: Int) {
        let fontSize: CGFloat = isNeedBigTextForIPad() ? 20 : 15
        button.setTitle(" " + title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        button.contentHorizontalAlignment = .left
        button.tag = tag
        
        if let img = UIImage(systemName: icon)?.withTintColor(MyColors.primary, renderingMode: .alwaysOriginal) {
            button.setImage(img, for: .normal)
        }
        
        stackView.addArrangedSubview(button)
    }
    
    private func setupAudioRow() {
        audioContainer.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        
        let fontSize: CGFloat = isNeedBigTextForIPad() ? 20 : 15
        audioLabel.text = "suggestedPromptAudio1".localize()
        audioLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        audioLabel.textColor = MyColors.textPrimary
        
        audioToggleSwitch.isOn = BaseManager.shared.isAudioMessagesMode
        audioToggleSwitch.onTintColor = MyColors.primary
        audioToggleSwitch.addTarget(self, action: #selector(audioSwitchChanged(_:)), for: .valueChanged)
        
        audioContainer.addSubview(audioLabel)
        audioContainer.addSubview(audioToggleSwitch)
        
        audioLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        audioToggleSwitch.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(audioLabel.snp.trailing).offset(8)
        }
        
        stackView.addArrangedSubview(audioContainer)
    }
    
    @objc private func giftAction() { onGiftTapped?() }
    
    @objc private func promptAction(_ sender: UIButton) {
        guard let text = sender.title(for: .normal)?.trimmingCharacters(in: .whitespaces) else { return }
        onPromptTapped?(text)
    }
    
    @objc private func audioSwitchChanged(_ sender: UISwitch) {
        onAudioToggled?(sender.isOn)
    }
    
    // Поддержка старых методов скрытия (А/Б тесты)
    func hideAllPromptsExceptGift() {
        photoPromptButton.isHidden = true
        videoPromptButton.isHidden = true
        audioContainer.isHidden = true
    }
    
    func hideVideoPrompt() { videoPromptButton.isHidden = true }
    func hidePhotoPrompt() { photoPromptButton.isHidden = true }
}
