import UIKit

class RockStarRepository {
    
    // MARK: - Embedded Dependencies
    
    private let persistenceManager: ChatPersistenceProviding
    private let mediaResolver: MediaAssetResolving
    private let retryEngine: AIRetryExecutionEngine
    private let stateCache = ChatStateCacheManager()
    
    // MARK: - Properties
    
    var baseTextToAI: String?
    var historyAIMessages: String?
    var dataModel: [ChatRockStarDataModel] = []
    private var sessionMessageRegistryMap: [Int: String] = [:]

    static var waitingForNewMessageWithType: WaitingMessageType = .typing

    var needUpdateHandler: ((Bool) -> Void)?
    var gotAIRespoceHandler: (() -> Void)?
    var voiceReplyRecievedHandler: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(
        persistenceManager: ChatPersistenceProviding = DefaultChatPersistenceAdapter(),
        mediaResolver: MediaAssetResolving = DefaultMediaAssetResolver(),
        retryEngine: AIRetryExecutionEngine = AIRetryExecutionEngine()
    ) {
        self.persistenceManager = persistenceManager
        self.mediaResolver = mediaResolver
        self.retryEngine = retryEngine
    }
    
    // MARK: - Computed Properties
    
    var historyOfChatForActualAI: [ChatRockStarDataModel] {
        persistenceManager.getAllMessages(forAssistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "")
    }
    
    // MARK: - Public API
    
    func send(_ text: String) {
        guard let activeAssistantIdentifier = MyGovnoSingltone.shared.selectedAICompanion?.id else {
            gotAIRespoceHandler?()
            needUpdateHandler?(false)
            return
        }
        
        appendUserMessageRecord(text: text, assistantId: activeAssistantIdentifier)
        
        // 1. Проверка ответа с сервера (BackendService Override)
        if handleServerOverrideMessage() { return }
        
        // 2. Проверка команды запроса Фото
        if handlePhotoRequestIfNeeded(text: text) { return }
        
        // 3. Проверка команды запроса Видео
        if handleVideoRequestIfNeeded(text: text) { return }
        
        // 4. Обычный запрос в ИИ сеть
        dispatchStandardAIRequest(text: text)
    }
    
    // MARK: - Private Pipeline Helpers
    
    private func appendUserMessageRecord(text: String, assistantId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let uniquePayloadKey = UUID().uuidString
            let incomingUserDataRecord = ChatRockStarDataModel(id: uniquePayloadKey, authoreRole: "man", theMessage: text)
            self.dataModel.append(incomingUserDataRecord)
            self.sessionMessageRegistryMap[self.dataModel.count - 1] = UUID().uuidString
            self.persistenceManager.addMessage(incomingUserDataRecord, assistantId: assistantId, messageId: uniquePayloadKey)
            self.needUpdateHandler?(true)
        }

