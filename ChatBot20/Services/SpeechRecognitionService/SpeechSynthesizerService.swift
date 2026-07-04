//
//  SpeechSynthesizerService.swift
//  ChatBot20
//
//  Created by Mikita on 18/01/2026.
//

import AVFoundation

class SpeechSynthesizerService: NSObject {
    static let shared = SpeechSynthesizerService()
    
    var audioPlayer: AVPlayer?
    private var apiKey: String {
        "AIzaSyAisC2WePRrTDojZa" + ConfigService.shared.audioHalfKey
    }

    var currentSpeakinID: String?
    private(set) var isPreparing: Bool = false

    var isSpeaking: Bool {
        if isPreparing { return true }
        return audioPlayer?.rate != 0 && audioPlayer?.error == nil && audioPlayer != nil
    }

    private override init() {
        super.init()
    }

    func speak(text: String) {
        stopSpeaking(needNotifyOthers: false)
        
        isPreparing = true
        NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        
        let rawLang = MainHelper.shared.currentLanguage.isEmpty ? (Locale.current.identifier) : MainHelper.shared.currentLanguage
        let voiceConfig = VoiceMapping.getConfig(for: rawLang)
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
        try? audioSession.setActive(true)
        
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let textToSpeech = text.replacingOccurrences(of: "~", with: "")
        
        // Динамически собираем audioConfig, чтобы не пихать pitch туда, где он запрещен
        var audioConfig: [String: Any] = [
            "audioEncoding": "MP3",
            "speakingRate": 1.05
        ]
        
        // Если pitch есть в конфиге (не nil) — добавляем его. Если это Journey (nil) — игнорируем.
        if let pitchValue = voiceConfig.pitch {
            audioConfig["pitch"] = pitchValue
        }
        
        let json: [String: Any] = [
            "input": ["text": textToSpeech],
            "voice": [
                "languageCode": voiceConfig.langTag,
                "name": voiceConfig.voiceName
            ],
            "audioConfig": audioConfig
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("❌ Ошибка сети: \(error?.localizedDescription ?? "no data")")
                self?.handleError()
                return
            }
            
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let audioContent = jsonResponse["audioContent"] as? String,
                  let audioData = Data(base64Encoded: audioContent) else {
                print("❌ Google вернул ошибку: \(String(data: data, encoding: .utf8) ?? "")")
                self?.handleError()
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
            try? audioData.write(to: tempURL)
            
            DispatchQueue.main.async {
                self?.isPreparing = false
                self?.play(url: tempURL)
            }
        }.resume()
    }

    // Доп. метод для сброса стейта при ошибке, чтобы ячейка не "висла"
    private func handleError() {
        DispatchQueue.main.async {
            self.isPreparing = false
            self.handleFinished()
        }
    }

    private func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
        
        // Повторно триггерим обновление, так как статус сменился с isPreparing на реальный play
        NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
    }

    // Изменяем логику: теперь это пауза, если плеер уже создан
    func togglePause() {
        guard let player = audioPlayer else { return }
        if player.rate == 0 {
            player.play()
            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        } else {
            player.pause()
            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
        }
    }

    func stopSpeaking(needNotifyOthers: Bool = true) {
        isPreparing = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        if let player = audioPlayer {
            player.pause()
            // Важнейший фикс: сбрасываем плеер на начало, чтобы в следующий раз он мог играть снова
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        audioPlayer = nil
        if needNotifyOthers {
            handleFinished()
        }
    }
    
    @objc func playerDidFinishPlaying() {
        // Когда аудио доиграло до конца, вызываем полную остановку со сбросом
        stopSpeaking(needNotifyOthers: true)
    }
    
    private func handleFinished() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
        }
    }
}
