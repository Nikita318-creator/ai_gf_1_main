//
//  CommentTableViewCell.swift
//  ChatBot20
//
//  Created by Mikita on 06/07/2026.
//

import UIKit
import SnapKit

protocol CommentCellDelegate: AnyObject {
    func didTapLike(on comment: CommentModel)
    func didTapReply(on comment: CommentModel)
}

class CommentTableViewCell: UITableViewCell {
    
    weak var delegate: CommentCellDelegate?
    private var comment: CommentModel?
    
    private let avatarImageView = UIImageView()
    private let containerStack = UIStackView()
    
    private let nameLabel = UILabel()
    private let commentTextLabel = UILabel()
    private let actionsStack = UIStackView()
    private let replyButton = UIButton(type: .system)
    private let likesCountLabel = UILabel()
    
    private let likeButton = UIButton(type: .system)
    
    // Бейдж "Liked by author"
    private let authorLikeView = UIView()
    private let authorLikeAvatar = UIImageView()
    private let authorLikeIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .darkGray
        avatarImageView.tintColor = .lightGray
        
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .lightGray
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        contentView.addSubview(likeButton)
        likeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(20)
        }
        
        containerStack.axis = .vertical
        containerStack.spacing = 4
        contentView.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(likeButton.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        nameLabel.font = .systemFont(ofSize: 13, weight: .bold)
        nameLabel.textColor = .lightGray
        
        commentTextLabel.font = .systemFont(ofSize: 14)
        commentTextLabel.textColor = .white
        commentTextLabel.numberOfLines = 0
        
        actionsStack.axis = .horizontal
        actionsStack.spacing = 16
        actionsStack.alignment = .center
        
        replyButton.setTitle("Reply".localize(), for: .normal)
        replyButton.setTitleColor(.lightGray, for: .normal)
        replyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        replyButton.addTarget(self, action: #selector(replyTapped), for: .touchUpInside)
        
        likesCountLabel.font = .systemFont(ofSize: 12)
        likesCountLabel.textColor = .lightGray
        
        // Мини-бейджик лайка от автора
        setupAuthorLikeBadge()
        
        actionsStack.addArrangedSubview(likesCountLabel)
        actionsStack.addArrangedSubview(replyButton)
        actionsStack.addArrangedSubview(authorLikeView)
        actionsStack.addArrangedSubview(UIView()) // Спейсер
        
        containerStack.addArrangedSubview(nameLabel)
        containerStack.addArrangedSubview(commentTextLabel)
        containerStack.addArrangedSubview(actionsStack)
    }
    
    private func setupAuthorLikeBadge() {
        authorLikeAvatar.layer.cornerRadius = 8
        authorLikeAvatar.clipsToBounds = true
        authorLikeAvatar.contentMode = .scaleAspectFill
        authorLikeAvatar.backgroundColor = .darkGray
        
        authorLikeIcon.image = UIImage(systemName: "heart.fill")
        authorLikeIcon.tintColor = .systemPink
        authorLikeIcon.backgroundColor = .black
        authorLikeIcon.layer.cornerRadius = 5
        authorLikeIcon.clipsToBounds = true
        
        authorLikeView.addSubview(authorLikeAvatar)
        authorLikeView.addSubview(authorLikeIcon)
        
        authorLikeAvatar.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        authorLikeIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.bottom.equalTo(authorLikeAvatar.snp.bottom).offset(2)
            make.size.equalTo(10)
        }
        authorLikeView.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(18)
        }
    }
    
    func configure(with comment: CommentModel, isReply: Bool, authorAvatar: UIImage?) {
        self.comment = comment
        
        // Прячем кнопку «Ответить» для вложенных комментариев (второго уровня)
        replyButton.isHidden = isReply
        
        // Отступ для ответов (иерархия)
        avatarImageView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(isReply ? 52 : 16)
            make.size.equalTo(isReply ? 28 : 36)
        }
        avatarImageView.layer.cornerRadius = isReply ? 14 : 18
        
        // Аватарки
        if comment.isFromAIAuthor {
            nameLabel.text = "AuthorCreator".localize()
            nameLabel.textColor = .white
            avatarImageView.image = authorAvatar ?? UIImage(systemName: "person.circle.fill")
        } else {
            nameLabel.text = comment.isFromUser ? "You".localize() : comment.authorName
            nameLabel.textColor = .lightGray
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        commentTextLabel.text = comment.text
        
        // Лайк
        let heartImg = comment.isLikedByUser ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: heartImg), for: .normal)
        likeButton.tintColor = comment.isLikedByUser ? .systemPink : .lightGray
        likesCountLabel.text = comment.likesCount > 0 ? "\(comment.likesCount) likes" : ""
        likesCountLabel.isHidden = comment.likesCount == 0
        
        // Лайк от автора
        authorLikeView.isHidden = !comment.isLikedByAuthor || comment.isFromAIAuthor
        authorLikeAvatar.image = authorAvatar ?? UIImage(systemName: "person.circle.fill")
    }
    
    @objc private func likeTapped() {
        guard let comment = comment else { return }
        delegate?.didTapLike(on: comment)
    }
    
    @objc private func replyTapped() {
        guard let comment = comment else { return }
        delegate?.didTapReply(on: comment)
    }
}
