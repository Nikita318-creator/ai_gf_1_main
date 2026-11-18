//
//  BaseGridVC.swift
//  rock666start
//

import UIKit
import SnapKit

// MARK: - Game Model
struct GameItem {
    let title: String
    let iconName: String
}

final class BaseGridVC: UIViewController {

    // MARK: - Properties
    private var games: [GameItem] = []

    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ArcadeVerse"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = BasePalitColors.textPrimary
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a game and start playing"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = BasePalitColors.textSecondary
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.showsVerticalScrollIndicator = false
        cv.register(GameCell.self, forCellWithReuseIdentifier: GameCell.identifier)
        return cv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup Data
    private func setupData() {
        let gameTitles = [
            "Checkers", "2048", "Tic Tac Toe", "Jigsaw Puzzle",
            "Reversi", "Sudoku", "Memory Match", "Snake",
            "Mahjong", "Word Search",
        ]
        
        games = gameTitles.enumerated().map { index, title in
            let iconIndex = (index % 100) + 1
            return GameItem(title: title, iconName: "mainIcon\(iconIndex)")
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(collectionView)
    }

    // MARK: - Setup Constraints
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension BaseGridVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.identifier, for: indexPath) as? GameCell else {
            return UICollectionViewCell()
        }
        let game = games[indexPath.item]
        cell.configure(with: game)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Сетка в 2 столбца с учетом отступа между ними (16pt)
        let spacing: CGFloat = 16
        let totalWidth = collectionView.frame.width
        let itemWidth = (totalWidth - spacing) / 2
        // Высота карточки: квадратная превьюшка + отступы + текст
        return CGSize(width: itemWidth, height: itemWidth + 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedGame = games[indexPath.item]
        
        // Проверяем, что выбрали шашки (или открываем Game1VC напрямую)
        if selectedGame.title == "Checkers" {
            let gameVC = Game1VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "2048" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic Tac Toe" {
            let gameVC = Game3VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Jigsaw Puzzle" {
            let gameVC = Game4VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Reversi" {
            let gameVC = Game5VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Sudoku" {
            let gameVC = Game6VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Memory Match" {
            let gameVC = Game7VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Snake" {
            let gameVC = Game8VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Mahjong" {
            let gameVC = Game9VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Word Search" {
            let gameVC = Game10VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        } else if selectedGame.title == "Tic" {
            let gameVC = Game2VC()
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true, completion: nil)
        }
    }
}

// MARK: - GameCell
final class GameCell: UICollectionViewCell {
    static let identifier = "GameCell"

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.separator.cgColor
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = BasePalitColors.messageBackground
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = BasePalitColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(iconImageView.snp.width) // Делаем превью квадратным
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    func configure(with game: GameItem) {
        titleLabel.text = game.title
        iconImageView.image = UIImage(named: game.iconName) ?? UIImage(systemName: "gamecontroller.fill")
    }
}
