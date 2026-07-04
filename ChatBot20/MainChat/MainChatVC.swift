//
//  MainChatVC.swift
//  ChatBot20
//
//  Created by Mikita on 4.06.25.
//

import UIKit
import SnapKit

class MainChatVC: UIViewController {
    
    private let chatView = AIChatView()
    private let voiceChatView = AudioChat()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if MainHelper.shared.isVoiceChat {
            view.addSubview(voiceChatView)
            voiceChatView.vc = self
            voiceChatView.setup()
            voiceChatView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            view.addSubview(chatView)
            chatView.vc = self
            chatView.setup()
            chatView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if MainHelper.shared.isVoiceChat {
            voiceChatView.setMessagesFromDB()
            voiceChatView.setupNavTitleAndAvatar()
        } else {
            chatView.setMessagesFromDB()
            chatView.setupNavTitleAndAvatar()
        }
        
        if !NetworkMonitor.shared.isConnected {
            showInternetErrorAlert()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        chatView.updateForRLTIfNeeded()
    }
    
    func showInternetErrorAlert() {
        let alertController = UIAlertController(
            title: "InternetError.title".localize(),
            message: "InternetError.message".localize(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK".localize(), style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}
