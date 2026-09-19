import UIKit
import SnapKit

class StoriesView: UIView {
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
        backgroundColor = MyColors.background
        
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
        let seenIDs = BaseManager.shared.viewedStoriesId
        
        stories = (1...10).map { index in
            let idString = "\(index)"
            let imageName = "mainAvatar\(index)"
            
            return StoryModel(
                id: idString,
                imageName: imageName,
                detailImageName: imageName,
                title: "character.name\(index)".localize(),
                description: "",
                isViewed: seenIDs.contains(idString)
            )
        }
        .shuffled()
        
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
