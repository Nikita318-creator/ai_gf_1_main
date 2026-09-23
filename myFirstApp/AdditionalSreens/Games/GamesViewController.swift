import UIKit
import SnapKit
import MessageUI

enum GameType: String {
    case checkers = "1"
    case jigsaw = "2"
    case merge2048 = "3"
    case tictactoe = "4"
    case rockPaperScissors = "5"
    case reversi = "6"

    var controller: UIViewController {
        switch self {
        case .checkers:  return CheckersGameVC()
        case .jigsaw:    return JigsawGameVC()
        case .merge2048: return Merge2048GameVC()
        case .tictactoe: return TicTacToeGameVC()
        case .rockPaperScissors: return RockPaperScissorsGameVC()
        case .reversi: return ReversiGameVC()
        }
    }
}

enum GamesSection: Int, CaseIterable {
    case banner
    case games
    case storylines
    
    var title: String? {
        switch self {
        case .games: return "MiniGames".localize()
        case .storylines: return "TextAdventures".localize()
        default: return nil
        }
    }
}

class GamesViewController: UIViewController {
    
    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
    }

    private var collectionView: UICollectionView!
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()
    
    private let sections: [GamesSection] = [.banner, .games, .storylines]

    private let games: [GameModel] = [
        GameModel(id: "1", title: "mini.game.aigf.1".localize(), imageName: "checkersPteview"),
        GameModel(id: "2", title: "mini.game.aigf.2".localize(), imageName: "jigsawPreview"),
        GameModel(id: "3", title: "mini.game.aigf.3".localize(), imageName: "2048preview"),
        GameModel(id: "4", title: "mini.game.aigf.4".localize(), imageName: "tictacPreview"),
        GameModel(id: "5", title: "mini.game.aigf.5".localize(), imageName: "rockPaperPreview"),
        GameModel(id: "6", title: "mini.game.aigf.6".localize(), imageName: "reversiPreview")
    ]
    
    private let storylines: [StorylineModel] = [
        StorylineModel(id: "s1", title: "TextAdventuresTitle1".localize(), imageName: "novel1_1"),
        StorylineModel(id: "s2", title: "TextAdventuresTitle2".localize(), imageName: "novel2_1"),
        StorylineModel(id: "s3", title: "TextAdventuresTitle3".localize(), imageName: "novel3_1"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    private func setupUI() {
        view.backgroundColor = TelegramColors.background
        navigationController?.navigationBar.prefersLargeTitles = true
        setupCollectionView()
        collectionView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 50, right: 0)
        
        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(40)
        }
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(GameCell.self, forCellWithReuseIdentifier: GameCell.identifier)
        collectionView.register(StorylineCell.self, forCellWithReuseIdentifier: StorylineCell.identifier)
        
        // Supplementary views
        collectionView.register(BannerHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BannerHeaderView.identifier)
        collectionView.register(SectionTitleView.self, forSupplementaryViewOfKind: "SectionTitle", withReuseIdentifier: SectionTitleView.identifier)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let currentSection = self.sections[sectionIndex]
            
            // Настройка размеров групп
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            let groupHeight: NSCollectionLayoutDimension
            switch currentSection {
            case .banner: groupHeight = .absolute(0.01) // Почти нулевая высота для пустой секции
            case .games: groupHeight = .fractionalWidth(0.5 * 1.5)
            case .storylines: groupHeight = .fractionalWidth(0.6)
            }
                
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: groupHeight)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            
            // Убираем отступы для пустой баннерной секции
            section.contentInsets = (currentSection == .banner) ? .zero : NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 20, trailing: 8)
            
            var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
            
            // Добавляем Supplementary элементы
            switch currentSection {
            case .banner:
                let bannerWidth = layoutEnvironment.container.contentSize.width - 32
                let bannerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(bannerWidth / 2 + 16))
                let banner = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: bannerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                boundaryItems.append(banner)
                
            case .games, .storylines:
                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleSize, elementKind: "SectionTitle", alignment: .top)
                boundaryItems.append(titleHeader)
            }
            
            section.boundarySupplementaryItems = boundaryItems
            return section
        }
    }

    @objc private func bannerTapped() {
        let dressUpVC = DressUpVC()
        dressUpVC.modalPresentationStyle = .fullScreen
        present(dressUpVC, animated: true)
    }
    
    @objc private func didTapBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

extension GamesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let type = sections[section]
        switch type {
        case .banner: return 0
        case .games: return games.count
        case .storylines: return storylines.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let type = sections[indexPath.section]
        
        if type == .games {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.identifier, for: indexPath) as! GameCell
            cell.configure(with: games[indexPath.item])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StorylineCell.identifier, for: indexPath) as! StorylineCell
            cell.configure(with: storylines[indexPath.item])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let type = sections[indexPath.section]

        switch kind {
        case "SectionTitle":
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionTitleView.identifier, for: indexPath) as! SectionTitleView
            header.label.text = type.title
            return header
            
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BannerHeaderView.identifier, for: indexPath) as! BannerHeaderView
            header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bannerTapped)))
            return header
            
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
        case .games:
            let game = games[indexPath.item]
            guard let gameType = GameType(rawValue: game.id) else { return }
            
            AmplitudeManager.shared.logEvent(name: "Game selected", properties: ["id": game.id, "title": game.title])
            
            let vc = gameType.controller
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            
        case .storylines:
            let storyline = storylines[indexPath.item]
            
            AmplitudeManager.shared.logEvent(name: "Storyline selected", properties: ["id": "\(indexPath.item)", "title": storyline.title])
            
            let vc = StorylineVC(storyIndex: indexPath.item, title: storyline.title)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            
        case .banner:
            break
        }
    }
}
