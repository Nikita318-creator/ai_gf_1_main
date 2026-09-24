import UIKit
import SnapKit

protocol MyGFOneScreenViewDelegate: AnyObject {
    func didSelectOption(questionId: String)
}

class MyGFOneScreenView: UIView {
    
    private static let checkTag = 9101
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = MyColors.textPrimary
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let optionsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    private var question: MyGFQuestionModel?
    private weak var delegate: MyGFOneScreenViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = MyColors.cardBackground
        layer.cornerRadius = 16
        
        addSubview(titleLabel)
        addSubview(optionsStack)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        optionsStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with question: MyGFQuestionModel, delegate: MyGFOneScreenViewDelegate) {
        self.question = question
        self.delegate = delegate
        titleLabel.text = question.title
        
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let savedSelections = CreateMyGFUseCase.shared.getSelection(questionId: question.id)
        
        question.options.forEach { option in
            let button = createOptionButton(
                text: option,
                isSelected: savedSelections.contains(option)
            )
            optionsStack.addArrangedSubview(button)
        }
    }
    
    private func createOptionButton(text: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        
        let isIPad = isCurrentDeviceiPad()
        
        button.titleLabel?.font = .systemFont(ofSize: isIPad ? 24 : 15, weight: .medium)
        
        button.contentHorizontalAlignment = .leading
        
        let isRTL = UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute) == .rightToLeft
        let baseLeftPadding: CGFloat = isIPad ? 22 : 14
        let baseRightPadding: CGFloat = isIPad ? 60 : 44
        let verticalPadding: CGFloat = isIPad ? 18 : 13
        
        let leftInset: CGFloat = isRTL ? baseRightPadding : baseLeftPadding
        let rightInset: CGFloat = isRTL ? baseLeftPadding : baseRightPadding
        button.contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: leftInset, bottom: verticalPadding, right: rightInset)
        
        button.layer.cornerRadius = isIPad ? 18 : 12
        button.layer.borderWidth = isIPad ? 2.0 : 1.5
        
        let checkView = UIImageView()
        checkView.tag = MyGFOneScreenView.checkTag
        checkView.contentMode = .scaleAspectFit
        checkView.isUserInteractionEnabled = false
        button.addSubview(checkView)
        
        let checkSize: CGFloat = isIPad ? 32 : 22
        let checkInset: CGFloat = isIPad ? 20 : 14
        
        checkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(checkInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(checkSize)
        }
        
        updateButtonAppearance(button, isSelected: isSelected)
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func updateButtonAppearance(_ button: UIButton, isSelected: Bool) {
        let checkView = button.viewWithTag(MyGFOneScreenView.checkTag) as? UIImageView
        
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        
        if isSelected {
            button.backgroundColor = MyColors.selectedOption
            button.layer.borderColor = MyColors.primary.cgColor
            checkView?.image = UIImage(systemName: "checkmark.circle.fill")
            checkView?.tintColor = MyColors.primary
        } else {
            button.backgroundColor = MyColors.inputBackground
            button.layer.borderColor = UIColor.clear.cgColor
            checkView?.image = UIImage(systemName: "circle")
            checkView?.tintColor = MyColors.textSecondary.withAlphaComponent(0.6)
        }
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        guard let question = question,
              let optionText = sender.title(for: .normal) else { return }
        
        var currentSelections = CreateMyGFUseCase.shared.getSelection(questionId: question.id)
        
        if question.allowMultipleSelection {
            if let index = currentSelections.firstIndex(of: optionText) {
                currentSelections.remove(at: index)
            } else {
                currentSelections.append(optionText)
            }
        } else {
            currentSelections = [optionText]
        }
        
        CreateMyGFUseCase.shared.saveSelection(questionId: question.id, options: currentSelections)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        refreshSelection()
        delegate?.didSelectOption(questionId: question.id)
    }
    
    func refreshSelection() {
        guard let question = question else { return }
        let savedSelections = CreateMyGFUseCase.shared.getSelection(questionId: question.id)
        
        for button in optionsStack.arrangedSubviews {
            guard let btn = button as? UIButton,
                  let title = btn.title(for: .normal) else { continue }
            
            let isSelected = savedSelections.contains(title)
            updateButtonAppearance(btn, isSelected: isSelected)
        }
    }
}

extension MyGFOneScreenView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        layer.cornerRadius = 24
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        optionsStack.spacing = 14
        
        titleLabel.snp.updateConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(24)
        }
        
        optionsStack.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.trailing.bottom.equalToSuperview().inset(24)
        }
    }
}
