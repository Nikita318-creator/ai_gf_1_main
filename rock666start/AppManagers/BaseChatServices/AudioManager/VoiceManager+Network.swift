import AVFoundation

extension VoiceManager {
    func speak(text: String, isAnime: Bool) {
        stopSpeaking(needNotifyOthers: false)
        
        isPreparing = true
        postNotification(name: "playAudioObserver")
        
        let selectedLocaleIdentifier = MyGovnoSingltone.shared.userLang.isEmpty ? Locale.current.identifier : MyGovnoSingltone.shared.userLang
        let resolvedVoiceSettings = VoiceMapping.getConfig(for: selectedLocaleIdentifier, isAnime: isAnime)
        
        let sharedAudioSession = AVAudioSession.sharedInstance()
        try? sharedAudioSession.setCategory(.playback, mode: .spokenAudio, options: [])
        try? sharedAudioSession.setActive(true)
        
        guard let endpointURL = URL(string: "\(VoiceAPIKeys.baseHost)?key=\(internalSecretTokenKey)") else { return }
        
        var requestMessage = URLRequest(url: endpointURL)
        requestMessage.httpMethod = "POST"
        requestMessage.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payloadStructure = buildPayloadContainer(text: text, settings: resolvedVoiceSettings)
        requestMessage.httpBody = try? JSONSerialization.data(withJSONObject: payloadStructure)
        
        URLSession.shared.dataTask(with: requestMessage) { [weak self] rawResponseData, _, executionError in
            guard let rawResponseData = rawResponseData, executionError == nil else {
                self?.processExecutionFailure()
                return
            }
            
            guard let parsedDictionary = try? JSONSerialization.jsonObject(with: rawResponseData) as? [String: Any],
                  let base64EncodedStream = parsedDictionary[VoiceAPIKeys.Payload.content] as? String,
                  let decodedByteSequence = Data(base64Encoded: base64EncodedStream) else {
                self?.processExecutionFailure()
                return
            }
            
            let temporaryFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
            try? decodedByteSequence.write(to: temporaryFilePath)
            
            AudioStreamPipelineDispatcher.shared.dispatchOnMainThread {
                self?.isPreparing = false
                self?.startPlaybackStream(from: temporaryFilePath)
            }
        }.resume()
    }

    private func buildPayloadContainer(text: String, settings: VoiceConfig) -> [String: Any] {
        let cleanedInputText = text.replacingOccurrences(of: "~", with: "")
        
        var synthesizedAudioParameters: [String: Any] = [
            VoiceAPIKeys.Payload.encoding: "MP3",
            VoiceAPIKeys.Payload.rate: 1.05
        ]
        
        if let currentPitchValue = settings.pitch {
            synthesizedAudioParameters[VoiceAPIKeys.Payload.pitch] = currentPitchValue
        }
        
        return [
            VoiceAPIKeys.Payload.input: [VoiceAPIKeys.Payload.text: cleanedInputText],
            VoiceAPIKeys.Payload.voice: [
                VoiceAPIKeys.Payload.langCode: settings.langTag,
                VoiceAPIKeys.Payload.name: settings.voiceName
            ],
            VoiceAPIKeys.Payload.audioConfig: synthesizedAudioParameters
        ]
    }

    func processExecutionFailure() {
        AudioStreamPipelineDispatcher.shared.dispatchOnMainThread {
            self.isPreparing = false
            self.notifyPlaybackCompleted()
        }
    }

    func startPlaybackStream(from targetMediaURL: URL) {
        let currentItem = AVPlayerItem(url: targetMediaURL)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        
        audioPlayer = AVPlayer(playerItem: currentItem)
        audioPlayer?.play()
        
        postNotification(name: "playAudioObserver")
    }

    func resetAudioEngineState() {
        if let activePlayer = audioPlayer {
            activePlayer.pause()
            activePlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }

    func notifyPlaybackCompleted() {
        AudioStreamPipelineDispatcher.shared.dispatchOnMainThread {
            self.postNotification(name: "endedAudioObserver")
        }
    }

    func postNotification(name: String) {
        NotificationCenter.default.post(name: NSNotification.Name(name), object: nil)
    }
}
