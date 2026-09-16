import UIKit

struct Message {
    let role: String
    let content: String
    var isLoading: Bool = false
    var photoID: String = ""
    var isVoiceMessage: Bool = false
    var id: String?
    var reaction: String? = nil
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

struct GoogleAPIError: Codable {
    struct ErrorDetails: Codable {
        let code: Int
        let message: String
        let status: String
    }
    let error: ErrorDetails
}

enum AIMessageType: String {
    case typing = "AIMessageType.typing"
    case recordingAudio = "AIMessageType.recordingAudio"
    case sendingPhoto = "AIMessageType.sendingPhoto"
    case recordingVideo = "AIMessageType.recordingVideo"
}

class AIChatViewModel {
    let messageService = MessageHistoryService()
    var messagesAI: [Message] = []
    var onMessagesUpdated: ((Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onAudioMessagesUpdated: ((Bool) -> Void)?
    var systemPrompt: String?
    var safeSystemPrompt: String?
    var previousMessages: String?

    private var messageIds: [Int: String] = [:]

    var currentMessagesAI: [Message] {
        messageService.getAllMessages(forAssistantId: MainHelper.shared.currentAssistant?.id ?? "")
    }
    
    func sendMessageViaCustomServer(_ text: String, isRegenerate: Bool = false, isAudioCall: Bool = false, isMessageFromTextChat: Bool = false, isNeedOnlyReply: Bool = false) {
        AnalyticService.shared.logEvent(name: "sendMessage", properties: ["sendMessage: ":[text]])
        
        guard let assistantId = MainHelper.shared.currentAssistant?.id else {
            print("No current assistant selected")
            onMessageReceived?() // важно - размораживаем кнопку сент в инпуте!
            onMessagesUpdated?(false)
            return
        }

        if !isRegenerate, !isNeedOnlyReply {
            DispatchQueue.main.async { [self] in
                let messageId = UUID().uuidString
                let userMessage = Message(role: "user", content: text, id: messageId)
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
        
        if !ConfigService.shared.messageFromDeveloper.isEmpty,
           isMessageFromTextChat,
           !isRegenerate,
           !isNeedOnlyReply {
            var sentMessages = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            let currentMessage = ConfigService.shared.messageFromDeveloper
            if !sentMessages.contains(currentMessage) {
                AnalyticService.shared.logEvent(
                    name: "developerMessageSent",
                    properties: ["developerMessageSent": [currentMessage]]
                )
                
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
        
        if (text.contains("suggestedPrompt1".localize()) || text.contains("I'd love to see a photo"))
            && MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == false
            && !isAudioCall {
            AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[photo]: ":["photo"]])
            MainHelper.shared.currentAIMessageType = .sendingPhoto
            addLoadingMessage()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.handleSuccessResponse(for: "[photo]", isAudioCall: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        let wannaSeeVideoStr = [
            "see the video",
            "see a video",
            "see video",
            "send video",
            "sent video",
            "send a video",
            "sent a video",
            "send the video",
            "sent the video",
            "i'd love to see a video",
            "i'd love to see the video",
            "i'd love to see video"
        ] // только для англ делаем общий кейс? - пока да пусть так

        let containsVideoRequest = wannaSeeVideoStr.contains { phrase in
            text.lowercased().contains(phrase)
        }

        if text.contains("suggestedPromptVideo".localize())
            || containsVideoRequest
            && MainHelper.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == false
            && MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == false
            && ConfigService.shared.isVideoReady {
            
            if MainHelper.shared.videoCountSent % 5 == 0 { // сколько в итоге то ставить?
                MainHelper.shared.videoCountSent += 1 // - со временем можно прям блокать дальнейшую возможность просмотра видосов! но пока что почему бы и не попрашайничать просто не блокая юзера
                systemPrompt = (systemPrompt ?? "") + " Do not send him a new video, but say that you would like to receive a little gift, even the simplest one - just as a sign of his love for you, and then you will be able to send him a new video, better than the previous one! Do not repeat the text exactly. Improvise to convey the message to the user."
            } else {
                MainHelper.shared.currentAIMessageType = .recordingVideo
                addLoadingMessage()
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    
                    await self.handleSuccessResponse(for: "[video]", isAudioCall: false)
                    self.onMessagesUpdated?(true)
                }
                
                return
            }
        }
        
        if text.contains("[new video]") {
            AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[new video]: ":["from mock"]])
            MainHelper.shared.currentAIMessageType = .recordingVideo
            addLoadingMessage()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.handleSuccessResponse(for: "[new video]", isAudioCall: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        MainHelper.shared.currentAIMessageType = MainHelper.shared.isAudioMessagesMode ? .recordingAudio : .typing
        addLoadingMessage()
        
        // ================= дальше кастом сервер логика идет ================================ \\
        
        let aiService = AIService()
        // Начальный промпт
        var fullMessage = (systemPrompt ?? "") + (previousMessages ?? "") + "\n" + text

        // Внутренняя функция для повторного запроса
        func fetchWithRetry(attempt: Int) {
            aiService.fetchAIResponse(userMessage: fullMessage, systemPrompt: "") { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let responseText):
                    AnalyticService.shared.logEvent(name: "responseMessage", properties: ["responseMessage: ": responseText])
                    if attempt > 0 {
                        WebHookAnaliticksService.shared.sendErrorReport(
                            messageText: "⚠️ Request success after \(attempt) retries \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                        )
                        AnalyticService.shared.logEvent(name: "⚠️ Request success after", properties: ["retries":"\(attempt)"])
                    }
                    
                    let cleanedText = responseText
                        .replacingOccurrences(of: "[video]", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    Task { @MainActor in
                        await self.handleSuccessResponse(for: cleanedText, isAudioCall: isAudioCall)
                    }
                    
                case .failure(let error):
                    
                    if attempt < 1 {
                        fullMessage = (safeSystemPrompt ?? "") + (previousMessages ?? "") + "\n" + text
                        print("⚠️ Attempt 1 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 2 {
                        fullMessage = (systemPrompt ?? "") + "\n" + text
                        print("⚠️ Attempt 2 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 3 {
                        fullMessage = (safeSystemPrompt ?? "") + "\n" + text
                        print("⚠️ Attempt 3 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 4 {
                        let safeHistory = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
                        fullMessage = (systemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 4 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 5 {
                        let safeHistory = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
                        fullMessage = (safeSystemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 5 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 6 {
                        let safeHistory = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
                        fullMessage = (systemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 6 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 7 {
                        let safeHistory = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
                        fullMessage = (safeSystemPrompt ?? "") + "\n" + safeHistory
                        print("⚠️ Attempt 7 failed, retrying in 1s... Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else {
                        // Финальный провал
                        print("❌ Request failed after all retries.")
                        AnalyticService.shared.logEvent(name: "failure sendMessage", properties: [
                            "error type: ": "\(error)",
                            "error localizedDescription: ": "\(error.localizedDescription)"
                        ])
                        WebHookAnaliticksService.shared.sendErrorReport(
                            messageText: "❌ Request failed after all retries \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                        )
                        
                        // Check if error is rate limit (spam control)
                        let errorText: String
                        if case .rateLimitExceeded = error {
                            errorText = "RateLimitResponceErrorText".localize()
                        } else {
                            errorText = "NewErrorText".localize()
                        }
                        
                        let errorMessage = Message(role: "assistant", content: errorText)
                        
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
        let avatar = MainHelper.shared.currentAssistant?.avatarImageName ?? ""
        var testResponce: String?
        
        MainHelper.shared.currentAIMessageType = .sendingPhoto

        if responseText.contains("[new video]") {
            MainHelper.shared.currentAIMessageType = .recordingVideo
            
            Task { @MainActor in
                let videoID = await AdditionalVideosService.shared.getNextVideo()
                                
                let messageId = UUID().uuidString
                let aiMessage = Message(role: "assistant", content: "[new video]", photoID: videoID ?? "", id: messageId)
                messagesAI[messagesAI.count - 1] = aiMessage
                
                messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
                onMessageReceived?()
                onMessagesUpdated?(true)
            }
            return
        }
        
        if responseText.contains("[restrict]") {
            UserDefaults.standard.set(true, forKey: "didRequestSuchPhoto")
            GiftsPhotoService.shared.startFetching()
            photoID = ""
            let allResponses = (1...10).map { "specialRequest\($0)".localize() }
            testResponce = allResponses.randomElement() ?? ""
            AnalyticService.shared.logEvent(name: "requested gift", properties: ["":""])
            WebHookAnaliticksService.shared.sendErrorReport(messageText: "requested gift, for user: \(WebHookAnaliticksService.shared.randomID) + \(Locale.preferredLanguages.first ?? "")")
        } else if avatar.hasPrefix("mainAvatar"),
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
            MainHelper.shared.currentAIMessageType = .typing
            photoID = ""
        }
        
        let messageId = UUID().uuidString
        
        if responseText.contains("[video]") {
            MainHelper.shared.currentAIMessageType = .recordingVideo
            MainHelper.shared.videoCountSent += 1
            RemoteVideoService.shared.getVideoData(for: avatar) { [weak self] videoID in
                guard let self else { return }
                
                AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[video]: ":["\(videoID ?? "")"]])
                let aiMessage = Message(role: "assistant", content: "[video]", photoID: videoID ?? "", id: messageId)
                messagesAI[messagesAI.count - 1] = aiMessage
                
                if !isAudioCall {
                    messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
                }
                onAudioMessagesUpdated?(true)
                onMessageReceived?()
                onMessagesUpdated?(true)
            }
            return
        }
        
        let isVoiceMessage = MainHelper.shared.isAudioMessagesMode && !responseText.contains("[restrict]") && !responseText.contains("[photo]")
        if isVoiceMessage {
            MainHelper.shared.currentAIMessageType = .recordingAudio
        }
        
        let aiMessage = Message(role: "assistant", content: testResponce ?? responseText, photoID: photoID, isVoiceMessage: isVoiceMessage, id: messageId)
        messagesAI[messagesAI.count - 1] = aiMessage
        
        if !isAudioCall {
            messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
        }
        onAudioMessagesUpdated?(true)
        onMessageReceived?()
        onMessagesUpdated?(true)
    }
    
    private func addLoadingMessage() {
        let loadingMessage = Message(role: "assistant", content: "", isLoading: true)
        DispatchQueue.main.async { [self] in
            messagesAI.append(loadingMessage)
            messageIds[messagesAI.count - 1] = UUID().uuidString
            onMessagesUpdated?(true)
        }
    }
}
