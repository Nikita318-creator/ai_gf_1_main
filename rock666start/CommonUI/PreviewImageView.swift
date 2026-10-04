import UIKit
import SnapKit
import Photos

class PreviewImageView: UIView {

    // MARK: - UI Components

    private let containerView = UIView()
    private let imageView = UIImageView()
    
    // Верхний бар с кнопками
    private let topBarContainer = UIView()
    private let closeButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)
    
    // Лейбл для уведомлений о статусе (Toast)
    private let statusToastView = UIView()
    private let statusLabel = UILabel()

    // Трансформации жестов
    private var currentScale: CGFloat = 1.0
    private var currentRotation: CGFloat = 0.0
    private var currentTranslation: CGPoint = .zero

    weak var vc: UIViewController?

    // MARK: - Initialization

    init(image: UIImage?) {
        super.init(frame: .zero)
        setupViews()
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Полноценный непрозрачный фон из темы
        backgroundColor = MyColors.background
        alpha = 0.0

        // Настройка ImageView на весь экран
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true

        // Контейнер для трансформаций
        containerView.isUserInteractionEnabled = true
        addSubview(containerView)
        containerView.addSubview(imageView)

        // Верхняя плашка/контейнер под кнопки в правом верхнем углу
        topBarContainer.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.85)
        topBarContainer.layer.cornerRadius = 20
        topBarContainer.layer.masksToBounds = true
        addSubview(topBarContainer)

        // Настройка кнопки скачивания (рядом с закрытием)
        downloadButton.setImage(
            UIImage(systemName: "square.and.arrow.down")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            ),
            for: .normal
        )
        downloadButton.tintColor = MyColors.textPrimary
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)

        // Настройка кнопки закрытия
        closeButton.setImage(
            UIImage(systemName: "xmark")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
            ),
            for: .normal
        )
        closeButton.tintColor = MyColors.textPrimary
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        topBarContainer.addSubview(downloadButton)
        topBarContainer.addSubview(closeButton)

        // Настройка Toast-уведомления статуса
        statusToastView.backgroundColor = MyColors.cardBackground
        statusToastView.layer.cornerRadius = 12
        statusToastView.layer.borderWidth = 1
        statusToastView.layer.borderColor = MyColors.separator.cgColor
        statusToastView.alpha = 0.0
        addSubview(statusToastView)

        statusLabel.textColor = MyColors.textPrimary
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusToastView.addSubview(statusLabel)

        // Подключение жестов (Pinch, Rotate, Pan, DoubleTap)
        setupGestures()

        // Констрейнты layout
        setupConstraints()
    }

    private func setupGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        pinch.delegate = self
        rotation.delegate = self
        pan.delegate = self

        containerView.addGestureRecognizer(pinch)
        containerView.addGestureRecognizer(rotation)
        containerView.addGestureRecognizer(pan)
        containerView.addGestureRecognizer(doubleTap)
    }

    private func setupConstraints() {
        // Контейнер и фоновое фото занимают весь экран
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Блок кнопок управления в правом верхнем углу
        topBarContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }

        downloadButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(downloadButton.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        // Всплывающий статус снизу экрана
        statusToastView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            make.height.equalTo(44)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Gesture Handlers (Pinch / Rotate / Move)

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            currentScale *= gesture.scale
            gesture.scale = 1.0
            updateTransform()
        case .ended, .cancelled:
            if currentScale < 1.0 {
                resetTransformAnimated()
            }
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .changed {
            currentRotation += gesture.rotation
            gesture.rotation = 0.0
            updateTransform()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation = gesture.translation(in: containerView)
            currentTranslation.x += translation.x
            currentTranslation.y += translation.y
            gesture.setTranslation(.zero, in: containerView)
            updateTransform()
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if currentScale != 1.0 || currentRotation != 0.0 || currentTranslation != .zero {
            resetTransformAnimated()
        } else {
            UIView.animate(withDuration: 0.3) {
                self.currentScale = 2.0
                self.updateTransform()
            }
        }
    }

    private func updateTransform() {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: currentTranslation.x, y: currentTranslation.y)
        transform = transform.rotated(by: currentRotation)
        transform = transform.scaledBy(x: currentScale, y: currentScale)
        containerView.transform = transform
    }

    private func resetTransformAnimated() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.currentScale = 1.0
            self.currentRotation = 0.0
            self.currentTranslation = .zero
            self.containerView.transform = .identity
        }
    }

    // MARK: - Actions & Save Flow

    @objc private func downloadButtonTapped() {
        guard let imageToSave = imageView.image else { return }
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            saveImage(imageToSave)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.saveImage(imageToSave)
                    } else {
                        self.showStatusMessage("galery.PermissionRejected".localize())
                    }
                }
            }
        case .denied, .restricted:
            showStatusMessage("galery.PermissionRejected".localize())
            showGaleryPermissionAlert()
        @unknown default:
            print("Unknown permission status.")
        }
    }

    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            showStatusMessage("galery.SaveError".localize())
        } else {
            showStatusMessage("galery.Saved".localize())
        }
    }

    private func showStatusMessage(_ message: String) {
        self.statusLabel.text = message
        
        // Плавный запуск отображения toast-уведомления
        UIView.animate(withDuration: 0.25) {
            self.statusToastView.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.8, options: [], animations: {
                self.statusToastView.alpha = 0.0
            })
        }
    }

    // MARK: - Public Methods (Сохраненная совместимость)

    func show(in parentView: UIView) {
        guard !BaseManager.shared.isImageOpened else { return }
        BaseManager.shared.isImageOpened = true

        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Плавный переход открывания полного экрана
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1.0
        }
    }

    @objc func dismiss() {
        BaseManager.shared.isImageOpened = false

        // Анимация затухания полноэкранного превью
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
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
}

// MARK: - UIGestureRecognizerDelegate

extension PreviewImageView: UIGestureRecognizerDelegate {
    // Разрешает одновременное выполнение зума, поворота и сдвига
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
