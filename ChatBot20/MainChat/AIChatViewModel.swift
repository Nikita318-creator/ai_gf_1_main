import UIKit

struct Message {
    let role: String
    let content: String
    var isLoading: Bool = false
    var photoID: String = ""
    var isVoiceMessage: Bool = false
    var id: String?
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
        // ================= ОДИНАКОВО ДЛЯ СВОЕГО ОБОИХ ПОДХОДОВ ================================ \\
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
            
            // достаём массив уже отправленных сообщений (или пустой)
            var sentMessages = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            
            let currentMessage = ConfigService.shared.messageFromDeveloper
            
            // проверяем, что такого сообщения ещё не было
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
                
                // Сохраняем в UserDefaults (это можно оставить снаружи Task)
                sentMessages.append(currentMessage)
                UserDefaults.standard.set(sentMessages, forKey: "developerMessagesSent")
                
                return
            }
        }
        
        // если запросил фотку известным промптом то не грузим АИ-шку а просто отдаем фотку
        if (text.contains("suggestedPrompt1".localize()) || text.contains("I'd love to see a photo"))
            && MainHelper.shared.currentAssistant?.avatarImageName.contains("ex") == false
            && MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == false
            && !isAudioCall {
            AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[photo]: ":["from mock"]])
            MainHelper.shared.currentAIMessageType = .sendingPhoto
            addLoadingMessage()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_500_000_000)
                
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
            && MainHelper.shared.currentAssistant?.avatarImageName.contains("ex") == false
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
                        
                        // Доп. логика с фото (isExSendPhoto), если не аудиозвонок
                        if MainHelper.shared.isExSendPhoto {
                            MainHelper.shared.isExSendPhoto = false
                            let photoIDEx: String
                            if GEOService.shared.isAsionGeo {
                                photoIDEx = MainHelper.shared.picAsionIDs.randomElement() ?? ""
                            } else {
                                photoIDEx = MainHelper.shared.exGirlDs.randomElement() ?? ""
                            }
                            let messageId = UUID().uuidString
                            let aiPhotoExMessage = Message(role: "assistant", content: "[photo]", photoID: photoIDEx, id: messageId)
                            self.messagesAI.append(aiPhotoExMessage)
                            if !isAudioCall {
                                self.messageService.addMessage(aiPhotoExMessage, assistantId: assistantId, messageId: messageId)
                            }
                            self.onMessagesUpdated?(true)
                        }
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
                            errorText = "LocationError.NewErrorText".localize()
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
            RemotePhotoService.shared.startFetching()

            photoID = ""
            let allResponses = (1...10).map { "responceToTestRequest\($0)".localize() }
            testResponce = allResponses.randomElement() ?? ""
            AnalyticService.shared.logEvent(name: "requested gift", properties: ["":""])
            WebHookAnaliticksService.shared.sendErrorReport(messageText: "requested gift, for user: \(WebHookAnaliticksService.shared.randomID) + \(Locale.preferredLanguages.first ?? "")")
            
        } else if ["1", "2", "4", "7", "10", "CustomAvatar1", "CustomAvatar4", "roleplay6", "roleplay7"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picIBlondDs.randomElement() ?? "" : ""
        } else if ["3", "5", "6", "8", "9", "CustomAvatar2", "CustomAvatar6", "CustomAvatar9", "roleplay1", "roleplay2"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picIBrunetdDs.randomElement() ?? "" : ""
        } else if ["CustomAvatar7", "CustomAvatar8", "CustomAvatar15", "CustomAvatar12", "CustomAvatar14", "roleplay10"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRedIDs.randomElement() ?? "" : ""
        } else if ["CustomAvatar3", "CustomAvatar17", "CustomAvatar16", "CustomAvatar18", "roleplay12"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRealRedIDs.randomElement() ?? "" : ""
        } else if ["CustomAvatar5", "CustomAvatar10", "CustomAvatar11", "roleplay11"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picPinkIDs.randomElement() ?? "" : ""
        } else if ["CustomAvatar13", "roleplay9"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picWhiteIDs.randomElement() ?? "" : ""
        } else if ["roleplay3"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRoleplay3NurseIDs.randomElement() ?? "" : ""
        } else if ["roleplay4"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRoleplay4ElfIDs.randomElement() ?? "" : ""
        } else if ["roleplay5"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRoleplay5NeighbourIDs.randomElement() ?? "" : ""
        } else if ["roleplay8"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picRoleplay8AnimeIDs.randomElement() ?? "" : ""
        } else if avatar.contains("arab") {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picArabIDs.randomElement() ?? "" : ""
        } else if avatar.contains("ind") {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picIndIDs.randomElement() ?? "" : ""
        } else if avatar.contains("asion") {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picAsionIDs.randomElement() ?? "" : ""
        } else if avatar.contains("latina") {
            photoID = responseText.contains("[photo]") ? MainHelper.shared.picLatinaIDs.randomElement() ?? "" : ""
        } else if ["milfAvatar1"].contains(avatar) {
            // Ждем результат выполнения, код замрет на этой строке, но UI будет жить
            photoID = responseText.contains("[photo]") ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: 1) : ""
            
        } else if ["milfAvatar2"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: 2) : ""
            
        } else if ["milfAvatar3"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: 3) : ""
            
        } else if ["milfAvatar4"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: 4) : ""
            
        } else if ["milfAvatar5"].contains(avatar) {
            photoID = responseText.contains("[photo]") ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: 5) : ""
            
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

