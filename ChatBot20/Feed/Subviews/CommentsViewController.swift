//
//  CommentsViewController.swift
//  ChatBot20
//
//  Created by Mikita on 06/07/2026.
//

import UIKit
import SnapKit

class CommentsViewController: UIViewController {
    
    private let videoId: String
    private let authorAvatar: UIImage?
    private let feedVM = FeedVM()
    
    private var allComments: [CommentModel] = []
    private var flatDisplayList: [(comment: CommentModel, isReply: Bool, parentId: String?)] = []
    
    private var replyingToComment: CommentModel?
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Comments".localize()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        return tv
    }()
    
    private let containerInputView = UIView()
    private let replyBannerView = UIView()
    private let replyBannerLabel = UILabel()
    private let cancelReplyButton = UIButton(type: .system)
    
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    init(videoId: String, authorAvatar: UIImage?) {
        self.videoId = videoId
        self.authorAvatar = authorAvatar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        loadAndProcessComments()
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: - Работа с данными и отложенная реакция девушки (Правило 8)
    private func loadAndProcessComments() {
        let defaultsKey = "custom_comments_\(videoId)"
        let pendingUserCommentsKey = "pending_user_comments_\(videoId)"
        
        // 1. Загружаем сохраненные комментарии (моки или пользовательские)
        var savedComments: [CommentModel] = []
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([CommentModel].self, from: data) {
            savedComments = decoded
        } else {
            savedComments = feedVM.getMockComments(for: videoId)
        }
        
        // 2. Проверяем очередь ожидающих реакции комментариев
        if let pendingIds = UserDefaults.standard.stringArray(forKey: pendingUserCommentsKey), !pendingIds.isEmpty {
            
            for pendingId in pendingIds {
                // Сценарий А: Пользователь оставил ГЛАВНЫЙ комментарий
                if let idx = savedComments.firstIndex(where: { $0.id == pendingId }) {
                    // Вызываем для главного комментария (parentComment равен nil по умолчанию)
                    _ = applyGirlReaction(to: &savedComments[idx])
                }
                // Сценарий Б: Пользователь оставил ОТВЕТ (reply) под чужим комментарием
                else {
                    for i in 0..<savedComments.count {
                        if let rIdx = savedComments[i].replies.firstIndex(where: { $0.id == pendingId }) {
                            // Вызываем для вложенного ответа и обновляем родительский комментарий
                            if let updatedParent = applyGirlReaction(to: &savedComments[i].replies[rIdx], parentComment: savedComments[i]) {
                                savedComments[i] = updatedParent
                            }
                        }
                    }
                }
            }
            
            // Очищаем очередь, так как реакция применилась и теперь запишется в базу навсегда
            UserDefaults.standard.removeObject(forKey: pendingUserCommentsKey)
            saveToUserDefaults(comments: savedComments)
        }
        
        self.allComments = savedComments
        rebuildFlatList()
    }
    
    private func applyGirlReaction(to comment: inout CommentModel, parentComment: CommentModel? = nil) -> CommentModel? {
        let reaction = feedVM.generateGirlReactionForUserComment(videoId: videoId, userCommentId: comment.id)
        
        if reaction.authorLiked {
            comment.isLikedByAuthor = true
            comment.likesCount += 1
        }
        
        if let replyText = reaction.replyText {
            let aiReply = CommentModel(
                id: UUID().uuidString,
                videoId: videoId,
                authorName: "Author".localize(),
                text: replyText,
                isFromAIAuthor: true,
                isFromUser: false,
                likesCount: 1,
                isLikedByUser: false,
                isLikedByAuthor: false,
                replies: []
            )
            
            if var parent = parentComment {
                parent.replies.append(aiReply)
                return parent // Возвращаем измененного родителя
            } else {
                comment.replies.append(aiReply)
            }
        }
        
        return nil
    }
    
    private func saveToUserDefaults(comments: [CommentModel]) {
        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: "custom_comments_\(videoId)")
        }
    }
    
    private func rebuildFlatList() {
        flatDisplayList.removeAll()
        for comment in allComments {
            flatDisplayList.append((comment, false, nil))
            for reply in comment.replies {
                flatDisplayList.append((reply, true, comment.id))
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        view.addSubview(containerInputView)
        
        containerInputView.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        
        replyBannerView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        replyBannerView.isHidden = true
        replyBannerLabel.font = .systemFont(ofSize: 12)
        replyBannerLabel.textColor = .lightGray
        cancelReplyButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelReplyButton.tintColor = .lightGray
        cancelReplyButton.addTarget(self, action: #selector(cancelReplyTapped), for: .touchUpInside)
        
        replyBannerView.addSubview(replyBannerLabel)
        replyBannerView.addSubview(cancelReplyButton)
        containerInputView.addSubview(replyBannerView)
        
        containerInputView.addSubview(textField)
        containerInputView.addSubview(sendButton)
        
        textField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        textField.textColor = .white
        textField.layer.cornerRadius = 18
        textField.clipsToBounds = true
        textField.setLeftPaddingPoints(12)
        textField.attributedPlaceholder = NSAttributedString(string: "AddComment".localize(), attributes: [.foregroundColor: UIColor.lightGray])
        
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview()
        }
        
        containerInputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        replyBannerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0) // Изменится при реплае
        }
        replyBannerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        cancelReplyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        sendButton.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(replyBannerView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.size.equalTo(36)
        }

        textField.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-12)
            make.centerY.equalTo(sendButton)
            make.height.equalTo(36)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(containerInputView.snp.top)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newCommentId = UUID().uuidString
        let newComment = CommentModel(
            id: newCommentId,
            videoId: videoId,
            authorName: "You".localize(),
            text: text,
            isFromAIAuthor: false,
            isFromUser: true,
            likesCount: 0,
            isLikedByUser: false,
            isLikedByAuthor: false,
            replies: []
        )
        
        if let parent = replyingToComment {
            // Если parent сам является реплаем, ищем его корневого родителя в allComments,
            // чтобы не плодить вложенность в структуре данных.
            if let rootIdx = allComments.firstIndex(where: { $0.id == parent.id }) {
                allComments[rootIdx].replies.append(newComment)
            } else {
                // Если мы ответили на вложенный коммент, находим его родителя
                for i in 0..<allComments.count {
                    if allComments[i].replies.contains(where: { $0.id == parent.id }) {
                        allComments[i].replies.append(newComment)
                        break
                    }
                }
            }
        } else {
            allComments.append(newComment)
        }
        
        var pending = UserDefaults.standard.stringArray(forKey: "pending_user_comments_\(videoId)") ?? []
        pending.append(newCommentId)
        UserDefaults.standard.set(pending, forKey: "pending_user_comments_\(videoId)")
        
        saveToUserDefaults(comments: allComments)
        rebuildFlatList()
        
        textField.text = ""
        cancelReplyTapped()
        textField.resignFirstResponder()
        
        if !flatDisplayList.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: flatDisplayList.count - 1, section: 0), at: .bottom, animated: true)
        }
        AnalyticService.shared.logEvent(name: "Comment added", properties: ["videoId": videoId])
    }
    
    @objc private func cancelReplyTapped() {
        replyingToComment = nil
        replyBannerView.isHidden = true
        replyBannerView.snp.updateConstraints { make in make.height.equalTo(0) }
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            containerInputView.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-height + view.safeAreaInsets.bottom)
            }
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        containerInputView.snp.updateConstraints { make in make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom) }
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
}

