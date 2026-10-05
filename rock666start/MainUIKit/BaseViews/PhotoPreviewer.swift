import UIKit
import SnapKit
import Photos

class PhotoPreviewer: UIView {
    private let mainWrapperCanvasView = UIView()
    private let primaryDisplayImageView = UIImageView()
    private let headerControlOverlayView = UIView()
    private let exitActionButton = UIButton(type: .system)
    private let saveMediaActionButton = UIButton(type: .system)
    private let feedbackToastContainerView = UIView()
    private let feedbackMessageTextLabel = UILabel()
    private var activeZoomScaleFactor: CGFloat = 1.0
    private var activeRotationAngleVal: CGFloat = 0.0
    private var activeTranslationOffsetPoint: CGPoint = .zero

    weak var vc: UIViewController?

    init(image: UIImage?) {
        super.init(frame: .zero)
        configureViewHierarchyAndStyles()
        primaryDisplayImageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViewHierarchyAndStyles() {
        backgroundColor = BasePalitColors.background
        alpha = 0.0

        // Настройка ImageView на весь экран
        primaryDisplayImageView.contentMode = .scaleAspectFit
        primaryDisplayImageView.clipsToBounds = true
        primaryDisplayImageView.isUserInteractionEnabled = true

        mainWrapperCanvasView.isUserInteractionEnabled = true
        addSubview(mainWrapperCanvasView)
        mainWrapperCanvasView.addSubview(primaryDisplayImageView)

        headerControlOverlayView.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.85)
        headerControlOverlayView.layer.cornerRadius = 20
        headerControlOverlayView.layer.masksToBounds = true
        addSubview(headerControlOverlayView)

        saveMediaActionButton.setImage(
            UIImage(systemName: "square.and.arrow.down")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            ),
            for: .normal
        )
        saveMediaActionButton.tintColor = BasePalitColors.textPrimary
        saveMediaActionButton.addTarget(self, action: #selector(didTapSaveMediaButton), for: .touchUpInside)

        exitActionButton.setImage(
            UIImage(systemName: "xmark")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
            ),
            for: .normal
        )
        exitActionButton.tintColor = BasePalitColors.textPrimary
        exitActionButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        headerControlOverlayView.addSubview(saveMediaActionButton)
        headerControlOverlayView.addSubview(exitActionButton)

        feedbackToastContainerView.backgroundColor = BasePalitColors.cardBackground
        feedbackToastContainerView.layer.cornerRadius = 12
        feedbackToastContainerView.layer.borderWidth = 1
        feedbackToastContainerView.layer.borderColor = BasePalitColors.separator.cgColor
        feedbackToastContainerView.alpha = 0.0
        addSubview(feedbackToastContainerView)

        feedbackMessageTextLabel.textColor = BasePalitColors.textPrimary
        feedbackMessageTextLabel.font = .systemFont(ofSize: 14, weight: .medium)
        feedbackMessageTextLabel.textAlignment = .center
        feedbackToastContainerView.addSubview(feedbackMessageTextLabel)

        initializeInteractionGestureRecognizers()
        applyAutoLayoutConstraints()
    }

    private func initializeInteractionGestureRecognizers() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(processPinchGesture(_:)))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(processRotationGesture(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(processPanGesture(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(processDoubleTapGesture(_:)))
        doubleTap.numberOfTapsRequired = 2

        pinch.delegate = self
        rotation.delegate = self
        pan.delegate = self

        mainWrapperCanvasView.addGestureRecognizer(pinch)
        mainWrapperCanvasView.addGestureRecognizer(rotation)
        mainWrapperCanvasView.addGestureRecognizer(pan)
        mainWrapperCanvasView.addGestureRecognizer(doubleTap)
    }

    private func applyAutoLayoutConstraints() {
        mainWrapperCanvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        primaryDisplayImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerControlOverlayView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }

        saveMediaActionButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        exitActionButton.snp.makeConstraints { make in
            make.leading.equalTo(saveMediaActionButton.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        feedbackToastContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            make.height.equalTo(44)
        }

        feedbackMessageTextLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func processPinchGesture(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            activeZoomScaleFactor *= gesture.scale
            gesture.scale = 1.0
            recalculateCanvasTransform()
        case .ended, .cancelled:
            if activeZoomScaleFactor < 1.0 {
                resetCanvasTransformWithAnimation()
            }
        default:
            break
        }
    }

    @objc private func processRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .changed {
            activeRotationAngleVal += gesture.rotation
            gesture.rotation = 0.0
            recalculateCanvasTransform()
        }
    }

    @objc private func processPanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation = gesture.translation(in: mainWrapperCanvasView)
            activeTranslationOffsetPoint.x += translation.x
            activeTranslationOffsetPoint.y += translation.y
            gesture.setTranslation(.zero, in: mainWrapperCanvasView)
            recalculateCanvasTransform()
        }
    }

    @objc private func processDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        if activeZoomScaleFactor != 1.0 || activeRotationAngleVal != 0.0 || activeTranslationOffsetPoint != .zero {
            resetCanvasTransformWithAnimation()
        } else {
            UIView.animate(withDuration: 0.3) {
                self.activeZoomScaleFactor = 2.0
                self.recalculateCanvasTransform()
            }
        }
    }

    private func recalculateCanvasTransform() {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: activeTranslationOffsetPoint.x, y: activeTranslationOffsetPoint.y)
        transform = transform.rotated(by: activeRotationAngleVal)
        transform = transform.scaledBy(x: activeZoomScaleFactor, y: activeZoomScaleFactor)
        mainWrapperCanvasView.transform = transform
    }

    private func resetCanvasTransformWithAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.activeZoomScaleFactor = 1.0
            self.activeRotationAngleVal = 0.0
            self.activeTranslationOffsetPoint = .zero
            self.mainWrapperCanvasView.transform = .identity
        }
    }

    @objc private func didTapSaveMediaButton() {
        guard let imageToSave = primaryDisplayImageView.image else { return }
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            executeMediaSavingTask(imageToSave)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.executeMediaSavingTask(imageToSave)
                    } else {
                        self.displayToastNotificationMessage("Permission Rejected")
                    }
                }
            }
        case .denied, .restricted:
            displayToastNotificationMessage("Permission Rejected")
            presentPhotoLibraryAccessAlert()
        @unknown default:
            print("Unknown permission status.")
        }
    }

    private func executeMediaSavingTask(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(handleImageSavingResult(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func handleImageSavingResult(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            displayToastNotificationMessage("Error")
        } else {
            displayToastNotificationMessage("Saved")
        }
    }

    private func displayToastNotificationMessage(_ message: String) {
        self.feedbackMessageTextLabel.text = message
        
        UIView.animate(withDuration: 0.25) {
            self.feedbackToastContainerView.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.8, options: [], animations: {
                self.feedbackToastContainerView.alpha = 0.0
            })
        }
    }

    func show(in parentView: UIView) {
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        UIView.animate(withDuration: 0.25) {
            self.alpha = 1.0
        }
    }

    @objc func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    private func presentPhotoLibraryAccessAlert() {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "Please allow access to your Photo Library in Settings",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        })
        vc?.present(alert, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PhotoPreviewer: UIGestureRecognizerDelegate {
    // Разрешает одновременное выполнение зума, поворота и сдвига
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
