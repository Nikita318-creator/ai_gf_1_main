import UIKit
import SnapKit

class ChatRockStarBottomTextFild: UIView {
    
    private let _vMod = ChatRockStarBottomTextFildVM()
    
    var sendMessageHandler: ((String) -> Void)? { get { _vMod.sendMessageHandler } set { _vMod.sendMessageHandler = newValue } }
    var pleaseWaitHandler: (() -> Void)? { get { _vMod.pleaseWaitHandler } set { _vMod.pleaseWaitHandler = newValue } }
    var textDidChangedHandler: (() -> Void)? { get { _vMod.textDidChangedHandler } set { _vMod.textDidChangedHandler = newValue } }
    var needPremiumForAudioHandler: (() -> Void)? { get { _vMod.needPremiumForAudioHandler } set { _vMod.needPremiumForAudioHandler = newValue } }

    var canSendMessage: Bool { get { _vMod.canSendMessage } set { _vMod.canSendMessage = newValue } }
    weak var vc: UIViewController? { get { _vMod.vc } set { _vMod.vc = newValue; _micEngine.vc = newValue } }

    let textView = UITextView()
    let sendButton = UIButton(type: .system)
    let placeholderLabel = UILabel()
    private let _boxContainerView = UIView()
    private let _dividerLineView = UIView()
    
    private let _toggleMenuBtn = UIButton(type: .system)
    private let _popActionMenuView = ActionMenuPopupView()
    private let _heartsStackContainer = UIStackView()
    
    private var _textContainerHeightConstraint: Constraint?
    private let _maxInputBoxHeight: CGFloat = 120
    private lazy var _minInputBoxHeight: CGFloat = isIPad() ? 50 : 36
    
    private enum ActionButtonState { case mic, stop, send }
    private var _actionButtonMode: ActionButtonState = .mic
    private let _micEngine = MicService()
    private var _capturedVoiceText = ""

