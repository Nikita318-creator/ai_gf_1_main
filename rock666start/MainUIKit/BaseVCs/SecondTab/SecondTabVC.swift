//
//  SecondTabVC.swift
//  rock666start
//

import UIKit
import SnapKit

struct QuizTopic {
    let title: String
    let iconName: String
}

final class SecondTabVC: UIViewController {
    
    private let topics: [QuizTopic] = [
        QuizTopic(title: "Fashion Designer", iconName: "icon27"),
        QuizTopic(title: "Tattoo Artist", iconName: "icon1"),
        QuizTopic(title: "Indie Musician", iconName: "icon28"),
        QuizTopic(title: "Python Developer", iconName: "icon2"),
        QuizTopic(title: "Pastry Chef", iconName: "icon4"),
        QuizTopic(title: "Fitness Coach", iconName: "icon3"),
        QuizTopic(title: "Anime Illustrator", iconName: "icon11"),
        QuizTopic(title: "Pro eSports Gamer", iconName: "icon29"),
        QuizTopic(title: "Yoga & Mindfulness Guru", iconName: "icon30"),
        QuizTopic(title: "Cybersecurity Specialist", iconName: "icon12"),
        QuizTopic(title: "Manga Concept Artist", iconName: "icon31"),
        QuizTopic(title: "VTuber Streamer", iconName: "icon32"),
        QuizTopic(title: "Sommelier", iconName: "icon36"),
        QuizTopic(title: "Barista & Coffee Roaster", iconName: "icon34"),
        QuizTopic(title: "Art Historian", iconName: "icon35"),
        QuizTopic(title: "Sound Producer", iconName: "icon33")
    ]
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose a topic and play with AI"
        label.textColor = BasePalitColors.textSecondary
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(QuizTopicCell.self, forCellWithReuseIdentifier: QuizTopicCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        view.addSubview(headerLabel)
        view.addSubview(collectionView)
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "AI Coach & Quizzes"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = BasePalitColors.textPrimary
        titleLabel.sizeToFit()
        
        navigationItem.titleView = titleLabel
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BasePalitColors.background
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

extension SecondTabVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: QuizTopicCell.reuseIdentifier,
            for: indexPath
        ) as? QuizTopicCell else {
            return UICollectionViewCell()
        }
        
        let topic = topics[indexPath.row]
        cell.configure(with: topic)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 12
        let totalWidth = collectionView.bounds.width - padding
        let width = totalWidth / 2
        return CGSize(width: width, height: 130)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic = topics[indexPath.row]
        
        // Создаем вьюмодель и контроллер квиза
        let viewModel = QuizViewModel(topic: topic)
        let quizVC = QuizViewController(viewModel: viewModel)
        
        navigationController?.pushViewController(quizVC, animated: true)
    }
}
