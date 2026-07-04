import UIKit
import SnapKit
import Photos

class AvatarPickerView: UIView {

    // MARK: - UI Elements

    private let dimmingView = UIView() // Затемняющий фон
    private let containerView = UIView() // Контейнер для контента пикера
    private let titleLabel = UILabel()
    private let templatesCollectionView: UICollectionView
    private let chooseFromGalleryButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system) // Кнопка закрытия пикера

    // MARK: - Properties

    // Closure для передачи выбранной аватарки (UIImage) и её ID (String для asset name)
    var onAvatarSelected: ((UIImage?, String?) -> Void)?
    weak var vc: UIViewController?

    // Telegram цвета (для единообразия)
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
    }
    
    // Моковые данные для шаблонов аватаров (ID из ассетов)
    private lazy var templateAvatarNames: [String] = [
        "CustomAvatar1", "CustomAvatar2",
        "CustomAvatar3", "CustomAvatar4", "CustomAvatar5", "CustomAvatar6",
        "CustomAvatar7", "CustomAvatar8", "CustomAvatar9", "CustomAvatar10",
        "CustomAvatar11", "CustomAvatar12", "CustomAvatar13", "CustomAvatar14",
        "CustomAvatar15", "CustomAvatar16", "CustomAvatar17", "CustomAvatar18"
    ].shuffled()
    private lazy var avatarsAlreadyInUse = AssistantsService().getAllConfigs().map { $0.avatarImageName }

    // MARK: - Initialization

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 80, height: 80) // Размер ячейки аватара
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        templatesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupViews() {
        backgroundColor = .clear // Основной фон прозрачный
        
        // Затемняющий фон (dimmingView)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        addSubview(dimmingView)
        
        // Контейнер (containerView)
        containerView.backgroundColor = TelegramColors.background
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // Заголовок
        titleLabel.text = "CreateYourGF.ChooseYourAvatar".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = TelegramColors.textPrimary
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // Коллекция шаблонов аватаров
        templatesCollectionView.backgroundColor = .clear
        templatesCollectionView.dataSource = self
        templatesCollectionView.delegate = self
        templatesCollectionView.register(AvatarTemplateCell.self, forCellWithReuseIdentifier: AvatarTemplateCell.identifier)
        containerView.addSubview(templatesCollectionView)
        
        // Кнопка "Выбрать из галереи"
        chooseFromGalleryButton.setTitle("CreateYourGF.ChooseFromGallery".localize(), for: .normal)
        chooseFromGalleryButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        chooseFromGalleryButton.backgroundColor = TelegramColors.primary
        chooseFromGalleryButton.setTitleColor(TelegramColors.textPrimary, for: .normal)
        chooseFromGalleryButton.layer.cornerRadius = 12
        chooseFromGalleryButton.clipsToBounds = true
        chooseFromGalleryButton.addTarget(self, action: #selector(chooseFromGalleryTapped), for: .touchUpInside)
        containerView.addSubview(chooseFromGalleryButton)

        // Кнопка закрытия (крестик)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        ), for: .normal)
        closeButton.tintColor = TelegramColors.textSecondary
        closeButton.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        setupConstraints()
    }

    private func setupConstraints() {
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.7) // Высота контейнера
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.width.height.equalTo(36)
        }

        templatesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(chooseFromGalleryButton.snp.top).offset(-16)
        }
        
        chooseFromGalleryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    // MARK: - Actions

    @objc private func chooseFromGalleryTapped() {
        // Проверяем разрешение на доступ к фотобиблиотеке
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if status == .authorized {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = .photoLibrary
                    // UIImagePickerController должен быть презентован контроллером
                    // Так как это UIView, нужно найти ближайший UIViewController
                    if let viewController = self.vc {
                        viewController.present(picker, animated: true)
                    } else {
                        // Ошибка: не удалось найти контроллер для презентации пикера
                        print("Error: Could not find a UIViewController to present UIImagePickerController.")
                        // Можно показать алерт пользователю
                    }
                } else {
                    self.showGaleryPermissionAlert()
                }
            }
        }
    }

    private func showGaleryPermissionAlert() {
        let alert = UIAlertController(
            title: "PermissionDenied".localize(),
            message: "PermissionDenied.Message".localize(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel".localize(), style: .cancel))
        alert.addAction(UIAlertAction(title: "OpenSettings".localize(), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        })
        vc?.present(alert, animated: true)
    }
    
    @objc private func dismissPicker() {
        dismiss()
    }

    // MARK: - Presentation and Dismissal

    func show(in view: UIView) {
        view.addSubview(self)

        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        setupViews()
    }

    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmingView.alpha = 0 // Затемняющий фон исчезает
            self.containerView.alpha = 0 // Контейнер исчезает
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Сжимается
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localize(), style: .default, handler: nil))
        if let viewController = vc {
            viewController.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension AvatarPickerView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templateAvatarNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarTemplateCell.identifier, for: indexPath) as? AvatarTemplateCell else { return UICollectionViewCell() }
        let avatarName = templateAvatarNames[indexPath.item]
        let isAvailable = !avatarsAlreadyInUse.contains(avatarName)
        cell.configure(with: avatarName, isAvailable: isAvailable)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !avatarsAlreadyInUse.contains(templateAvatarNames[indexPath.item]) else {
            let alert = UIAlertController(title: "CreateYourGF.AvatarError.Title".localize(), message: "CreateYourGF.AvatarError.Message".localize(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localize(), style: .default, handler: nil))
            if let viewController = vc {
                viewController.present(alert, animated: true)
            }
            return
        }

        let selectedAvatarName = templateAvatarNames[indexPath.item]
        if let image = UIImage(named: selectedAvatarName) {
            onAvatarSelected?(image, selectedAvatarName)
            dismiss()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension AvatarPickerView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            if let image = info[.originalImage] as? UIImage {
                if let localImagePath = self?.saveImageToDocumentsDirectory(image: image) {
                    self?.onAvatarSelected?(image, localImagePath)
                    self?.dismiss()
                } else {
                    // Ошибка сохранения изображения
                    self?.showAlert(title: "Error".localize(), message: "CouldNotSaveImage".localize())
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Image Saving Helper
    
    private func saveImageToDocumentsDirectory(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename // Возвращаем только имя файла, так как путь к Documents всегда одинаков
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}