    private let _audioVisualizerContainer = UIView()
    private var _audioVisualizerBarViews: [UIView] = []
    private var _isWaveAnimatingActive = false
    private var _shouldAutoScrollToEnd: Bool = true

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }
        
        if !_popActionMenuView.isHidden {
            let _convertedPoint = convert(point, to: _popActionMenuView)
            if _popActionMenuView.point(inside: _convertedPoint, with: event) {
                return _popActionMenuView.hitTest(_convertedPoint, with: event)
            } else {
                let _hitTargetView = super.hitTest(point, with: event)
                if _hitTargetView != _toggleMenuBtn {
                    hideMenu()
                }
                return _hitTargetView
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    func setup() {
        clipsToBounds = false
        _configureBaseBackground()
        _configureHeartsContainer()
        _configureInputContainerView()
        _configureTextEntryView()
        _configureAudioVisualizer()
        _configureActionButtons()
        _configureMenuToggleButton()
        _configureActionMenuView()
        _applyLayoutConstraints()
        _refreshActionButtonState()
        iPadCheck()
        _evaluatePromptsVisibility()
        
        _micEngine.onResult = { [weak self] _recognizedText in
            self?._capturedVoiceText = _recognizedText
            self?.textView.text = _recognizedText
            self?._recalculateTextViewHeight()
        }
    }
    
    private func _configureBaseBackground() {
        backgroundColor = .clear
        _dividerLineView.backgroundColor = BasePalitColors.separator
        addSubview(_dividerLineView)
    }
    
    private func _configureHeartsContainer() {
        _heartsStackContainer.axis = .horizontal
        _heartsStackContainer.spacing = 8
        addSubview(_heartsStackContainer)
    }
    
    private func _configureInputContainerView() {
        _boxContainerView.backgroundColor = BasePalitColors.inputBackground
        _boxContainerView.layer.cornerRadius = 20
        _boxContainerView.layer.borderWidth = 1
        _boxContainerView.layer.borderColor = BasePalitColors.separator.withAlphaComponent(0.6).cgColor
        addSubview(_boxContainerView)
    }
    
    private func _configureTextEntryView() {
        let _isRightToLeftDirection = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = _isRightToLeftDirection ? .forceRightToLeft : .forceLeftToRight
        
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = BasePalitColors.textPrimary
        textView.backgroundColor = .clear
        textView.textAlignment = _isRightToLeftDirection ? .right : .left
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.enablesReturnKeyAutomatically = true
        
        placeholderLabel.text = "Type a message..."
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = BasePalitColors.textSecondary
        placeholderLabel.textAlignment = _isRightToLeftDirection ? .right : .left
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        _boxContainerView.addSubview(textView)
        _boxContainerView.addSubview(placeholderLabel)
    }

    private func _configureAudioVisualizer() {
        _audioVisualizerContainer.backgroundColor = .clear
        _audioVisualizerContainer.isHidden = true
        _boxContainerView.addSubview(_audioVisualizerContainer)

        _audioVisualizerContainer.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.trailing.equalTo(textView)
            _layoutMaker.centerY.equalTo(textView)
            _layoutMaker.height.equalTo(_minInputBoxHeight)
        }

        let _barsTotalCount = 5
        for _barIndex in 0..<_barsTotalCount {
            let _singleBarView = UIView()
            _singleBarView.backgroundColor = BasePalitColors.textSecondary
            _singleBarView.layer.cornerRadius = 1.5
            _audioVisualizerContainer.addSubview(_singleBarView)
            _audioVisualizerBarViews.append(_singleBarView)

            _singleBarView.snp.makeConstraints { _layoutMaker in
                _layoutMaker.width.equalTo(4)
                _layoutMaker.height.equalTo(_minInputBoxHeight * 0.5)
                _layoutMaker.centerY.equalToSuperview()
                _layoutMaker.leading.equalTo(_barIndex == 0 ? 0 : _audioVisualizerBarViews[_barIndex - 1].snp.trailing).offset(4)
            }
        }
    }
    
    private func _configureActionButtons() {
        sendButton.layer.cornerRadius = 18
        sendButton.addTarget(self, action: #selector(_handleActionButtonClick), for: .touchUpInside)
        let _longTouchRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(_handleLongPressGesture(_:)))
        _longTouchRecognizer.minimumPressDuration = 0.5
        sendButton.addGestureRecognizer(_longTouchRecognizer)
        addSubview(sendButton)
    }
    
    private func _configureMenuToggleButton() {
        let _iconPointSize: CGFloat = isIPad() ? 28 : 22
        let _chevronImage = UIImage(systemName: "chevron.up.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: _iconPointSize, weight: .medium))
        
        _toggleMenuBtn.setImage(_chevronImage, for: .normal)
        _toggleMenuBtn.tintColor = BasePalitColors.textSecondary
        _toggleMenuBtn.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        addSubview(_toggleMenuBtn)
    }
    
    private func _configureActionMenuView() {
        _popActionMenuView.isHidden = true
        addSubview(_popActionMenuView)
        
        _popActionMenuView.onGiftTapped = { [weak self] in
            self?.hideMenu()
        }
        
        _popActionMenuView.onPhotoVideoTapped = { [weak self] _promptContent in
            self?.hideMenu()
            self?._vMod.sendText(_promptContent) {
                self?._resetInputToDefault()
            }
        }
        
        _popActionMenuView.onAudioToggled = { [weak self] _isAudioEnabled in
            guard let self = self else { return }
            if _isAudioEnabled && !AppHudAdapter.shared.hasActiveSubscription {
                self._popActionMenuView.audioToggleSwitch.setOn(false, animated: true)
                self.needPremiumForAudioHandler?()
            } else {
                MyGovnoSingltone.shared.voiceChatToggleOn = _isAudioEnabled
            }
        }
    }
    
    private func _applyLayoutConstraints() {
        _dividerLineView.snp.makeConstraints { _layoutMaker in
            _layoutMaker.top.leading.trailing.equalToSuperview()
            _layoutMaker.height.equalTo(0.5)
        }
        
        _heartsStackContainer.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.equalToSuperview().inset(16)
            _layoutMaker.bottom.equalTo(_boxContainerView.snp.top).offset(-8)
            _layoutMaker.height.equalTo(24)
        }

        sendButton.snp.makeConstraints { _layoutMaker in
            _layoutMaker.trailing.equalToSuperview().inset(16)
            _layoutMaker.bottom.equalTo(_boxContainerView).inset(2)
            _layoutMaker.width.height.equalTo(36)
        }
        
        _toggleMenuBtn.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.equalToSuperview().inset(12)
            _layoutMaker.bottom.equalTo(_boxContainerView).inset(4)
            _layoutMaker.width.height.equalTo(36)
        }
        
        _boxContainerView.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.equalTo(_toggleMenuBtn.snp.trailing).offset(8)
            _layoutMaker.trailing.equalTo(sendButton.snp.leading).offset(-8)
            _layoutMaker.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            _layoutMaker.top.greaterThanOrEqualTo(_heartsStackContainer.snp.bottom).offset(12)
        }
        
        textView.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.trailing.equalToSuperview().inset(12)
            _layoutMaker.top.bottom.equalToSuperview().inset(6)
            _textContainerHeightConstraint = _layoutMaker.height.equalTo(_minInputBoxHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.trailing.equalTo(textView)
            _layoutMaker.centerY.equalTo(textView)
        }
        
        _popActionMenuView.snp.makeConstraints { _layoutMaker in
            _layoutMaker.leading.equalTo(_toggleMenuBtn.snp.leading)
            _layoutMaker.bottom.equalTo(_toggleMenuBtn.snp.top).offset(-12)
            _layoutMaker.width.equalTo(250)
        }
    }
    
    private func _evaluatePromptsVisibility() {
        if BackendService.shared.currentData.aiText.isEmpty {
            _popActionMenuView.togglePicButton()
            _popActionMenuView.toggleClipButton()
        }
    }

    func showMenu() {
        guard _popActionMenuView.isHidden else { return }
        _popActionMenuView.alpha = 0
        _popActionMenuView.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self._popActionMenuView.alpha = 1
            self._toggleMenuBtn.transform = CGAffineTransform(rotationAngle: .pi)
        }
    }
    
    func hideMenu() {
        guard !_popActionMenuView.isHidden else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self._popActionMenuView.alpha = 0
            self._toggleMenuBtn.transform = .identity
        }) { _ in
            self._popActionMenuView.isHidden = true
        }
    }
    
    @objc func toggleMenu() {
        if _popActionMenuView.isHidden {
            showMenu()
        } else {
            hideMenu()
        }
    }

    func toggleClipButton() { _popActionMenuView.toggleClipButton() }
    func togglePicButton() { _popActionMenuView.togglePicButton() }
    
    func enableSendButton() {
        _vMod.canSendMessage = true
        if self._actionButtonMode == .send {
            self.sendButton.backgroundColor = BasePalitColors.primary
        }
    }
    
    private func _resetInputToDefault() {
        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0.5
        }) { _ in
            self.textView.text = ""
            self.textView.alpha = 1.0
            self.placeholderLabel.isHidden = false
            self._refreshActionButtonState()
            self._recalculateTextViewHeight()
        }
    }
    
    private func _refreshActionButtonState() {
        let _hasUserTypedText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if _hasUserTypedText { _actionButtonMode = .send }
        else if _actionButtonMode != .stop { _actionButtonMode = .mic }
        
        var _assignedIconImage: UIImage?
        var _assignedBgColor: UIColor

        textView.isHidden = false
        placeholderLabel.isHidden = !textView.text.isEmpty
        _audioVisualizerContainer.isHidden = true
        _disableAudioWaveAnimation()

        let _iconPointSize: CGFloat = isIPad() ? 24 : 16
        switch _actionButtonMode {
        case .mic:
            _assignedIconImage = UIImage(systemName: "mic.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: _iconPointSize, weight: .semibold))
            _assignedBgColor = BasePalitColors.inputBackground
            if textView.inputView != nil { textView.resignFirstResponder(); textView.inputView = nil; textView.reloadInputViews() }
        case .stop:
            _assignedIconImage = UIImage(systemName: "stop.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: _iconPointSize, weight: .semibold))
            _assignedBgColor = BasePalitColors.accentRed
            placeholderLabel.isHidden = true
            _audioVisualizerContainer.isHidden = true
            _enableAudioWaveAnimation()
            textView.inputView = UIView()
            textView.reloadInputViews()
            textView.becomeFirstResponder()
        case .send:
            _assignedIconImage = UIImage(systemName: "paperplane.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: _iconPointSize, weight: .semibold))
            _assignedBgColor = canSendMessage ? BasePalitColors.primary : BasePalitColors.inputBackground
            if textView.inputView != nil { textView.resignFirstResponder(); textView.inputView = nil; textView.reloadInputViews() }
        }
        
        sendButton.setImage(_assignedIconImage, for: .normal)
        sendButton.tintColor = BasePalitColors.textPrimary
        sendButton.backgroundColor = _assignedBgColor
        UIView.animate(withDuration: 0.2) { self.sendButton.transform = .identity }
    }
    
    private func _refreshActionButtonForLongPress() {
        _refreshActionButtonState()
        if _actionButtonMode == .stop {
            sendButton.tintColor = BasePalitColors.textPrimary
            sendButton.backgroundColor = BasePalitColors.primary
            _enablePulsatingMicEffect()
        } else {
            _disablePulsatingMicEffect()
        }
    }
    
    private func _recalculateTextViewHeight() {
        _textContainerHeightConstraint?.update(offset: _minInputBoxHeight)
        textView.isScrollEnabled = true
    }
    
    private func _enablePulsatingMicEffect() {
        let _pulseEffectLayer = CALayer()
        _pulseEffectLayer.backgroundColor = BasePalitColors.primary.withAlphaComponent(0.4).cgColor
        _pulseEffectLayer.frame = sendButton.bounds
        _pulseEffectLayer.cornerRadius = sendButton.layer.cornerRadius
        sendButton.layer.insertSublayer(_pulseEffectLayer, at: 0)
        
        let _scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        _scaleAnim.fromValue = 1.0
        _scaleAnim.toValue = 3.0
        
        let _opacityAnim = CABasicAnimation(keyPath: "opacity")
        _opacityAnim.fromValue = 0.8
        _opacityAnim.toValue = 0.0
        
        let _animGroup = CAAnimationGroup()
        _animGroup.animations = [_scaleAnim, _opacityAnim]
        _animGroup.duration = 1.0
        _animGroup.repeatCount = .infinity
        _animGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        _pulseEffectLayer.add(_animGroup, forKey: "pulsingAnimation")
        sendButton.layer.setValue(_pulseEffectLayer, forKey: "pulseLayer")
    }

    private func _disablePulsatingMicEffect() {
        if let _pulseEffectLayer = sendButton.layer.value(forKey: "pulseLayer") as? CALayer {
            _pulseEffectLayer.removeFromSuperlayer()
            sendButton.layer.setValue(nil, forKey: "pulseLayer")
        }
    }
    
    private func _enableAudioWaveAnimation() {
        guard !_isWaveAnimatingActive else { return }
        _isWaveAnimatingActive = true
        let _maxScaleYFactor: CGFloat = 2.0; let _minScaleYFactor: CGFloat = 0.5; let _animationDuration: TimeInterval = 0.6
        for (_barIdx, _barView) in _audioVisualizerBarViews.enumerated() {
            let _waveAnim = CABasicAnimation(keyPath: "transform.scale.y")
            _waveAnim.fromValue = _minScaleYFactor
            _waveAnim.toValue = _maxScaleYFactor
            _waveAnim.autoreverses = true
            _waveAnim.repeatCount = .infinity
            _waveAnim.duration = _animationDuration
            _waveAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            _waveAnim.beginTime = CACurrentMediaTime() + Double(_barIdx) * (_animationDuration / Double(_audioVisualizerBarViews.count))
            _barView.layer.add(_waveAnim, forKey: "scaleAnimation")
        }
    }

    private func _disableAudioWaveAnimation() {
        guard _isWaveAnimatingActive else { return }
        _isWaveAnimatingActive = false
        for _barView in _audioVisualizerBarViews { _barView.layer.removeAnimation(forKey: "scaleAnimation") }
    }
    
    @objc private func _handleActionButtonClick() {
        switch _actionButtonMode {
        case .mic:
            _capturedVoiceText = ""
            _actionButtonMode = .stop
            _refreshActionButtonState()
            _micEngine.startRecognition()
        case .stop:
            _actionButtonMode = .mic
            _refreshActionButtonState()
            _micEngine.stopRecognition()
            _vMod.sendText(_capturedVoiceText) { self._resetInputToDefault() }
        case .send:
            if let _currentInputText = textView.text {
                if let _primaryLanguage = textView.textInputMode?.primaryLanguage { MyGovnoSingltone.shared.userLang = _primaryLanguage }
                _vMod.sendText(_currentInputText) { self._resetInputToDefault() }
            }
        }
    }

    @objc private func _handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            _capturedVoiceText = ""
            _actionButtonMode = .stop
            _refreshActionButtonForLongPress()
            _micEngine.startRecognition()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .ended, .cancelled:
            _actionButtonMode = .mic
            _refreshActionButtonForLongPress()
            _micEngine.stopRecognition()
            _vMod.sendText(_capturedVoiceText) { self._resetInputToDefault() }
        default: break
        }
    }
}

