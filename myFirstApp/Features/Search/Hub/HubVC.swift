import UIKit
import SnapKit
import MessageUI

enum HubType: String {
    case DRAUGHTSGUIDE = "1"
    case PhotoPuzzle = "2"
    case NUMBERMERGE = "3"
    case NOUGHTSCROSSES = "4"
    case Roshambo = "5"
    case OTHELLOV = "6"

    var controller: UIViewController {
        switch self {
        case .DRAUGHTSGUIDE:  return DRAUGHTSGUIDEViewController()
        case .PhotoPuzzle:    return PhotoPuzzleViewController()
        case .NUMBERMERGE: return NUMBERMERGEViewController()
        case .NOUGHTSCROSSES: return NOUGHTSCROSSESViewController()
        case .Roshambo: return RoshamboViewController()
        case .OTHELLOV: return OTHELLOViewController()
        }
    }
}

enum HubSection: Int, CaseIterable {
    case topView
    case miniGames
    case novels
    
    var title: String? {
        switch self {
        case .miniGames: return "MiniGames".localize()
        case .novels: return "TextAdventures".localize()
        default: return nil
        }
    }
}

class HubVC: UIViewController {
    private var collectionView: UICollectionView!
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()
    
    private let sections: [HubSection] = [.topView, .miniGames, .novels]

    private let games: [HabMainDataModel] = [
        HabMainDataModel(id: "1", title: "mini.game.aigf.1".localize(), imageName: "checkersPteview"),
        HabMainDataModel(id: "2", title: "mini.game.aigf.2".localize(), imageName: "jigsawPreview"),
        HabMainDataModel(id: "3", title: "mini.game.aigf.3".localize(), imageName: "2048preview"),
        HabMainDataModel(id: "4", title: "mini.game.aigf.4".localize(), imageName: "tictacPreview"),
        HabMainDataModel(id: "5", title: "mini.game.aigf.5".localize(), imageName: "rockPaperPreview"),
        HabMainDataModel(id: "6", title: "mini.game.aigf.6".localize(), imageName: "reversiPreview")
    ]
    
    private let storylines: [ NovellModel] = [
         NovellModel(id: "s1", title: "TextAdventuresTitle1".localize(), imageName: "novel1_1"),
         NovellModel(id: "s2", title: "TextAdventuresTitle2".localize(), imageName: "novel2_1"),
         NovellModel(id: "s3", title: "TextAdventuresTitle3".localize(), imageName: "novel3_1"),
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
        view.backgroundColor = MyColors.background
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
        
        collectionView.register(HabMainCell.self, forCellWithReuseIdentifier: HabMainCell.identifier)
        collectionView.register( NovellCell.self, forCellWithReuseIdentifier:  NovellCell.identifier)
        
        // Supplementary views
        collectionView.register(HabTopView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HabTopView.identifier)
        collectionView.register(NovellSectionTitleView.self, forSupplementaryViewOfKind: "SectionTitle", withReuseIdentifier: NovellSectionTitleView.identifier)
        
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
            case .topView: groupHeight = .absolute(0.01) // Почти нулевая высота для пустой секции
            case .miniGames: groupHeight = .fractionalWidth(0.5 * 1.5)
            case .novels: groupHeight = .fractionalWidth(0.6)
            }
                
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: groupHeight)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            
            // Убираем отступы для пустой баннерной секции
            section.contentInsets = (currentSection == .topView) ? .zero : NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 20, trailing: 8)
            
            var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
            
            // Добавляем Supplementary элементы
            switch currentSection {
            case .topView:
                let bannerWidth = layoutEnvironment.container.contentSize.width - 32
                let bannerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(bannerWidth / 2 + 16))
                let banner = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: bannerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                boundaryItems.append(banner)
                
            case .miniGames, .novels:
                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleSize, elementKind: "SectionTitle", alignment: .top)
                boundaryItems.append(titleHeader)
            }
            
            section.boundarySupplementaryItems = boundaryItems
            return section
        }
    }

    @objc private func bannerTapped() {
        let dressUpVC = OutfitViewController()
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

extension HubVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let type = sections[section]
        switch type {
        case .topView: return 0
        case .miniGames: return games.count
        case .novels: return storylines.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let type = sections[indexPath.section]
        
        if type == .miniGames {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HabMainCell.identifier, for: indexPath) as! HabMainCell
            cell.configure(with: games[indexPath.item])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  NovellCell.identifier, for: indexPath) as!  NovellCell
            cell.configure(with: storylines[indexPath.item])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let type = sections[indexPath.section]

        switch kind {
        case "SectionTitle":
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NovellSectionTitleView.identifier, for: indexPath) as! NovellSectionTitleView
            header.label.text = type.title
            return header
            
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HabTopView.identifier, for: indexPath) as! HabTopView
            header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bannerTapped)))
            return header
            
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
        case .miniGames:
            let game = games[indexPath.item]
            guard let gameType = HubType(rawValue: game.id) else { return }
            
            AmplitudeManager.shared.logEvent(name: "Game selected", properties: ["id": game.id, "title": game.title])
            
            let vc = gameType.controller
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            
        case .novels:
            let storyline = storylines[indexPath.item]
            
            AmplitudeManager.shared.logEvent(name: "Storyline selected", properties: ["id": "\(indexPath.item)", "title": storyline.title])
            
            let vc = NovellViewController(storyIndex: indexPath.item, title: storyline.title)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            
        case .topView:
            break
        }
    }
}
