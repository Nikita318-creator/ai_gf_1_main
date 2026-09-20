import UIKit
import SnapKit

class FeedbackAlertView: UIView {
    
    var onSendTapped: ((String) -> Void)?
    
    // UI Elements
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let textView = UITextView()
    
    // Email Elements
    private let emailTextField = UITextField()
    private let emailHintLabel = UILabel()
    
    // SubtitleLabel теперь используется как финальный дисклеймер или нижнее описание
    private let subtitleLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupKeyboardObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Background
        backgroundView.backgroundColor = MyColors.background.withAlphaComponent(0.8)
        backgroundView.alpha = 0
        addSubview(backgroundView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        backgroundView.addGestureRecognizer(tap)
        
        // Container
        containerView.backgroundColor = MyColors.cardBackground
        containerView.layer.cornerRadius = 24
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: 50)
        addSubview(containerView)
        
        // Labels
        titleLabel.text = "UserSupport.Header".localize()
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        subtitleLabel.text = "UserSupport.PrivacyNote".localize()
        subtitleLabel.textColor = MyColors.textSecondary
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        containerView.addSubview(subtitleLabel)
        
        // Main Input (Feedback text): «вдавленное» поле темнее карточки
        textView.backgroundColor = MyColors.background
        textView.textColor = MyColors.textPrimary
        textView.tintColor = MyColors.primary
        textView.keyboardAppearance = .dark
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.cornerRadius = 14
        textView.layer.borderWidth = 1
        textView.layer.borderColor = MyColors.separator.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self
        textView.returnKeyType = .done
        containerView.addSubview(textView)
        
        // Email TextField
        emailTextField.backgroundColor = MyColors.background
        emailTextField.textColor = MyColors.textPrimary
        emailTextField.tintColor = MyColors.primary
        emailTextField.keyboardAppearance = .dark
        emailTextField.font = UIFont.systemFont(ofSize: 15)
        emailTextField.layer.cornerRadius = 14
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = MyColors.separator.cgColor
        emailTextField.placeholder = "Email (optional)"
        // Отступ слева для текста внутри UITextField
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 40))
        emailTextField.leftViewMode = .always
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.delegate = self
        emailTextField.returnKeyType = .done
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email (optional)",
            attributes: [NSAttributedString.Key.foregroundColor: MyColors.textSecondary]
        )
        containerView.addSubview(emailTextField)
        
        // Email Hint Label (подпись под полем)
        emailHintLabel.text = "UserSupport.ContactFieldHint".localize()
        emailHintLabel.textColor = MyColors.textSecondary
        emailHintLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        emailHintLabel.textAlignment = .left
        emailHintLabel.numberOfLines = 0
        containerView.addSubview(emailHintLabel)
        
        // Buttons
        sendButton.setTitle("Send".localize(), for: .normal)
        sendButton.backgroundColor = MyColors.primary
        sendButton.setTitleColor(MyColors.textPrimary, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        sendButton.layer.cornerRadius = 14
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        closeButton.tintColor = MyColors.textSecondary
        closeButton.backgroundColor = MyColors.textPrimary.withAlphaComponent(0.08)
        closeButton.layer.cornerRadius = 15
        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        setupConstraints()
    }
    
    /// Карточка: по бокам 24, но на iPad не шире 480 и всегда по центру
    private func applyContainerHorizontalConstraints(_ make: ConstraintMaker) {
        make.centerX.equalToSuperview()
        make.leading.trailing.equalToSuperview().inset(24).priority(.high)
        make.width.lessThanOrEqualTo(480)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            applyContainerHorizontalConstraints(make)
            make.centerY.equalToSuperview().priority(.low)
            make.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.width.height.equalTo(30)
        }
        
        // Заголовок на одной линии с кнопкой закрытия; боковые отступы симметричны, чтобы текст оставался по центру
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(19)
            make.leading.trailing.equalToSuperview().inset(52)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(110)
        }
        
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(46)
        }
        
        emailHintLabel.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(emailHintLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        containerView.snp.remakeConstraints { make in
            self.applyContainerHorizontalConstraints(make)
            make.bottom.equalToSuperview().offset(-keyboardHeight - 20)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide() {
        containerView.snp.remakeConstraints { make in
            self.applyContainerHorizontalConstraints(make)
            make.centerY.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @objc private func sendTapped() {
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        var finalMessage = text
        
        // Проверяем, ввел ли пользователь email
        if let email = emailTextField.text, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalMessage += "\nemail: \(email.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        
        onSendTapped?(finalMessage)
        dismissAlert()
    }
    
    @objc private func dismissKeyboard() {
        endEditing(true)
    }
    
    @objc func dismissAlert() {
        endEditing(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 50)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    func show(in view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }, completion: nil)
        
        textView.becomeFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Focus ring (только внешний вид: рамка поля подсвечивается акцентом)

extension FeedbackAlertView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderColor = MyColors.primary.cgColor
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderColor = MyColors.separator.cgColor
    }
}

extension FeedbackAlertView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = MyColors.primary.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = MyColors.separator.cgColor
    }
}
