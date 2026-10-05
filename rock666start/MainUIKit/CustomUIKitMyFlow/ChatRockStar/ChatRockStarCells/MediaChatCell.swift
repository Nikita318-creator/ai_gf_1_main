import UIKit
import AVFoundation
import AVKit

class MediaChatCell: AbstractChatCell {

    private let contentDisplayImageView: UIImageView = {
        let visualContainerView = UIImageView()
        visualContainerView.contentMode = .scaleAspectFill
        visualContainerView.clipsToBounds = true
        visualContainerView.layer.cornerRadius = 12
        visualContainerView.isUserInteractionEnabled = true
        return visualContainerView
    }()

    private let contentBlurOverlayView: PhotoBlureOverlay = {
        let blurWrapperView = PhotoBlureOverlay()
        blurWrapperView.isHidden = true
        blurWrapperView.isUserInteractionEnabled = true
        return blurWrapperView
    }()

    private let playbackControlImageView: UIImageView = {
        let actionIconImageView = UIImageView()
        actionIconImageView.contentMode = .scaleAspectFit
        actionIconImageView.tintColor = BasePalitColors.textPrimary
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold, scale: .large)
        actionIconImageView.image = UIImage(systemName: "play.circle.fill")?.withConfiguration(symbolConfiguration)
        actionIconImageView.isHidden = true
        return actionIconImageView
    }()

    private var hasActiveVideoContent = false
    private var mediaItemIdentifier: String?
    private var videoPlaybackSessionManager: MusicVideoReppitter?

    var currentImage: UIImage? {
        return contentDisplayImageView.image
    }

    override func setupSubviews() {
        bobleView.addSubview(contentDisplayImageView)
        contentDisplayImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMediaItemTap)))

        contentDisplayImageView.addSubview(playbackControlImageView)
        contentDisplayImageView.bringSubviewToFront(playbackControlImageView)
        contentDisplayImageView.addSubview(contentBlurOverlayView)

        contentBlurOverlayView.snp.makeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.edges.equalToSuperview()
        }

        playbackControlImageView.snp.makeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.center.equalToSuperview()
            let calculatedIconMetric: CGFloat = isIPad() ? 80 : 60
            layoutConstraintsMaker.width.height.equalTo(calculatedIconMetric)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentDisplayImageView.image = nil
        playbackControlImageView.isHidden = true
        contentBlurOverlayView.isHidden = true
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, id: String, reaction: String?) {
        self.currentMessageID = id
        self.hasActiveVideoContent = message.contains("[video]")

        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)

        playbackControlImageView.isHidden = true

        if !isUserMessage && !SubscriptionManager.shared.hasActiveSubscription {
            contentBlurOverlayView.isHidden = false
        } else {
            contentBlurOverlayView.isHidden = true
        }

        if message.contains("[video]") {
            mediaItemIdentifier = photoID
            playbackControlImageView.isHidden = false
            if let cachedThumbnailData = RemoteRealmVideoService.shared.getThumbnailData(name: photoID) {
                self.contentDisplayImageView.image = UIImage(data: cachedThumbnailData)
            }
        } else if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("mainAvatar") == true && !isUserMessage {
            if photoID.contains("firstFoto") {
                contentDisplayImageView.image = (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
            } else {
                contentDisplayImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
            }
        } else if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("MyGF") == true && !isUserMessage {
            contentDisplayImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
        } else {
            contentDisplayImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? UIImage(named: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
        }

        if isUserMessage {
            applyOutgoingImageLayout()
        } else {
            applyIncomingImageLayout()
        }
    }

    private func applyOutgoingImageLayout() {
        let minimalDeviceDimension = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let calculatedPhotoDimension: CGFloat = isIPad() ? minimalDeviceDimension / 2 : 200

        bobleView.snp.remakeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.top.equalToSuperview().inset(4)
            layoutConstraintsMaker.bottom.equalToSuperview().inset(4)
            layoutConstraintsMaker.trailing.equalToSuperview().inset(16)
            layoutConstraintsMaker.leading.greaterThanOrEqualToSuperview().inset(80)
            layoutConstraintsMaker.width.equalTo(calculatedPhotoDimension)
            layoutConstraintsMaker.height.equalTo(calculatedPhotoDimension)
        }

        contentDisplayImageView.snp.remakeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.edges.equalToSuperview().inset(4)
        }
    }

    private func applyIncomingImageLayout() {
        let minimalDeviceDimension = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let calculatedPhotoDimension: CGFloat = isIPad() ? minimalDeviceDimension / 2 : 250
        let calculatedAvatarDimension: CGFloat = isIPad() ? 52 : 36

        authorImageView.snp.remakeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.leading.equalToSuperview().inset(16)
            layoutConstraintsMaker.bottom.equalToSuperview().inset(4)
            layoutConstraintsMaker.width.height.equalTo(calculatedAvatarDimension)
        }

        bobleView.backgroundColor = BasePalitColors.assistantMessageBackground
        bobleView.snp.remakeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.top.equalToSuperview().inset(4)
            layoutConstraintsMaker.bottom.equalToSuperview().inset(4)
            layoutConstraintsMaker.leading.equalTo(authorImageView.snp.trailing).offset(8)
            layoutConstraintsMaker.trailing.lessThanOrEqualToSuperview().inset(80)
            layoutConstraintsMaker.width.equalTo(calculatedPhotoDimension)
            layoutConstraintsMaker.height.equalTo(calculatedPhotoDimension + (calculatedPhotoDimension / 2))
        }

        contentDisplayImageView.snp.remakeConstraints { layoutConstraintsMaker in
            layoutConstraintsMaker.edges.equalToSuperview().inset(4)
        }
    }

    @objc private func handleMediaItemTap() {
        guard let presentingViewController = vc else { return }
        hideKeyboardHandler?()

        guard SubscriptionManager.shared.hasActiveSubscription else {
            openPaywallHandler?()
            return
        }

        if hasActiveVideoContent {
            guard let activePlayerInstance = instantiateVideoPlayer(using: mediaItemIdentifier ?? "") else { return }

            let customAudioSessionManager = VoiceVideoCellReppitter()
            self.videoPlaybackSessionManager = MusicVideoReppitter(player: activePlayerInstance, audioManager: customAudioSessionManager)

            let customPlayerViewController = HardcorePlayerViewController()
            customPlayerViewController.player = activePlayerInstance
            customPlayerViewController.modalPresentationStyle = .fullScreen
            customPlayerViewController.delegate = self
            activePlayerInstance.isMuted = true

            presentingViewController.present(customPlayerViewController, animated: true) { activePlayerInstance.play() }
        } else if let displayedPreviewImage = contentDisplayImageView.image {
            let fullscreenPreviewContainer = PhotoPreviewer(image: displayedPreviewImage)
            fullscreenPreviewContainer.vc = presentingViewController
            fullscreenPreviewContainer.show(in: presentingViewController.view)
        }
    }

    private func instantiateVideoPlayer(using targetResourceName: String) -> AVPlayer? {
        guard let targetMediaFilePathURL = RemoteRealmVideoService.shared.getVideoLocalURL(name: targetResourceName) else {
            return nil
        }
        return AVPlayer(url: targetMediaFilePathURL)
    }

    override func iPadCheck() {
        super.iPadCheck()
        guard isIPad() else { return }
        contentDisplayImageView.layer.cornerRadius = 22
    }
}

extension MediaChatCell: AVPlayerViewControllerDelegate {
    func playerViewControllerWillDisappear(_ playerViewController: AVPlayerViewController) {
        playerViewController.player?.pause()
        if let activeSessionManager = self.videoPlaybackSessionManager {
            activeSessionManager.player.removeObserver(activeSessionManager, forKeyPath: "rate")
        }
        self.videoPlaybackSessionManager = nil
    }
}