extension ChatRockStarBottomTextFild: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChangedHandler?()
        placeholderLabel.isHidden = !textView.text.isEmpty
        _refreshActionButtonState()
        _recalculateTextViewHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let _existingContent = textView.text ?? ""
        guard let _targetRange = Range(range, in: _existingContent) else { return false }
        let _newProposedContent = _existingContent.replacingCharacters(in: _targetRange, with: text)
        return _newProposedContent.count <= 2000
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        _boxContainerView.layer.borderColor = BasePalitColors.primary.withAlphaComponent(0.6).cgColor
        hideMenu()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self._boxContainerView.layer.shadowOpacity = 0.2
            self._boxContainerView.layer.shadowRadius = 6
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        _boxContainerView.layer.borderColor = BasePalitColors.separator.withAlphaComponent(0.6).cgColor
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self._boxContainerView.layer.shadowOpacity = 0.1
            self._boxContainerView.layer.shadowRadius = 3
            self._boxContainerView.transform = .identity
        }
    }
}

extension ChatRockStarBottomTextFild {
    func iPadCheck() {
        guard isIPad() else { return }
        _boxContainerView.layer.cornerRadius = 28
        sendButton.layer.cornerRadius = 28
        textView.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        placeholderLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        sendButton.snp.updateConstraints { _layoutMaker in _layoutMaker.width.height.equalTo(56) }
        _toggleMenuBtn.snp.updateConstraints { _layoutMaker in _layoutMaker.width.height.equalTo(56) }
    }
}
