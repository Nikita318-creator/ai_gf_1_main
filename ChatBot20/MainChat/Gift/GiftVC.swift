import UIKit
import SnapKit

// MARK: - GiftVC
class GiftVC: UIViewController {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let balanceView = UIView()
    private let coinIcon = UIImageView()
    private let balanceLabel = UILabel()
    private let collectionView: UICollectionView

    // MARK: - Properties
    private var userBalance: Int = CoinsService.shared.getCoins()

    // Mock data for the gift items
    private let giftItems: [GiftItem] = [
        GiftItem(imageName: "giftsIcon1", price: 5),
        GiftItem(imageName: "giftsIcon2", price: 5),
        GiftItem(imageName: "giftsIcon3", price: 5),
        GiftItem(imageName: "giftsIcon4", price: 5),
        GiftItem(imageName: "giftsIcon5", price: 5),
        
        GiftItem(imageName: "giftsIcon6", price: 10),
        GiftItem(imageName: "giftsIcon7", price: 10),
        GiftItem(imageName: "giftsIcon8", price: 10),
        GiftItem(imageName: "giftsIcon9", price: 10),
        GiftItem(imageName: "giftsIcon10", price: 10),
        
        GiftItem(imageName: "giftsIcon11", price: 15),
        GiftItem(imageName: "giftsIcon12", price: 15),
        GiftItem(imageName: "giftsIcon13", price: 15),
        GiftItem(imageName: "giftsIcon14", price: 15),
        GiftItem(imageName: "giftsIcon15", price: 15),
        
        GiftItem(imageName: "giftsIcon16", price: 20),
        GiftItem(imageName: "giftsIcon17", price: 20),
        GiftItem(imageName: "giftsIcon18", price: 20),
        GiftItem(imageName: "giftsIcon19", price: 20),
        GiftItem(imageName: "giftsIcon20", price: 20),
        
        GiftItem(imageName: "giftsIcon21", price: 25),
        GiftItem(imageName: "giftsIcon22", price: 25),
        GiftItem(imageName: "giftsIcon23", price: 25),
        GiftItem(imageName: "giftsIcon24", price: 25),
        GiftItem(imageName: "giftsIcon25", price: 25),
        
        GiftItem(imageName: "giftsIcon26", price: 30),
        GiftItem(imageName: "giftsIcon27", price: 30),
        GiftItem(imageName: "giftsIcon28", price: 30),
        GiftItem(imageName: "giftsIcon29", price: 30),
        GiftItem(imageName: "giftsIcon30", price: 30),
        
        GiftItem(imageName: "giftsIcon31", price: 35),
        GiftItem(imageName: "giftsIcon32", price: 35),
        GiftItem(imageName: "giftsIcon33", price: 35),
        GiftItem(imageName: "giftsIcon34", price: 35),
        GiftItem(imageName: "giftsIcon35", price: 35),
        
        GiftItem(imageName: "giftsIcon36", price: 40),
        GiftItem(imageName: "giftsIcon37", price: 40),
        GiftItem(imageName: "giftsIcon38", price: 40),
        GiftItem(imageName: "giftsIcon39", price: 40),
        GiftItem(imageName: "giftsIcon40", price: 40),
        
        GiftItem(imageName: "giftsIcon41", price: 45),
        GiftItem(imageName: "giftsIcon42", price: 45),
        GiftItem(imageName: "giftsIcon43", price: 45),
    ]

    var sendGiftHandler: ((GiftItem) -> Void)?
    
    // MARK: - Initializers

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateBalanceLabel()
        
        AnalyticService.shared.logEvent(name: "GiftVC shown", properties: ["":""])
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title and Subtitle
        titleLabel.text = "gift.title".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)

        subtitleLabel.text = "gift.subtitle".localize()
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)

        // Balance View (top right)
        balanceView.backgroundColor = .secondarySystemBackground
        balanceView.layer.cornerRadius = 15
        view.addSubview(balanceView)
        balanceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCoins)))
        
        coinIcon.image = UIImage(systemName: "circle.fill") // Placeholder for a coin icon
        coinIcon.tintColor = .systemYellow
        balanceView.addSubview(coinIcon)

        balanceLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        balanceLabel.textColor = .label
        balanceLabel.textAlignment = .center
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.5
        balanceView.addSubview(balanceLabel)

        // Close Button (top left)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GiftCell.self, forCellWithReuseIdentifier: GiftCell.reuseIdentifier)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        balanceView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(30)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    private func updateBalanceLabel() {
        balanceLabel.text = "\(userBalance)"
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func updateCoins() {
        userBalance = CoinsService.shared.getCoins()
        updateBalanceLabel()
    }
}

// MARK: - UICollectionViewDataSource
extension GiftVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return giftItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiftCell.reuseIdentifier, for: indexPath) as? GiftCell else {
            return UICollectionViewCell()
        }
        let gift = giftItems[indexPath.row]
        cell.configure(with: gift)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension GiftVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let collectionViewWidth = collectionView.bounds.width
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        let spaceBetweenCells = flowLayout?.minimumInteritemSpacing ?? 16
        let totalSpacing = spaceBetweenCells * (numberOfColumns - 1)
        let availableWidth = collectionViewWidth - totalSpacing
        let itemWidth = floor(availableWidth / numberOfColumns)
        if itemWidth <= 0 {
            return CGSize(width: 100, height: 120)
        }
        return CGSize(width: itemWidth, height: itemWidth * 1.2)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gift = giftItems[indexPath.row]
        
        AnalyticService.shared.logEvent(name: "GiftVC didSelectItemAt", properties: ["":"\(indexPath): \(gift)"])

        if userBalance >= gift.price {
            let alert = GiftConfirmAlert(gift: gift) { [weak self] in
                print("Gift sent! Price: \(gift.price)")
                if CoinsService.shared.spendCoins(gift.price) {
                    CoinsService.shared.addSentGift(gift.imageName, for: MainHelper.shared.currentAssistant?.id ?? "")
                    self?.userBalance -= gift.price
                    self?.updateBalanceLabel()
                    self?.sendGiftHandler?(gift)
                    
                    AnalyticService.shared.logEvent(name: "GiftVC gift sended", properties: ["gift sended":"Gift sent! Price: \(gift.price), userBalance = \(self?.userBalance ?? 0)"])
                }
            }
            alert.show(on: self)
        } else {
            AnalyticService.shared.logEvent(name: "Enough Coins alert", properties: ["":""])

            let alert = NotEnoughCoinsAlert()
            alert.okButtonTappedHandler = { [weak self] in
                self?.openCoins()
                alert.removeFromSuperview()
            }
            alert.show(on: self)
        }
    }
    
    @objc func openCoins() {
        AnalyticService.shared.logEvent(name: "GiftVC openCoins", properties: ["":""])

        let coinsView = CoinsView()
        coinsView.coinsAddedHandler = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.updateCoins()
            }
        }
        view.addSubview(coinsView)

        coinsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