// MARK: - TableView & Cell Delegate
extension CommentsViewController: UITableViewDataSource, UITableViewDelegate, CommentCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { flatDisplayList.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentTableViewCell else { return UITableViewCell() }
        let item = flatDisplayList[indexPath.row]
        cell.configure(with: item.comment, isReply: item.isReply, authorAvatar: authorAvatar)
        cell.delegate = self
        return cell
    }
    
    func didTapLike(on comment: CommentModel) {
        // Функция для рекурсивного обновления лайка
        func toggleLike(in list: inout [CommentModel]) {
            for i in 0..<list.count {
                if list[i].id == comment.id {
                    list[i].isLikedByUser.toggle()
                    list[i].likesCount += list[i].isLikedByUser ? 1 : -1
                    return
                }
                toggleLike(in: &list[i].replies)
            }
        }
        toggleLike(in: &allComments)
        saveToUserDefaults(comments: allComments)
        rebuildFlatList()
    }
    
    func didTapReply(on comment: CommentModel) {
        replyingToComment = comment
        replyBannerLabel.text = "\("ReplyingTo".localize()) \(comment.isFromUser ? ("You".localize()) : comment.authorName)..."
        replyBannerView.isHidden = false
        replyBannerView.snp.updateConstraints { make in make.height.equalTo(30) }
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        textField.becomeFirstResponder()
    }
}
