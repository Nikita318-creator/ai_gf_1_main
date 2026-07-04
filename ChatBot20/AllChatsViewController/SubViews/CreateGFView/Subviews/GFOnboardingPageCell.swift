import UIKit
import SnapKit

// MARK: - Onboarding Page Cell
class GFOnboardingPageCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var actionButtonStackView: UIStackView?
    private var sliderStackView: UIStackView?
    
    // MARK: - Page 1
    private let yourNameTextField = UITextField()
    private let gfNameTextField = UITextField()
    
    // MARK: - Page 4 & 5
    private let slider = UISlider()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()

    // MARK: - Page 6
    private let yesButton = UIButton(type: .system)
    private let keepDistanceButton = UIButton(type: .system)

    private let progressStackView = UIStackView()
    private var progressIndicators: [UIView] = []
    private let totalPages = 7 // Общее количество страниц
    
    weak var delegate: GFOnboardingPageCellDelegate?
    private var currentPageIndex: Int = 0
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupProgressIndicators()
        updateTextForIPadIfNeeded()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let smallerSide = min(self.bounds.width, self.bounds.height)
        
        if isCurrentDeviceiPad() {
            // Удаляем старые констрейнты и задаем новые
            imageView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(30) // Отступ сверху
                make.centerX.equalToSuperview() // Всегда по центру
                make.height.width.equalTo(smallerSide * 0.8) // Размер 80% от меньшей стороны
            }
        }
        
        // Применяем маску к imageView, чтобы закруглить только верхние углы
        self.roundTopCorners(view: imageView, cornerRadius: 20)
    }
    
    // MARK: - Public
    func configure(for index: Int) {
        self.currentPageIndex = index
        resetView() // Reset UI for reuse
        
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(descriptionLabel)
        
        // Устанавливаем их constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.leading.trailing.equalTo(contentView).inset(24)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(contentView).inset(24)
        }
        
        updateProgress(for: index)
        if isCurrentDeviceiPad() {
            scrollView.contentInset.bottom = 300
        }
        
        switch index {
        case 0: configurePage1() // Names
        case 1: configurePage2() // Buttocks
        case 2: configurePage3() // Breasts
        case 3: configurePage4() // Candor
        case 4: configurePage5() // Modesty
        case 5: configurePage6() // Distance
        case 6: configurePage7() // пейволл ???
        default: break
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Добавляем scrollView в contentView ячейки
        contentView.addSubview(scrollView)
        
        // Убедимся, что scrollView занимает всю площадь contentView
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Далее все элементы добавляем в scrollView
        // Так как scrollView является subview в contentView,
        // все элементы, добавленные в scrollView, будут видимы.
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        
        let titleLabelHeight: CGFloat = isCurrentDeviceiPad() ? 40 : 22
        let descriptionLabelHeight: CGFloat = isCurrentDeviceiPad() ? 30 : 16

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: titleLabelHeight, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        scrollView.addSubview(titleLabel)
        
        descriptionLabel.textColor = .lightGray
        descriptionLabel.font = .systemFont(ofSize: descriptionLabelHeight, weight: .regular)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        scrollView.addSubview(descriptionLabel)
        
        // Ограничения для общих элементов
        imageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.height.width.equalTo(self.snp.width)
        }
    }
    
    private func roundTopCorners(view: UIView, cornerRadius: CGFloat) {
        // Создаем маску слоя
        let maskPath = UIBezierPath(
            roundedRect: view.bounds,
            byRoundingCorners: isCurrentDeviceiPad() ? [.allCorners] : [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = view.bounds
        shapeLayer.path = maskPath.cgPath
        
        // Применяем маску к слою
        view.layer.mask = shapeLayer
    }
    
    private func setupProgressIndicators() {
        progressStackView.axis = .horizontal
        progressStackView.spacing = 8
        progressStackView.distribution = .fillEqually
        
        // Добавляем stackView в ваш main view
        addSubview(progressStackView)
        
        // Устанавливаем constraints
        progressStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(4) // Высота индикатора
        }
        
        for _ in 0..<totalPages {
            let indicatorView = UIView()
            indicatorView.backgroundColor = .systemGray4 // Серый цвет
            indicatorView.layer.cornerRadius = 2
            progressStackView.addArrangedSubview(indicatorView)
            progressIndicators.append(indicatorView)
        }
    }
    
    private func updateProgress(for index: Int) {
        for i in 0..<progressIndicators.count {
            if i <= index {
                UIView.animate(withDuration: 0.3) {
                    self.progressIndicators[i].backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
                }
            } else {
                // Иначе - серый
                self.progressIndicators[i].backgroundColor = .systemGray4
            }
        }
    }
    
    // MARK: - Page Configurations
    private func resetView() {
        // Удаляем все subviews из scrollView
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        // Пересоздаем общие элементы
        setupUI()
    }
    
    private func configurePage1() {
        titleLabel.text = "CustomGFPromptsNew20".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion39")
        } else {
            imageView.image = UIImage(named: "CustomAvatar1")
        }
        
        setupTextField(yourNameTextField, placeholder: "CreateYourGF.EnterName".localize())
        setupTextField(gfNameTextField, placeholder: "CreateYourGF.GiveGFName".localize())
        
        scrollView.addSubview(yourNameTextField)
        scrollView.addSubview(gfNameTextField)
        
        let textFieldHeight: CGFloat = isCurrentDeviceiPad() ? 70 : 50
        
        yourNameTextField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.leading.trailing.equalTo(contentView).inset(24)
            make.height.equalTo(textFieldHeight)
        }
        
        gfNameTextField.snp.makeConstraints { make in
            make.top.equalTo(yourNameTextField.snp.bottom).offset(20)
            make.leading.trailing.equalTo(contentView).inset(24)
            make.height.equalTo(textFieldHeight)
            make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
        }
        
        yourNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        gfNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    private func configurePage2() {
        titleLabel.text = "CustomGFPromptsNew15".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion48")
        } else {
            imageView.image = UIImage(named: "CustomAvatar3")
        }
        
        let buttockOptions = ["CustomGFPromptsNew16".localize(), "CustomGFPromptsNew17".localize(), "CustomGFPromptsNew18".localize(), "CustomGFPromptsNew19".localize()]
        let buttons = buttockOptions.map { createOptionButton(title: $0) }
        
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        scrollView.addSubview(stackView)
        
        let actualHeight = isCurrentDeviceiPad() ? 75 : 60
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.leading.trailing.equalTo(contentView).inset(24)
            make.height.equalTo(buttons.count * actualHeight)
            make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
        }
        
        buttons.forEach { $0.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside) }
    }
    
    private func configurePage3() {
        titleLabel.text = "CustomGFPromptsNew10".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion52")
        } else {
            imageView.image = UIImage(named: "CustomAvatar2")
        }
        
        let breastOptions = ["CustomGFPromptsNew11".localize(), "CustomGFPromptsNew12".localize(), "CustomGFPromptsNew13".localize(), "CustomGFPromptsNew14".localize()]
        let buttons = breastOptions.map { createOptionButton(title: $0) }
        
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        scrollView.addSubview(stackView)
        
        let actualHeight = isCurrentDeviceiPad() ? 75 : 60

        stackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.leading.trailing.equalTo(contentView).inset(24)
            make.height.equalTo(buttons.count * actualHeight)
            make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
        }
        
        buttons.forEach { $0.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside) }
    }
    
    private func configurePage4() {
        titleLabel.text = "CustomGFPromptsNew7".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion56")
        } else {
            imageView.image = UIImage(named: "CustomAvatar6")
        }
        
        setupSlider(slider, minLabel: minLabel, maxLabel: maxLabel, minText: "CustomGFPromptsNew8".localize(), maxText: "CustomGFPromptsNew9".localize())
        
        scrollView.addSubview(slider)
        scrollView.addSubview(minLabel)
        scrollView.addSubview(maxLabel)
        
        slider.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(80)
            make.leading.trailing.equalTo(contentView).inset(40)
            make.height.equalTo(30)
        }
        
        minLabel.snp.makeConstraints { make in
            make.bottom.equalTo(slider.snp.top).offset(-8)
            make.leading.equalTo(slider)
        }
        
        maxLabel.snp.makeConstraints { make in
            make.bottom.equalTo(slider.snp.top).offset(-8)
            make.trailing.equalTo(slider)
        }
        
        slider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .valueChanged)
    }

    private func configurePage5() {
        titleLabel.text = "CustomGFPromptsNew1".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion73")
        } else {
            imageView.image = UIImage(named: "CustomAvatar8")
        }
        
        setupSlider(slider, minLabel: minLabel, maxLabel: maxLabel, minText: "CustomGFPromptsNew2".localize(), maxText: "CustomGFPromptsNew3".localize())
        
        scrollView.addSubview(slider)
        scrollView.addSubview(minLabel)
        scrollView.addSubview(maxLabel)
        
        slider.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(80)
            make.leading.trailing.equalTo(contentView).inset(40)
            make.height.equalTo(30)
        }
        
        minLabel.snp.makeConstraints { make in
            make.bottom.equalTo(slider.snp.top).offset(-8)
            make.leading.equalTo(slider)
        }
        
        maxLabel.snp.makeConstraints { make in
            make.bottom.equalTo(slider.snp.top).offset(-8)
            make.trailing.equalTo(slider)
        }

        slider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .valueChanged)
    }

    private func configurePage6() {
        if GEOService.shared.isAsionGeo {
            titleLabel.text = "CustomGFPromptsNew27".localize()
            imageView.image = UIImage(named: "asion92")
            
            let hairOptions = ["CustomGFPromptsNew35".localize(), "CustomGFPromptsNew36".localize(), "CustomGFPromptsNew37".localize(), "CustomGFPromptsNew38".localize()]
            let buttons = hairOptions.map { createOptionButton(title: $0) }
            
            let stackView = UIStackView(arrangedSubviews: buttons)
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.distribution = .fillEqually
            scrollView.addSubview(stackView)
            
            let actualHeight = isCurrentDeviceiPad() ? 75 : 60

            stackView.snp.makeConstraints { make in
                make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
                make.leading.trailing.equalTo(contentView).inset(24)
                make.height.equalTo(buttons.count * actualHeight)
                make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
            }
            
            buttons.forEach { $0.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside) }
        } else {
            titleLabel.text = "CustomGFPromptsNew27".localize()
            imageView.image = UIImage(named: "CustomAvatar10")
            
            let hairOptions = ["CustomGFPromptsNew28".localize(), "CustomGFPromptsNew29".localize(), "CustomGFPromptsNew30".localize(), "CustomGFPromptsNew31".localize(), "CustomGFPromptsNew32".localize(), "CustomGFPromptsNew33".localize()]
            let buttons = hairOptions.map { createOptionButton(title: $0) }
            
            let stackView = UIStackView(arrangedSubviews: buttons)
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.distribution = .fillEqually
            scrollView.addSubview(stackView)
            
            let actualHeight = isCurrentDeviceiPad() ? 75 : 60

            stackView.snp.makeConstraints { make in
                make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
                make.leading.trailing.equalTo(contentView).inset(24)
                make.height.equalTo(buttons.count * actualHeight)
                make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
            }
            
            buttons.forEach { $0.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside) }
        }
    }
    
    private func configurePage7() {
        titleLabel.text = "CustomGFPromptsNew4".localize()
        descriptionLabel.text = "CustomGFPromptsNew21".localize()
        
        if GEOService.shared.isAsionGeo {
            imageView.image = UIImage(named: "asion78")
        } else {
            imageView.image = UIImage(named: "CustomAvatar13")
        }
        
        let titleLabelHeight: CGFloat = isCurrentDeviceiPad() ? 32 : 18

        yesButton.setTitle("CustomGFPromptsNew5".localize(), for: .normal)
        yesButton.setTitleColor(.white, for: .normal)
        yesButton.titleLabel?.font = .systemFont(ofSize: titleLabelHeight, weight: .semibold)
        yesButton.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        yesButton.layer.cornerRadius = 20
        yesButton.clipsToBounds = true
        yesButton.addTarget(self, action: #selector(yesTapped(_:)), for: .touchUpInside)
        
        keepDistanceButton.setTitle("CustomGFPromptsNew6".localize(), for: .normal)
        keepDistanceButton.setTitleColor(.white, for: .normal)
        keepDistanceButton.titleLabel?.font = .systemFont(ofSize: titleLabelHeight, weight: .semibold)
        keepDistanceButton.backgroundColor = .darkGray
        keepDistanceButton.layer.cornerRadius = 20
        keepDistanceButton.clipsToBounds = true
        keepDistanceButton.addTarget(self, action: #selector(keepDistanceTapped(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [yesButton, keepDistanceButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        scrollView.addSubview(stackView)
        
        let actualHeight = isCurrentDeviceiPad() ? 150 : 120

        stackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.leading.trailing.equalTo(contentView).inset(24)
            make.height.equalTo(actualHeight)
            make.bottom.lessThanOrEqualTo(scrollView.snp.bottom).offset(-20)
        }
    }

    // MARK: - Helper methods
    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        textField.layer.cornerRadius = 12
        textField.textColor = .white
        let fontSize: CGFloat = isCurrentDeviceiPad() ? 26 : 16
        textField.font = .systemFont(ofSize: fontSize, weight: .regular)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)]
        )
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.rightViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
    }
    
    private func setupSlider(_ slider: UISlider, minLabel: UILabel, maxLabel: UILabel, minText: String, maxText: String) {
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.5
        slider.tintColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        slider.thumbTintColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        
        let fontSize: CGFloat = isCurrentDeviceiPad() ? 26 : 13
        
        minLabel.text = minText
        minLabel.font = .systemFont(ofSize: fontSize, weight: .regular)
        minLabel.textColor = .lightGray
        
        maxLabel.text = maxText
        maxLabel.font = .systemFont(ofSize: fontSize, weight: .regular)
        maxLabel.textColor = .lightGray
    }

    private func createOptionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        let fontSize: CGFloat = isCurrentDeviceiPad() ? 28 : 18
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        button.clipsToBounds = true
        
        if isCurrentDeviceiPad() {
            button.layer.cornerRadius = 20
            button.snp.makeConstraints { make in
                make.height.equalTo(70)
            }
        } else {
            button.layer.cornerRadius = 12
            button.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
        }
        return button
    }

    // MARK: - Actions
    @objc private func textFieldDidChange() {
        delegate?.didUpdateName(yourName: yourNameTextField.text, gfName: gfNameTextField.text)
    }

    @objc private func optionButtonTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }

        // Анимация нажатия и смена цвета
        UIView.animate(withDuration: 0.2, animations: {
            // Уменьшаем размер и меняем цвет при нажатии
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        }) { [weak self] _ in
            // Возвращаем кнопку в исходное состояние после анимации
            UIView.animate(withDuration: 0.2, animations: {
                sender.transform = .identity
                self?.delegate?.didSelectBodySize(type: title)
            })
        }
    }
    
    @objc private func sliderDidChange(_ sender: UISlider) {
        delegate?.didChangeSliderValue(pageIndex: currentPageIndex, value: sender.value)
    }
    
    @objc private func nextPageTapped() {
        delegate?.didCompletePage(at: currentPageIndex)
    }
    
    @objc private func yesTapped(_ sender: UIButton) {
        // Анимация нажатия и смена цвета
        UIView.animate(withDuration: 0.2, animations: {
            // Уменьшаем размер и меняем цвет при нажатии
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { [weak self] _ in
            // Возвращаем кнопку в исходное состояние после анимации
            UIView.animate(withDuration: 0.2, animations: {
                sender.transform = .identity
                self?.delegate?.didChooseDistance(keepDistance: false)
            })
        }
    }
    
    @objc private func keepDistanceTapped(_ sender: UIButton) {
        // Анимация нажатия и смена цвета
        UIView.animate(withDuration: 0.2, animations: {
            // Уменьшаем размер и меняем цвет при нажатии
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { [weak self] _ in
            // Возвращаем кнопку в исходное состояние после анимации
            UIView.animate(withDuration: 0.2, animations: {
                sender.transform = .identity
                self?.delegate?.didChooseDistance(keepDistance: true)
            })
        }
    }
}

extension GFOnboardingPageCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == yourNameTextField {
            gfNameTextField.becomeFirstResponder()
        } else if textField == gfNameTextField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 30
    }
}

extension GFOnboardingPageCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        descriptionLabel.font = .systemFont(ofSize: 30, weight: .regular)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let safeAreaBottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let bottomInset = keyboardHeight + safeAreaBottom
        
        self.scrollView.contentInset.bottom = bottomInset
        
        // Прокручиваем к самому низу
        let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
        if bottomOffset.y > 0 {
            self.scrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset.bottom = isCurrentDeviceiPad() ? 300 : 0
    }
}