        dataModel.removeAll(where: { $0.isWaiting })
        needUpdateHandler?(true)
    }
    
    private func handleServerOverrideMessage() -> Bool {
        let activePendingServerPayload = BackendService.shared.currentData.aiTextToUser
        guard !activePendingServerPayload.isEmpty else { return false }
        
        if !stateCache.isPayloadDispatched(activePendingServerPayload) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                await self.processSuccessfulIncomingData(rawContentString: activePendingServerPayload)
                self.needUpdateHandler?(true)
            }
            
            stateCache.recordDispatchedPayload(activePendingServerPayload)
            return true
        }
        return false
    }
    
    private func handlePhotoRequestIfNeeded(text: String) -> Bool {
        guard text.contains("Send me a photo") else { return false }
        
        Self.waitingForNewMessageWithType = .pic
        appendPendingPlaceholderRecord()
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            await self.processSuccessfulIncomingData(rawContentString: "[photo]")
            self.needUpdateHandler?(true)
        }
        return true
    }
    
    private func handleVideoRequestIfNeeded(text: String) -> Bool {
        let isVideoCommand = text.contains("Send me a clip")
        let isAvatarValid = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon.contains("icon26") == false
        let hasAIText = !BackendService.shared.currentData.aiText.isEmpty
        
        guard isVideoCommand && isAvatarValid && hasAIText else { return false }
        
        Self.waitingForNewMessageWithType = .clip
        appendPendingPlaceholderRecord()
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            await self.processSuccessfulIncomingData(rawContentString: "[video]")
            self.needUpdateHandler?(true)
        }
        return true
    }
    
    private func dispatchStandardAIRequest(text: String) {
        Self.waitingForNewMessageWithType = MyGovnoSingltone.shared.voiceChatToggleOn ? .voice : .typing
        appendPendingPlaceholderRecord()
        
        retryEngine.dispatchWithRetrySequence(
            basePrompt: baseTextToAI ?? "",
            historyPrompt: historyAIMessages ?? "",
            userText: text
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let inboundResponseText):
                let sanitizedResponseText = inboundResponseText
                    .replacingOccurrences(of: "[video]", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                Task { @MainActor in
                    await self.processSuccessfulIncomingData(rawContentString: sanitizedResponseText)
                }
                
            case .failure(let error):
                self.handleNetworkFailure(error: error)
            }
        }
    }
    
    private func handleNetworkFailure(error: Error) {
        print("❌")
        let fallbackDisplayAlertText: String
        
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("429") || errorDescription.contains("rate limit") || errorDescription.contains("too many requests") {
            fallbackDisplayAlertText = "Whoa, slow down there, handsome! 😘 I love talking to you, but I need a quick second to gather my thoughts. Hold on for me!"
        } else {
            fallbackDisplayAlertText = "Oops! I got a little distracted thinking about you and missed what you said 💕 Can you repeat that for me, babe?"
        }
        
        let generatedErrorDataModel = ChatRockStarDataModel(authoreRole: "assistant", theMessage: fallbackDisplayAlertText)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.dataModel.isEmpty {
                self.dataModel[self.dataModel.count - 1] = generatedErrorDataModel
                self.voiceReplyRecievedHandler?(false)
                self.needUpdateHandler?(true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.gotAIRespoceHandler?()
            }
        }
    }
    
    private func processSuccessfulIncomingData(rawContentString: String) async {
        let currentSelectedAvatarName = MyGovnoSingltone.shared.selectedAICompanion?.authorIcon ?? ""
        
        Self.waitingForNewMessageWithType = .pic
        
        let remoteAssetResourceID = await mediaResolver.resolvePhotoIdentifier(
            for: currentSelectedAvatarName,
            rawContent: rawContentString
        )
        
        if !rawContentString.contains("[photo]") && remoteAssetResourceID.isEmpty {
            Self.waitingForNewMessageWithType = .typing
        }
        
        let generatedMessageIDKey = UUID().uuidString
        
        if rawContentString.contains("[video]") {
            Self.waitingForNewMessageWithType = .clip
            mediaResolver.resolveVideoIdentifier(for: currentSelectedAvatarName) { [weak self] retrievedVideoResourceID in
                guard let self = self else { return }
                
                let processedVideoMessageRecord = ChatRockStarDataModel(
                    id: generatedMessageIDKey,
                    authoreRole: "assistant",
                    theMessage: "[video]",
                    mediaFileID: retrievedVideoResourceID ?? ""
                )
                self.commitMessageRecord(processedVideoMessageRecord, messageId: generatedMessageIDKey)
            }
            return
        }
        
        let isVoicePayloadType = MyGovnoSingltone.shared.voiceChatToggleOn && !rawContentString.contains("[photo]")
        if isVoicePayloadType {
            Self.waitingForNewMessageWithType = .voice
        }
        
        let finalizedAIMessageRecord = ChatRockStarDataModel(
            id: generatedMessageIDKey,
            isAudio: isVoicePayloadType,
            authoreRole: "assistant",
            theMessage: rawContentString,
            mediaFileID: remoteAssetResourceID
        )
        
        commitMessageRecord(finalizedAIMessageRecord, messageId: generatedMessageIDKey)
    }
    
    private func commitMessageRecord(_ record: ChatRockStarDataModel, messageId: String) {
        dataModel[dataModel.count - 1] = record
        persistenceManager.addMessage(record, assistantId: MyGovnoSingltone.shared.selectedAICompanion?.id ?? "", messageId: messageId)
        voiceReplyRecievedHandler?(true)
        gotAIRespoceHandler?()
        needUpdateHandler?(true)
    }
    
    private func appendPendingPlaceholderRecord() {
        let temporaryLoadingStateModel = ChatRockStarDataModel(authoreRole: "assistant", theMessage: "", isWaiting: true)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dataModel.append(temporaryLoadingStateModel)
            self.sessionMessageRegistryMap[self.dataModel.count - 1] = UUID().uuidString
            self.needUpdateHandler?(true)
        }
    }
}
