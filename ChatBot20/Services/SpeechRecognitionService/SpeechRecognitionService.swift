import Foundation
import UIKit
import Speech
import AVFoundation

final class SpeechRecognitionService: NSObject {
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "en-US"))
    private let audioSession = AVAudioSession.sharedInstance()
    
    var onResult: ((String) -> Void)?
    weak var vc: UIViewController?
    
    public static var speachOptions: AVAudioSession.CategoryOptions = [AVAudioSession.CategoryOptions.allowBluetoothHFP, .defaultToSpeaker]
    
    override init() {
        super.init()
    }

    func startRecognition() {
        guard let recognizer = recognizer, recognizer.isAvailable else { return }
        
        stopRecognition()
        
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        /*
        mode: .measurement говорит iOS:

        «мне нужен максимально “сырой”, немодифицированный звук, без украшательств»

        Что это реально делает

        Когда ты ставишь .measurement:

        ❌ выключается системная обработка голоса:

        шумоподавление

        автоматическое усиление (AGC)

        эквалайзеры под речь

        voice processing magic

        ✅ микрофон отдаёт максимально точный сигнал, как есть
        
        Сравнение с другими режимами

        .default — универсальный, но с обработкой

        .voiceChat — оптимизирован под звонки (шумодав, компрессия)

        .videoRecording — заточен под камеру

        .measurement — самый “честный”
         
         do {
             try audioSession.setCategory(.playAndRecord, mode: .measurement, options: SpeechRecognitionService.speachOptions)
             try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
         } catch {
             print("Failed to set up audio session: \(error.localizedDescription)")
             return
         }
         
        */
        
        do {
            try audioSession.setCategory(.playAndRecord, options: SpeechRecognitionService.speachOptions)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            return
        }
        
        audioSession.requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard granted else {
                    self.showMicrophonePermissionAlert()
                    return
                }
                
                self.request = SFSpeechAudioBufferRecognitionRequest()
                guard let request = self.request else { return }
                
                request.shouldReportPartialResults = true
                
                self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    if let result = result {
                        self?.onResult?(result.bestTranscription.formattedString)
                    }
                    
                    if error != nil || (result?.isFinal ?? false) {
                        self?.stopRecognition()
                    }
                }
                
                // --- СЕКЦИЯ ПОВЫШЕННОЙ БЕЗОПАСНОСТИ ---
                let inputNode = engine.inputNode
                inputNode.removeTap(onBus: 0) // Всегда чистим перед установкой
                
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                // Проверка на 0 Гц И на 0 каналов (защита от краша при смене AirPods/Динамик)
                guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                    print("⚠️ SpeechRecognition: Invalid hardware format. SampleRate: \(recordingFormat.sampleRate), Channels: \(recordingFormat.channelCount)")
                    return
                }
                
                // Устанавливаем тап на актуальном формате
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    self?.request?.append(buffer)
                }
                // ---------------------------------------
                
                engine.prepare()
                
                do {
                    try engine.start()
                } catch {
                    print("Failed to start audio engine: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopRecognition() {
        recognitionTask?.cancel()
        request?.endAudio()
        
        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        
        audioEngine = nil
        recognitionTask = nil
        request = nil
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    private func showMicrophonePermissionAlert() {
        let alert = UIAlertController(
            title: "MicrophoneAccess.Title".localize(),
            message: "MicrophoneAccess.Message".localize(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel".localize(), style: .cancel))
        alert.addAction(UIAlertAction(title: "OpenSettings".localize(), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        })
        vc?.present(alert, animated: true)
    }
}
