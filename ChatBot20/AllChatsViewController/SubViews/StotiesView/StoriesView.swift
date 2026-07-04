import UIKit
import SnapKit

class StoriesView: UIView {
    // Telegram цвета (скопированы для независимости, но лучше использовать общий файл)
    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
    }

    private var collectionView: UICollectionView?
    var stories: [StoryModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    var onStoryTapped: ((StoryModel) -> Void)?
    var currentStoryIndex = 0
    var textForStoriesGeneratedCount: Int = 0
    
    var storiesTexts: [String] {
        (1...420).map { index in
            "stories.text\(index)".localize()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnStoriesOnMode),
            name: .modUpdated,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateForRLTIfNeeded() {
        guard let collectionView else { return }
        let rightOffset = CGPoint(x: collectionView.contentSize.width - collectionView.bounds.width + collectionView.contentInset.right, y: 0)
        collectionView.setContentOffset(rightOffset, animated: false)
    }
    
    private func setup() {
        backgroundColor = TelegramColors.background
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let layoutItemSize = isCurrentDeviceiPad() ? CGSize(width: 106, height: 122) : CGSize(width: 70, height: 90)
        layout.itemSize = layoutItemSize // Ширина для кружка + имени
        layout.minimumLineSpacing = 8 // Минимальный отступ между ячейками
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // Отступы секции

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.backgroundColor = .clear // Прозрачный фон для коллекции
        collectionView?.showsHorizontalScrollIndicator = false // Скрыть индикатор прокрутки
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.register(StoryCell.self, forCellWithReuseIdentifier: StoryCell.identifier)
        
        if let collectionView {
            addSubview(collectionView)
        }
        
        collectionView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setupMockStories() {
        let seenIDs = MainHelper.shared.viewedStoriesId
        
        if GEOService.shared.isAsionGeo {
            stories = [
                StoryModel(id: "asion41", imageName: "asion41", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend1".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion41")),
                StoryModel(id: "asion54", imageName: "asion54", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend2".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion54")),
                StoryModel(id: "asion58", imageName: "asion58", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend3".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion58")),
                StoryModel(id: "4", imageName: "4", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend4".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("4")),
                StoryModel(id: "5", imageName: "5", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend5".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("5")),
                StoryModel(id: "6", imageName: "6", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend6".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("6")),
                StoryModel(id: "7", imageName: "7", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend7".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("7")),
                StoryModel(id: "8", imageName: "8", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend8".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("8")),
                StoryModel(id: "latina3", imageName: "latina3", detailImageName: MainHelper.shared.picLatinaIDs.randomElement() ?? "", title: "Template.Girlfriend16".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("latina3")),
                StoryModel(id: "asion37", imageName: "asion37", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend10".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion37")),
                StoryModel(id: "arab6", imageName: "arab6", detailImageName: MainHelper.shared.picArabIDs.randomElement() ?? "", title: "Template.Girlfriend22".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("arab6")),
                StoryModel(id: "ind6", imageName: "ind6", detailImageName: MainHelper.shared.picIndIDs.randomElement() ?? "", title: "Template.Girlfriend21".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("ind6")),
                StoryModel(id: "latina16", imageName: "latina16", detailImageName: MainHelper.shared.picLatinaIDs.randomElement() ?? "", title: "Template.Girlfriend20".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("latina16")),
                StoryModel(id: "asion27", imageName: "asion27", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend19".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion27")),
                StoryModel(id: "arab1", imageName: "arab1", detailImageName: MainHelper.shared.picArabIDs.randomElement() ?? "", title: "Template.Girlfriend18".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("arab1")),
                StoryModel(id: "ind1", imageName: "ind1", detailImageName: MainHelper.shared.picIndIDs.randomElement() ?? "", title: "Template.Girlfriend17".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("ind1")),
                StoryModel(id: "asion29", imageName: "asion29", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend15".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion29")),
            ].shuffled()
        } else {
            stories = [
                StoryModel(id: "1", imageName: MainHelper.shared.isMode ? "pic109" : "1", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend1".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("1")),
                StoryModel(id: "2", imageName: "2", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend2".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("2")),
                StoryModel(id: "3", imageName: "3", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend3".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("3")),
                StoryModel(id: "4", imageName: "4", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend4".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("4")),
                StoryModel(id: "5", imageName: MainHelper.shared.isMode ? "photo113" : "5", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend5".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("5")),
                StoryModel(id: "6", imageName: MainHelper.shared.isMode ? "photo57" : "6", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend6".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("6")),
                StoryModel(id: "7", imageName: "7", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend7".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("7")),
                StoryModel(id: "8", imageName: "8", detailImageName: MainHelper.shared.picIBrunetdDs.randomElement() ?? "", title: "Template.Girlfriend8".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("8")),
                StoryModel(id: "latina3", imageName: "latina3", detailImageName: MainHelper.shared.picLatinaIDs.randomElement() ?? "", title: "Template.Girlfriend16".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("latina3")),
                StoryModel(id: "10", imageName: "10", detailImageName: MainHelper.shared.picIBlondDs.randomElement() ?? "", title: "Template.Girlfriend10".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("10")),
                StoryModel(id: "arab6", imageName: "arab6", detailImageName: MainHelper.shared.picArabIDs.randomElement() ?? "", title: "Template.Girlfriend22".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("arab6")),
                StoryModel(id: "ind6", imageName: "ind6", detailImageName: MainHelper.shared.picIndIDs.randomElement() ?? "", title: "Template.Girlfriend21".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("ind6")),
                StoryModel(id: "latina16", imageName: MainHelper.shared.isMode ? "latina11" : "latina16", detailImageName: MainHelper.shared.picLatinaIDs.randomElement() ?? "", title: "Template.Girlfriend20".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("latina16")),
                StoryModel(id: "asion27", imageName: "asion27", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend19".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion27")),
                StoryModel(id: "arab1", imageName: "arab1", detailImageName: MainHelper.shared.picArabIDs.randomElement() ?? "", title: "Template.Girlfriend18".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("arab1")),
                StoryModel(id: "ind1", imageName: MainHelper.shared.isMode ? "ind5" : "ind1", detailImageName: MainHelper.shared.picIndIDs.randomElement() ?? "", title: "Template.Girlfriend17".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("ind1")),
                StoryModel(id: "asion29", imageName: "asion29", detailImageName: MainHelper.shared.picAsionIDs.randomElement() ?? "", title: "Template.Girlfriend15".localize(), description: storiesTexts.randomElement() ?? "", isViewed: seenIDs.contains("asion29")),
            ].shuffled()
        }
        stories.sort { !$0.isViewed && $1.isViewed }
    }
    
    @objc private func updateOnStoriesOnMode() {
        setupMockStories()
        collectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension StoriesView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoryCell.identifier, for: indexPath) as? StoryCell else { return UICollectionViewCell() }
        let story = stories[indexPath.item]
        cell.configure(with: story)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StoriesView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Устанавливаем, что сторис просмотрена
        stories[indexPath.item].isViewed = true
        collectionView.reloadItems(at: [indexPath]) // Обновить только эту ячейку
        currentStoryIndex = indexPath.item
        onStoryTapped?(stories[indexPath.item])
    }
}