extension AIChatViewModel {
    var sampleProfiles: [[String: Any]] {
        return [
            ["age": 19, "country": "USA", "city": "LA", "bio": "Profile1".localize()],
            ["age": 21, "country": "Canada", "city": "Toronto", "bio": "Profile2".localize()],
            ["age": 22, "country": "UK", "city": "London", "bio": "Profile3".localize()],
            ["age": 20, "country": "USA", "city": "New York", "bio": "Profile4".localize()],
            ["age": 23, "country": "Spain", "city": "Barcelona", "bio": "Profile5".localize()],
            ["age": 19, "country": "Germany", "city": "Berlin", "bio": "Profile6".localize()],
            ["age": 21, "country": "France", "city": "Paris", "bio": "Profile7".localize()],
            ["age": 22, "country": "Italy", "city": "Rome", "bio": "Profile8".localize()],
            ["age": 20, "country": "USA", "city": "Miami", "bio": "Profile9".localize()],
            ["age": 24, "country": "Australia", "city": "Sydney", "bio": "Profile10".localize()],
            ["age": 19, "country": "USA", "city": "Chicago", "bio": "Profile11".localize()],
            ["age": 21, "country": "Brazil", "city": "Rio", "bio": "Profile12".localize()],
            ["age": 23, "country": "Mexico", "city": "Cancun", "bio": "Profile13".localize()],
            ["age": 20, "country": "Japan", "city": "Tokyo", "bio": "Profile14".localize()],
            ["age": 22, "country": "South Korea", "city": "Seoul", "bio": "Profile15".localize()],
            ["age": 21, "country": "USA", "city": "San Francisco", "bio": "Profile16".localize()],
            ["age": 19, "country": "Russia", "city": "Moscow", "bio": "Profile17".localize()],
            ["age": 22, "country": "Turkey", "city": "Istanbul", "bio": "Profile18".localize()],
            ["age": 20, "country": "USA", "city": "Austin", "bio": "Profile19".localize()],
            ["age": 23, "country": "Argentina", "city": "Buenos Aires", "bio": "Profile20".localize()],
            ["age": 19, "country": "USA", "city": "Dallas", "bio": "Profile21".localize()],
            ["age": 22, "country": "Italy", "city": "Milan", "bio": "Profile22".localize()],
            ["age": 20, "country": "Canada", "city": "Vancouver", "bio": "Profile23".localize()],
            ["age": 23, "country": "USA", "city": "Las Vegas", "bio": "Profile24".localize()],
            ["age": 21, "country": "Spain", "city": "Madrid", "bio": "Profile25".localize()],
            ["age": 19, "country": "France", "city": "Nice", "bio": "Profile26".localize()],
            ["age": 22, "country": "Germany", "city": "Munich", "bio": "Profile27".localize()],
            ["age": 24, "country": "USA", "city": "Boston", "bio": "Profile28".localize()],
            ["age": 20, "country": "Brazil", "city": "São Paulo", "bio": "Profile29".localize()],
            ["age": 21, "country": "Japan", "city": "Osaka", "bio": "Profile30".localize()],
            ["age": 23, "country": "Mexico", "city": "Mexico City", "bio": "Profile31".localize()],
            ["age": 19, "country": "Argentina", "city": "Cordoba", "bio": "Profile32".localize()],
            ["age": 22, "country": "Poland", "city": "Warsaw", "bio": "Profile33".localize()],
            ["age": 21, "country": "Sweden", "city": "Stockholm", "bio": "Profile34".localize()],
            ["age": 20, "country": "Norway", "city": "Oslo", "bio": "Profile35".localize()],
            ["age": 23, "country": "Netherlands", "city": "Amsterdam", "bio": "Profile36".localize()],
            ["age": 19, "country": "Switzerland", "city": "Zurich", "bio": "Profile37".localize()],
            ["age": 24, "country": "Austria", "city": "Vienna", "bio": "Profile38".localize()],
            ["age": 20, "country": "India", "city": "Mumbai", "bio": "Profile39".localize()],
            ["age": 22, "country": "China", "city": "Beijing", "bio": "Profile40".localize()],
            ["age": 21, "country": "South Africa", "city": "Cape Town", "bio": "Profile41".localize()],
            ["age": 23, "country": "Greece", "city": "Athens", "bio": "Profile42".localize()],
            ["age": 19, "country": "Portugal", "city": "Lisbon", "bio": "Profile43".localize()],
            ["age": 24, "country": "Egypt", "city": "Cairo", "bio": "Profile44".localize()],
            // азиатка
            ["age": 21, "country": "Japan", "city": "Kyoto", "bio": "Profile45".localize()],
            // латина
            ["age": 22, "country": "Mexico", "city": "Guadalajara", "bio": "Profile46".localize()],
            // из Индии
            ["age": 20, "country": "India", "city": "Delhi", "bio": "Profile47".localize()],
            // арабка
            ["age": 23, "country": "UAE", "city": "Dubai", "bio": "Profile48".localize()],
            // снова азиатка
            ["age": 19, "country": "South Korea", "city": "Busan", "bio": "Profile49".localize()],
            // снова латина
            ["age": 21, "country": "Brazil", "city": "Salvador", "bio": "Profile50".localize()],
            // снова из Индии
            ["age": 22, "country": "India", "city": "Bangalore", "bio": "Profile51".localize()],
            // снова арабка
            ["age": 24, "country": "Morocco", "city": "Casablanca", "bio": "Profile52".localize()],
            // Новые профили (Европейки, MILF)
            ["age": 44, "country": "France", "city": "Lyon", "bio": "Profile53".localize()],
            ["age": 39, "country": "Italy", "city": "Florence", "bio": "Profile54".localize()],
            ["age": 48, "country": "Germany", "city": "Hamburg", "bio": "Profile55".localize()],
            ["age": 42, "country": "Czech Republic", "city": "Prague", "bio": "Profile56".localize()],
            ["age": 52, "country": "Austria", "city": "Salzburg", "bio": "Profile57".localize()]
        ]
    }
}
