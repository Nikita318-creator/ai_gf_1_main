import UIKit

class RockStarRepository {
    let messageService = AIGirlfriendMessagesManager()
    var baseTextToAI: String?
    var historyAIMessages: String?
    var dataModel: [ChatRockStarDataModel] = []

    private var sessionMessageRegistryMap: [Int: String] = [:]

    static var waitingForNewMessageWithType: WaitingMessageType = .typing

    var needUpdateHandler: ((Bool) -> Void)?
    var gotAIRespoceHandler: (() -> Void)?
    var voiceReplyRecievedHandler: ((Bool) -> Void)?
    
    var historyOfChatForActualAI: [ChatRockStarDataModel] {
        messageService.getAllMessages(forAssistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "")
    }
    
    func send(_ text: String) {
        
        guard let activeAssistantIdentifier = MyGovnoSingltone.shared.selectedAICompanion?.id else {
            gotAIRespoceHandler?()
            needUpdateHandler?(false)
            return
        }
        
        DispatchQueue.main.async { [self] in
            let uniquePayloadKey = UUID().uuidString
            let incomingUserDataRecord = ChatRockStarDataModel(id: uniquePayloadKey, authoreRole: "man", theMessage: text)
            dataModel.append(incomingUserDataRecord)
            sessionMessageRegistryMap[dataModel.count - 1] = UUID().uuidString
            messageService.addMessage(incomingUserDataRecord, assistantId: activeAssistantIdentifier, messageId: uniquePayloadKey)
            needUpdateHandler?(true)
        }

        dataModel.removeAll(where: { $0.isWaiting })
        needUpdateHandler?(true)
        
        if !BackendService.shared.currentData.aiTextToUser.isEmpty {
            var sentDispatchedHistoryList = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            let activePendingServerPayload = BackendService.shared.currentData.aiTextToUser
            if !sentDispatchedHistoryList.contains(activePendingServerPayload) {
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    await self.processSuccessfulIncomingData(rawContentString: activePendingServerPayload)
                    self.needUpdateHandler?(true)
                }
                
                sentDispatchedHistoryList.append(activePendingServerPayload)
                UserDefaults.standard.set(sentDispatchedHistoryList, forKey: "developerMessagesSent")
                return
            }
        }
        
        if (text.contains("Send me a photo")) {
            RockStarRepository.waitingForNewMessageWithType = .pic
            appendPendingPlaceholderRecord()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await self.processSuccessfulIncomingData(rawContentString: "[photo]")
                self.needUpdateHandler?(true)
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
                
                await self.processSuccessfulIncomingData(rawContentString: "[video]")
                self.needUpdateHandler?(true)
            }
            
            return
        }
        
        RockStarRepository.waitingForNewMessageWithType = MyGovnoSingltone.shared.voiceChatToggleOn ? .voice : .typing
        appendPendingPlaceholderRecord()
        
        
        let clientNetworkAgent = GeminiAPIService()
        var assembledPromptBuffer = (baseTextToAI ?? "") + (historyAIMessages ?? "") + "\n" + text

        func executeRetrySequence(iterationCount: Int) {
            clientNetworkAgent.fetchAIResponse(userMessage: assembledPromptBuffer, systemPrompt: "") { [weak self] completionResult in
                guard let self = self else { return }
                
                switch completionResult {
                case .success(let inboundResponseText):
                    let sanitizedResponseText = inboundResponseText
                        .replacingOccurrences(of: "[video]", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    Task { @MainActor in
                        await self.processSuccessfulIncomingData(rawContentString: sanitizedResponseText)
                    }
                    
                case .failure(let networkExecutionError):
                    
                    if iterationCount < 1 {
                        assembledPromptBuffer = (baseTextToAI ?? "") + "\n" + text
                        print("⚠️ 1")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            executeRetrySequence(iterationCount: iterationCount + 1)
                        }
                    } else if iterationCount < 2 {
                        let fallbackContextPrompt = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
                        assembledPromptBuffer = (baseTextToAI ?? "") + "\n" + fallbackContextPrompt
                        print("⚠️ 2")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            executeRetrySequence(iterationCount: iterationCount + 1)
                        }
                    } else if iterationCount < 3 {
                        let secondaryFallbackPrompt = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
                        assembledPromptBuffer = (baseTextToAI ?? "") + "\n" + secondaryFallbackPrompt
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
                            if !self.dataModel.isEmpty {
                                self.dataModel[self.dataModel.count - 1] = generatedErrorDataModel
                                self.voiceReplyRecievedHandler?(false)
                                self.needUpdateHandler?(true)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.gotAIRespoceHandler?()
                            }
                        }
                    }
                }
            }
        }
        
        executeRetrySequence(iterationCount: 0)
    }
    
    private func processSuccessfulIncomingData(rawContentString: String) async {
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
                dataModel[dataModel.count - 1] = processedVideoMessageRecord
                
                messageService.addMessage(processedVideoMessageRecord, assistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "", messageId: generatedMessageIDKey)
                voiceReplyRecievedHandler?(true)
                gotAIRespoceHandler?()
                needUpdateHandler?(true)
            }
            return
        }
        
        let isVoicePayloadType = MyGovnoSingltone.shared.voiceChatToggleOn && !rawContentString.contains("[photo]")
        if isVoicePayloadType {
            RockStarRepository.waitingForNewMessageWithType = .voice
        }
        
        let finalizedAIMessageRecord = ChatRockStarDataModel(id: generatedMessageIDKey, isAudio: isVoicePayloadType, authoreRole: "assistant", theMessage: overrideTextRepresentation ?? rawContentString, mediaFileID: remoteAssetResourceID)
        dataModel[dataModel.count - 1] = finalizedAIMessageRecord
        
        messageService.addMessage(finalizedAIMessageRecord, assistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "", messageId: generatedMessageIDKey)
        voiceReplyRecievedHandler?(true)
        gotAIRespoceHandler?()
        needUpdateHandler?(true)
    }
    
    private func appendPendingPlaceholderRecord() {
        let temporaryLoadingStateModel = ChatRockStarDataModel(authoreRole: "assistant", theMessage: "", isWaiting: true)
        DispatchQueue.main.async { [self] in
            dataModel.append(temporaryLoadingStateModel)
            sessionMessageRegistryMap[dataModel.count - 1] = UUID().uuidString
            needUpdateHandler?(true)
        }
    }
}
