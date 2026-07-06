import UIKit
import SnapKit
import YouTubeiOSPlayerHelper

class VideoCollectionViewCell: UICollectionViewCell {
    
    private var playerView: YTPlayerView?
    private let fullScreenPreviewImageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let sidePanelStackView = UIStackView()
    
    let profileImageView = UIImageView()
    private let likeButton = UIButton()
    private let shareButton = UIButton()
    private let commentButton = UIButton()

    private var isLiked = false
    private var currentVideoId: String?
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var onShareTapped: ((UIImage?) -> Void)?
    var onAuthorTapped: ((UIImage?) -> Void)?
    var onVideoFailedToLoad: (() -> Void)?
    var onCommentsTapped: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        contentView.clipsToBounds = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        fullScreenPreviewImageView.backgroundColor = .black
        fullScreenPreviewImageView.contentMode = .scaleAspectFill
        fullScreenPreviewImageView.clipsToBounds = true
        contentView.addSubview(fullScreenPreviewImageView)
        fullScreenPreviewImageView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
        
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        
        setupSidePanel()
    }
    
    private func createAndAddPlayerView() -> YTPlayerView {
        let player = YTPlayerView()
        player.backgroundColor = .black
        player.delegate = self
        player.alpha = 0
        player.webView?.scrollView.isScrollEnabled = false
        player.webView?.scrollView.bounces = false
        
        contentView.insertSubview(player, aboveSubview: fullScreenPreviewImageView)
        
        player.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(-150)
            make.bottom.equalToSuperview().offset(150)
        }
        return player
    }
    
    private func setupSidePanel() {
        sidePanelStackView.axis = .vertical
        sidePanelStackView.distribution = .equalSpacing
        sidePanelStackView.alignment = .center
        sidePanelStackView.spacing = 24
        
        profileImageView.snp.makeConstraints { $0.size.equalTo(44) }
        profileImageView.layer.cornerRadius = 22
        profileImageView.layer.borderWidth = 1.5
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .darkGray
        applyShadow(to: profileImageView)
        
        likeButton.snp.makeConstraints { $0.size.equalTo(40) }
        let likeConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: likeConfig), for: .normal)
        likeButton.tintColor = .white
        likeButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        applyShadow(to: likeButton)
        
        // --- КНОПКА КОММЕНТАРИЕВ ---
        commentButton.snp.makeConstraints { $0.size.equalTo(40) }
        let commentConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        commentButton.setImage(UIImage(systemName: "bubble.right.fill", withConfiguration: commentConfig), for: .normal)
        commentButton.tintColor = .white
        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        applyShadow(to: commentButton)
        
        shareButton.snp.makeConstraints { $0.size.equalTo(40) }
        let shareConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        shareButton.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: shareConfig), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        applyShadow(to: shareButton)
        
        profileImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        
        sidePanelStackView.addArrangedSubview(profileImageView)
        sidePanelStackView.addArrangedSubview(likeButton)
        sidePanelStackView.addArrangedSubview(commentButton) // Добавили в стек между лайком и шаром
        sidePanelStackView.addArrangedSubview(shareButton)
        
        contentView.addSubview(sidePanelStackView)
        sidePanelStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-120)
        }
    }
    
    private func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerView?.stopVideo()
        playerView?.removeFromSuperview()
        playerView = nil
        
        fullScreenPreviewImageView.image = nil
        fullScreenPreviewImageView.alpha = 1
        
        loadingIndicator.stopAnimating()
        
        isLiked = false
        currentVideoId = nil
        profileImageView.image = nil
        updateLikeButton(animated: false)
    }
    
    private func extractVideoId(from urlString: String) -> String? {
        guard !urlString.isEmpty else { return nil }
        if let range = urlString.range(of: "/shorts/") {
            let substring = urlString[range.upperBound...]
            return substring.components(separatedBy: "?").first
        }
        return nil
    }
    
    func configure(with urlString: String) {
        guard let videoId = extractVideoId(from: urlString) else { return }
        if currentVideoId == videoId { return }
        self.currentVideoId = videoId
        
        isLiked = UserDefaults.standard.bool(forKey: "liked_\(videoId)")
        updateLikeButton(animated: false)
        
        loadingIndicator.startAnimating()
        loadHighResPreviews(for: videoId)
        
        if playerView == nil {
            playerView = createAndAddPlayerView()
        }
        
        let playerVars: [String: Any] = [
            "controls": 0,
            "playsinline": 1,
            "autoplay": 0,
            "loop": 1,
            "playlist": videoId,
            "modestbranding": 1,
            "rel": 0
        ]
        
        playerView?.load(withVideoId: videoId, playerVars: playerVars)
    }
    
    private func loadHighResPreviews(for videoId: String) {
        guard let highResUrl = URL(string: "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg"),
              let fallbackUrl = URL(string: "https://img.youtube.com/vi/\(videoId)/0.jpg") else { return }
        
        URLSession.shared.dataTask(with: highResUrl) { [weak self] data, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.fullScreenPreviewImageView.image = image
                    self?.profileImageView.image = image
                }
            } else {
                URLSession.shared.dataTask(with: fallbackUrl) { [weak self] data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.fullScreenPreviewImageView.image = image
                            self?.profileImageView.image = image
                        }
                    }
                }.resume()
            }
        }.resume()
    }
    
    func playVideo() {
        playerView?.playVideo()
    }
    
    func pauseVideo() {
        playerView?.pauseVideo()
    }
    
    func stopVideo() {
        playerView?.stopVideo()
    }
    
    @objc private func toggleLike() {
        AnalyticService.shared.logEvent(name: "FeedVC onLikeTapped", properties: ["":""])
        
        guard let videoId = currentVideoId else { return }
        isLiked.toggle()
        
        if isLiked {
            UserDefaults.standard.set(true, forKey: "liked_\(videoId)")
        } else {
            UserDefaults.standard.removeObject(forKey: "liked_\(videoId)")
        }
        
        updateLikeButton(animated: true)
        
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    private func updateLikeButton(animated: Bool) {
        let targetColor = isLiked ? UIColor.systemPink : UIColor.white
        
        if animated {
            likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0.5,
                           options: .allowUserInteraction,
                           animations: {
                self.likeButton.transform = .identity
                self.likeButton.tintColor = targetColor
            }, completion: nil)
        } else {
            likeButton.transform = .identity
            likeButton.tintColor = targetColor
        }
    }
    
    @objc private func shareButtonTapped() {
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
        
        shareButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: .allowUserInteraction,
                       animations: {
            self.shareButton.transform = .identity
        }, completion: { [weak self] _ in
            self?.onShareTapped?(self?.profileImageView.image)
        })
    }
    
    @objc private func profileImageTapped() {
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
        
        profileImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: .allowUserInteraction,
                       animations: {
            self.profileImageView.transform = .identity
        }, completion: { [weak self] _ in
            self?.onAuthorTapped?(self?.profileImageView.image)
        })
    }

    @objc private func commentButtonTapped() {
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
        
        commentButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: .allowUserInteraction,
                       animations: {
            self.commentButton.transform = .identity
        }, completion: { [weak self] _ in
            guard let self = self, let videoId = self.currentVideoId else { return }
            self.onCommentsTapped?(videoId)
        })
    }
}

extension VideoCollectionViewCell: YTPlayerViewDelegate {
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        if state == .playing {
            self.loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.25) {
                playerView.alpha = 1
                self.fullScreenPreviewImageView.alpha = 0
            }
        }
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        print("🔴 YouTube Player Error: \(error.rawValue) for videoId: \(currentVideoId ?? "")")
        AnalyticService.shared.logEvent(
            name: "🔴 YouTube Player Error",
            properties: ["rawValue": "\(error.rawValue)", "for videoId": "\(currentVideoId ?? "")"]
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.onVideoFailedToLoad?()
        }
    }
}
