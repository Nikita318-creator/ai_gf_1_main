import UIKit
import AVFoundation
import AVKit

class AIGFMediaChatCell: AIGFChatCell {

    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let blurryOverlayView: PhotoBlureOverlay = {
        let view = PhotoBlureOverlay()
        view.isHidden = true
        view.isUserInteractionEnabled = true
        return view
    }()

    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = BasePalitColors.textPrimary
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold, scale: .large)
        imageView.image = UIImage(systemName: "play.circle.fill")?.withConfiguration(config)
        imageView.isHidden = true
        return imageView
    }()

    private var isVideoCell = false
    private var videoID: String?
    private var loopingPlayerManager: LoopingPlayerManager?

    var currentImage: UIImage? {
        return messageImageView.image
    }

    override func setupSubviews() {
        messageContainerView.addSubview(messageImageView)
        messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(messageImageTapped)))

        messageImageView.addSubview(playIconImageView)
        messageImageView.bringSubviewToFront(playIconImageView)
        messageImageView.addSubview(blurryOverlayView)

        blurryOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            let iconSize: CGFloat = isIPad() ? 80 : 60
            make.width.height.equalTo(iconSize)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView.image = nil
        playIconImageView.isHidden = true
        blurryOverlayView.isHidden = true
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, id: String, reaction: String?) {
        self.messageID = id
        self.isVideoCell = message.contains("[video]")

        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)

        playIconImageView.isHidden = true

        if !isUserMessage && !SubscriptionManager.shared.hasActiveSubscription {
            blurryOverlayView.isHidden = false
        } else {
            blurryOverlayView.isHidden = true
        }

        if message.contains("[video]") {
            videoID = photoID
            playIconImageView.isHidden = false
            if let thumbnailData = RemoteRealmVideoService.shared.getThumbnailData(name: photoID) {
                self.messageImageView.image = UIImage(data: thumbnailData)
            }
        } else if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("mainAvatar") == true && !isUserMessage {
            if photoID.contains("firstFoto") {
                messageImageView.image = (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
            } else {
                messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
            }
        } else if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("MyGF") == true && !isUserMessage {
            messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
        } else {
            messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? UIImage(named: photoID) ?? (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? ("firstFoto_") : "firstFoto"))
        }

        if isUserMessage {
            configureUserMessageForImage()
        } else {
            configureAssistantMessageForImage()
        }
    }

    private func configureUserMessageForImage() {
        let smallerSide = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let photoSize: CGFloat = isIPad() ? smallerSide / 2 : 200

        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }

        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }

    private func configureAssistantMessageForImage() {
        let smallerSide = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let photoSize: CGFloat = isIPad() ? smallerSide / 2 : 200
        let avatarViewSize: CGFloat = isIPad() ? 52 : 36

        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = BasePalitColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }

        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }

    @objc private func messageImageTapped() {
        guard let vc = vc else { return }
        hideKeyboardHandler?()

        guard SubscriptionManager.shared.hasActiveSubscription else {
            showSubsHandler?()
            return
        }

        if isVideoCell {
            guard let player = makePlayer(from: videoID ?? "") else { return }

            let audioManager = LoopingAudioManager()
            self.loopingPlayerManager = LoopingPlayerManager(player: player, audioManager: audioManager)

            let playerVC = HardcorePlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            playerVC.delegate = self
            player.isMuted = true

            vc.present(playerVC, animated: true) { player.play() }
        } else if let messageImage = messageImageView.image {
            let fullScreenView = PhotoPreviewer(image: messageImage)
            fullScreenView.vc = vc
            fullScreenView.show(in: vc.view)
        }
    }

    private func makePlayer(from videoName: String) -> AVPlayer? {
        guard let localURL = RemoteRealmVideoService.shared.getVideoLocalURL(name: videoName) else {
            print("⚠️ Видео \(videoName) не найдено в кэше или было удалено системой.")
            return nil
        }
        return AVPlayer(url: localURL)
    }

    override func iPadCheck() {
        super.iPadCheck()
        guard isIPad() else { return }
        messageImageView.layer.cornerRadius = 22
    }
}

extension AIGFMediaChatCell: AVPlayerViewControllerDelegate {
    func playerViewControllerWillDisappear(_ playerViewController: AVPlayerViewController) {
        playerViewController.player?.pause()
        if let manager = self.loopingPlayerManager {
            manager.player.removeObserver(manager, forKeyPath: "rate")
        }
        self.loopingPlayerManager = nil
    }
}
