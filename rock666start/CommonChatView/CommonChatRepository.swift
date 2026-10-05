import UIKit

struct AIGFMessageModel {
    let role: String
    let content: String
    var isLoading: Bool = false
    var photoID: String = ""
    var isVoiceMessage: Bool = false
    var id: String?
    var reaction: String? = nil
}

enum AIMessageType: String {
    case typing = "typing..."
    case recordingAudio = "recording an audio..."
    case sendingPhoto = "sending a photo..."
    case recordingVideo = "recording a video..."
}

class CommonChatRepository {
    let messageService = AIGirlfriendMessagesManager()
    var messagesAI: [AIGFMessageModel] = []
    var onMessagesUpdated: ((Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onAudioMessagesUpdated: ((Bool) -> Void)?
    var systemPrompt: String?
    var previousMessages: String?

    private var messageIds: [Int: String] = [:]

    var currentMessagesAI: [AIGFMessageModel] {
        messageService.getAllMessages(forAssistantId: MyGovnoSingltone.shared.currentAssistant?.id ?? "")
    }
    
    func sendMessageViaCustomServer(_ text: String, isRegenerate: Bool = false, isAudioCall: Bool = false, isMessageFromTextChat: Bool = false, isNeedOnlyReply: Bool = false) {
        
        guard let assistantId = MyGovnoSingltone.shared.currentAssistant?.id else {
            print("No current assistant selected")
            onMessageReceived?() // важно - размораживаем кнопку сент в инпуте!
            onMessagesUpdated?(false)
            return
        }

        if !isRegenerate, !isNeedOnlyReply {
            DispatchQueue.main.async { [self] in
                let messageId = UUID().uuidString
                let userMessage = AIGFMessageModel(role: "user", content: text, id: messageId)
                messagesAI.append(userMessage)
                messageIds[messagesAI.count - 1] = UUID().uuidString
                if !isAudioCall {
                    messageService.addMessage(userMessage, assistantId: assistantId, messageId: messageId)
                }
                onMessagesUpdated?(true)
            }
        }
        
        messagesAI.removeAll(where: { $0.isLoading })
        onMessagesUpdated?(true)
        
        if !BackendService.shared.currentData.myMessageToUsers.isEmpty,
           isMessageFromTextChat,
           !isRegenerate,
           !isNeedOnlyReply {
            var sentMessages = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            let currentMessage = BackendService.shared.currentData.myMessageToUsers
            if !sentMessages.contains(currentMessage) {
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    await self.handleSuccessResponse(for: currentMessage, isAudioCall: isAudioCall)
                    self.onMessagesUpdated?(true)
                }
                
                sentMessages.append(currentMessage)
                UserDefaults.standard.set(sentMessages, forKey: "developerMessagesSent")
                return
            }
        }
        
        if (text.contains("Send me a photo"))
            && !isAudioCall {
            MyGovnoSingltone.shared.currentAIMessageType = .sendingPhoto
            addLoadingMessage()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.handleSuccessResponse(for: "[photo]", isAudioCall: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        if text.contains("Send me a clip")
            && MyGovnoSingltone.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == false
            && BackendService.shared.currentData.isABTestRandom {
            
            
            MyGovnoSingltone.shared.currentAIMessageType = .recordingVideo
            addLoadingMessage()
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.handleSuccessResponse(for: "[video]", isAudioCall: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        MyGovnoSingltone.shared.currentAIMessageType = MyGovnoSingltone.shared.isAudioMessagesMode ? .recordingAudio : .typing
        addLoadingMessage()
        
        
        let aiService = GeminiAPIService()
        var fullMessage = (systemPrompt ?? "") + (previousMessages ?? "") + "\n" + text

        func fetchWithRetry(attempt: Int) {
            aiService.fetchAIResponse(userMessage: fullMessage, systemPrompt: "") { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let responseText):
                    let cleanedText = responseText
                        .replacingOccurrences(of: "[video]", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    Task { @MainActor in
                        await self.handleSuccessResponse(for: cleanedText, isAudioCall: isAudioCall)
                    }
                    
                case .failure(let error):
                    
                    if attempt < 1 {
                        fullMessage = (systemPrompt ?? "") + "\n" + text
                        print("⚠️ Attempt 1 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 2 {
                        let safeHistory = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
                        fullMessage = (systemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 4 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 3 {
                        let safeHistory = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
                        fullMessage = (systemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 6 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else {
                        print("❌ Request failed after all retries.")
                        
                        // Check if error is rate limit (spam control)
                        let errorText: String
                        if case .rateLimitExceeded = error {
                            errorText = "Whoa, slow down there, handsome! 😘 I love talking to you, but I need a quick second to gather my thoughts. Hold on for me!"
                        } else {
                            errorText = "Oops! I got a little distracted thinking about you and missed what you said 💕 Can you repeat that for me, babe?"
                        }
                        
                        let errorMessage = AIGFMessageModel(role: "assistant", content: errorText)
                        
                        DispatchQueue.main.async {
                            if !self.messagesAI.isEmpty {
                                self.messagesAI[self.messagesAI.count - 1] = errorMessage
                                self.onAudioMessagesUpdated?(false)
                                self.onMessagesUpdated?(true)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.onMessageReceived?()
                            }
                        }
                    }
                }
            }
        }
        
        fetchWithRetry(attempt: 0)
    }
    
    private func handleSuccessResponse(for responseText: String, isAudioCall: Bool) async {
        var photoID: String = ""
        let avatar = MyGovnoSingltone.shared.currentAssistant?.avatarImageName ?? ""
        var testResponce: String?
        
        MyGovnoSingltone.shared.currentAIMessageType = .sendingPhoto
        
       if avatar.hasPrefix("mainAvatar"),
                  let numberString = avatar.components(separatedBy: "mainAvatar").last,
                  let avatarID = Int(numberString) {
            
            photoID = responseText.contains("[photo]")
            ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: avatarID)
            : ""
            
        } else if avatar.hasPrefix("MyGF"),
                  let firstDigitChar = avatar.dropFirst(4).first(where: { $0.isNumber }),
                  let avatarID = Int(String(firstDigitChar)) {
            
            photoID = responseText.contains("[photo]")
            ? await AdditionalRemotePhotoService.shared.getRandomPhoto(forMyGF: avatarID)
            : ""
        } else {
            if responseText.contains("[photo]") {
                photoID = await AdditionalRemotePhotoService.shared.getRandomPhotoFromAllPool(avatarID: avatar)
            } else {
                MyGovnoSingltone.shared.currentAIMessageType = .typing
                photoID = ""
            }
        }
        
        let messageId = UUID().uuidString
        
        if responseText.contains("[video]") {
            MyGovnoSingltone.shared.currentAIMessageType = .recordingVideo
            RemoteVideoService.shared.getVideoData(for: avatar) { [weak self] videoID in
                guard let self else { return }
                
                let aiMessage = AIGFMessageModel(role: "assistant", content: "[video]", photoID: videoID ?? "", id: messageId)
                messagesAI[messagesAI.count - 1] = aiMessage
                
                if !isAudioCall {
                    messageService.addMessage(aiMessage, assistantId: MyGovnoSingltone.shared.currentAssistant?.id ?? "", messageId: messageId)
                }
                onAudioMessagesUpdated?(true)
                onMessageReceived?()
                onMessagesUpdated?(true)
            }
            return
        }
        
        let isVoiceMessage = MyGovnoSingltone.shared.isAudioMessagesMode && !responseText.contains("[photo]")
        if isVoiceMessage {
            MyGovnoSingltone.shared.currentAIMessageType = .recordingAudio
        }
        
        let aiMessage = AIGFMessageModel(role: "assistant", content: testResponce ?? responseText, photoID: photoID, isVoiceMessage: isVoiceMessage, id: messageId)
        messagesAI[messagesAI.count - 1] = aiMessage
        
        if !isAudioCall {
            messageService.addMessage(aiMessage, assistantId: MyGovnoSingltone.shared.currentAssistant?.id ?? "", messageId: messageId)
        }
        onAudioMessagesUpdated?(true)
        onMessageReceived?()
        onMessagesUpdated?(true)
    }
    
    private func addLoadingMessage() {
        let loadingMessage = AIGFMessageModel(role: "assistant", content: "", isLoading: true)
        DispatchQueue.main.async { [self] in
            messagesAI.append(loadingMessage)
            messageIds[messagesAI.count - 1] = UUID().uuidString
            onMessagesUpdated?(true)
        }
    }
}
