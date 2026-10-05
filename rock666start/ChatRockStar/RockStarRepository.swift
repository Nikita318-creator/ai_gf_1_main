import UIKit

class RockStarRepository {
    let messageService = AIGirlfriendMessagesManager()
    var messagesAI: [ChatRockStarDataModel] = []
    var onMessagesUpdated: ((Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var onAudioMessagesUpdated: ((Bool) -> Void)?
    var systemPrompt: String?
    var previousMessages: String?

    private var sessionMessageRegistryMap: [Int: String] = [:]

    static var waitingForNewMessageWithType: WaitingMessageType = .typing

    var currentMessagesAI: [ChatRockStarDataModel] {
        messageService.getAllMessages(forAssistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "")
    }
    
    func sendMessageViaCustomServer(_ text: String, isRegenerate: Bool = false, isAudioCall: Bool = false, isMessageFromTextChat: Bool = false, isNeedOnlyReply: Bool = false) {
        
        guard let activeAssistantIdentifier = MyGovnoSingltone.shared.selectedAICompanion?.id else {
            print("No current assistant selected")
            onMessageReceived?()
            onMessagesUpdated?(false)
            return
        }

        if !isRegenerate, !isNeedOnlyReply {
            DispatchQueue.main.async { [self] in
                let uniquePayloadKey = UUID().uuidString
                let incomingUserDataRecord = ChatRockStarDataModel(id: uniquePayloadKey, authoreRole: "man", theMessage: text)
                messagesAI.append(incomingUserDataRecord)
                sessionMessageRegistryMap[messagesAI.count - 1] = UUID().uuidString
                if !isAudioCall {
                    messageService.addMessage(incomingUserDataRecord, assistantId: activeAssistantIdentifier, messageId: uniquePayloadKey)
                }
                onMessagesUpdated?(true)
            }
        }
        
        messagesAI.removeAll(where: { $0.isWaiting })
        onMessagesUpdated?(true)
        
        if !BackendService.shared.currentData.aiTextToUser.isEmpty,
           isMessageFromTextChat,
           !isRegenerate,
           !isNeedOnlyReply {
            var sentDispatchedHistoryList = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            let activePendingServerPayload = BackendService.shared.currentData.aiTextToUser
            if !sentDispatchedHistoryList.contains(activePendingServerPayload) {
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    await self.processSuccessfulIncomingData(rawContentString: activePendingServerPayload, isVoiceSessionActive: isAudioCall)
                    self.onMessagesUpdated?(true)
                }
                
                sentDispatchedHistoryList.append(activePendingServerPayload)
                UserDefaults.standard.set(sentDispatchedHistoryList, forKey: "developerMessagesSent")
                return
            }
        }
        
        if (text.contains("Send me a photo"))
            && !isAudioCall {
            RockStarRepository.waitingForNewMessageWithType = .pic
            appendPendingPlaceholderRecord()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.processSuccessfulIncomingData(rawContentString: "[photo]", isVoiceSessionActive: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        if text.contains("Send me a clip")
            && MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("mainAvatar26") == false
            && !BackendService.shared.currentData.aiText.isEmpty {
            
            
            RockStarRepository.waitingForNewMessageWithType = .clip
            appendPendingPlaceholderRecord()
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.processSuccessfulIncomingData(rawContentString: "[video]", isVoiceSessionActive: false)
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        RockStarRepository.waitingForNewMessageWithType = MyGovnoSingltone.shared.voiceChatToggleOn ? .voice : .typing
        appendPendingPlaceholderRecord()
        
        
        let clientNetworkAgent = GeminiAPIService()
        var assembledPromptBuffer = (systemPrompt ?? "") + (previousMessages ?? "") + "\n" + text

        func executeRetrySequence(iterationCount: Int) {
            clientNetworkAgent.fetchAIResponse(userMessage: assembledPromptBuffer, systemPrompt: "") { [weak self] completionResult in
                guard let self = self else { return }
                
                switch completionResult {
                case .success(let inboundResponseText):
                    let sanitizedResponseText = inboundResponseText
                        .replacingOccurrences(of: "[video]", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    Task { @MainActor in
                        await self.processSuccessfulIncomingData(rawContentString: sanitizedResponseText, isVoiceSessionActive: isAudioCall)
                    }
                    
                case .failure(let networkExecutionError):
                    
                    if iterationCount < 1 {
                        assembledPromptBuffer = (systemPrompt ?? "") + "\n" + text
                        print("⚠️ 1")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            executeRetrySequence(iterationCount: iterationCount + 1)
                        }
                    } else if iterationCount < 2 {
                        let fallbackContextPrompt = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
                        assembledPromptBuffer = (systemPrompt ?? "") + "\n" + fallbackContextPrompt
                        print("⚠️ 2")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            executeRetrySequence(iterationCount: iterationCount + 1)
                        }
                    } else if iterationCount < 3 {
                        let secondaryFallbackPrompt = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
                        assembledPromptBuffer = (systemPrompt ?? "") + "\n" + secondaryFallbackPrompt
                        print("⚠️ 3")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            executeRetrySequence(iterationCount: iterationCount + 1)
                        }
                    } else {
                        print("❌ Request failed after all retries.")
                        
                        let fallbackDisplayAlertText: String
                        if case .rateLimitExceeded = networkExecutionError {
                            fallbackDisplayAlertText = "Whoa, slow down there, handsome! 😘 I love talking to you, but I need a quick second to gather my thoughts. Hold on for me!"
                        } else {
                            fallbackDisplayAlertText = "Oops! I got a little distracted thinking about you and missed what you said 💕 Can you repeat that for me, babe?"
                        }
                        
                        let generatedErrorDataModel = ChatRockStarDataModel(authoreRole: "assistant", theMessage: fallbackDisplayAlertText)
                        
                        DispatchQueue.main.async {
                            if !self.messagesAI.isEmpty {
                                self.messagesAI[self.messagesAI.count - 1] = generatedErrorDataModel
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
        
        executeRetrySequence(iterationCount: 0)
    }
    
    private func processSuccessfulIncomingData(rawContentString: String, isVoiceSessionActive: Bool) async {
        var remoteAssetResourceID: String = ""
        let currentSelectedAvatarName = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName ?? ""
        var overrideTextRepresentation: String?
        
        RockStarRepository.waitingForNewMessageWithType = .pic
        
       if currentSelectedAvatarName.hasPrefix("mainAvatar"),
                  let parsedNumberComponent = currentSelectedAvatarName.components(separatedBy: "mainAvatar").last,
                  let parsedAvatarNumericID = Int(parsedNumberComponent) {
            
            remoteAssetResourceID = rawContentString.contains("[photo]")
            ? await AdditionalRemotePhotoService.shared.getRandomPhoto(for: parsedAvatarNumericID)
            : ""
            
        } else if currentSelectedAvatarName.hasPrefix("MyGF"),
                  let matchedDigitCharacter = currentSelectedAvatarName.dropFirst(4).first(where: { $0.isNumber }),
                  let parsedAvatarNumericID = Int(String(matchedDigitCharacter)) {
            
            remoteAssetResourceID = rawContentString.contains("[photo]")
            ? await AdditionalRemotePhotoService.shared.getRandomPhoto(forMyGF: parsedAvatarNumericID)
            : ""
        } else {
            if rawContentString.contains("[photo]") {
                remoteAssetResourceID = await AdditionalRemotePhotoService.shared.getRandomPhotoFromAllPool(avatarID: currentSelectedAvatarName)
            } else {
                RockStarRepository.waitingForNewMessageWithType = .typing
                remoteAssetResourceID = ""
            }
        }
        
        let generatedMessageIDKey = UUID().uuidString
        
        if rawContentString.contains("[video]") {
            RockStarRepository.waitingForNewMessageWithType = .clip
            RemoteVideoService.shared.getVideoData(for: currentSelectedAvatarName) { [weak self] retrievedVideoResourceID in
                guard let self else { return }
                
                let processedVideoMessageRecord = ChatRockStarDataModel(id: generatedMessageIDKey, authoreRole: "assistant", theMessage: "[video]", mediaFileID: retrievedVideoResourceID ?? "")
                messagesAI[messagesAI.count - 1] = processedVideoMessageRecord
                
                if !isVoiceSessionActive {
                    messageService.addMessage(processedVideoMessageRecord, assistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "", messageId: generatedMessageIDKey)
                }
                onAudioMessagesUpdated?(true)
                onMessageReceived?()
                onMessagesUpdated?(true)
            }
            return
        }
        
        let isVoicePayloadType = MyGovnoSingltone.shared.voiceChatToggleOn && !rawContentString.contains("[photo]")
        if isVoicePayloadType {
            RockStarRepository.waitingForNewMessageWithType = .voice
        }
        
        let finalizedAIMessageRecord = ChatRockStarDataModel(id: generatedMessageIDKey, isAudio: isVoicePayloadType, authoreRole: "assistant", theMessage: overrideTextRepresentation ?? rawContentString, mediaFileID: remoteAssetResourceID)
        messagesAI[messagesAI.count - 1] = finalizedAIMessageRecord
        
        if !isVoiceSessionActive {
            messageService.addMessage(finalizedAIMessageRecord, assistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "", messageId: generatedMessageIDKey)
        }
        onAudioMessagesUpdated?(true)
        onMessageReceived?()
        onMessagesUpdated?(true)
    }
    
    private func appendPendingPlaceholderRecord() {
        let temporaryLoadingStateModel = ChatRockStarDataModel(authoreRole: "assistant", theMessage: "", isWaiting: true)
        DispatchQueue.main.async { [self] in
            messagesAI.append(temporaryLoadingStateModel)
            sessionMessageRegistryMap[messagesAI.count - 1] = UUID().uuidString
            onMessagesUpdated?(true)
        }
    }
}
