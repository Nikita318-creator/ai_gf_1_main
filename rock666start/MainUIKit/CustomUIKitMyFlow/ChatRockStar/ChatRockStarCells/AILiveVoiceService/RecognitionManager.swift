import Foundation
import UIKit
import Speech
import AVFoundation

final class MicService: NSObject {
    private var coreAudioPipeline: AVAudioEngine?
    private var streamAudioRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeRecognitionWorker: SFSpeechRecognitionTask?
    private var primarySpeechDetector = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "en-US"))
    private let activeMediaSession = AVAudioSession.sharedInstance()
    
    var onResult: ((String) -> Void)?
    weak var vc: UIViewController?
    
    public static var speachOptions: AVAudioSession.CategoryOptions = [AVAudioSession.CategoryOptions.allowBluetoothHFP, .defaultToSpeaker]
    
    override init() {
        super.init()
    }

    func startRecognition() {
        guard let validDetector = primarySpeechDetector, validDetector.isAvailable else { return }
        
        stopRecognition()
        
        let standaloneEngine = AVAudioEngine()
        self.coreAudioPipeline = standaloneEngine
        
        do {
            try activeMediaSession.setCategory(.playAndRecord, options: MicService.speachOptions)
            try activeMediaSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            return
        }
        
        activeMediaSession.requestRecordPermission { [weak self] hasAccess in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard hasAccess else {
                    self.displayMicAccessWarning()
                    return
                }
                
                self.streamAudioRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let validRequest = self.streamAudioRequest else { return }
                
                validRequest.shouldReportPartialResults = true
                
                self.activeRecognitionWorker = validDetector.recognitionTask(with: validRequest) { [weak self] transcriptionData, taskError in
                    if let validTranscription = transcriptionData {
                        self?.onResult?(validTranscription.bestTranscription.formattedString)
                    }
                    
                    if taskError != nil || (transcriptionData?.isFinal ?? false) {
                        self?.stopRecognition()
                    }
                }
                
                let hardwareInputNode = standaloneEngine.inputNode
                hardwareInputNode.removeTap(onBus: 0)
                
                let inputAudioFormat = hardwareInputNode.outputFormat(forBus: 0)
                
                guard inputAudioFormat.sampleRate > 0, inputAudioFormat.channelCount > 0 else {
                    print("⚠️ SpeechRecognition: Invalid hardware format. SampleRate: \(inputAudioFormat.sampleRate), Channels: \(inputAudioFormat.channelCount)")
                    return
                }
                
                hardwareInputNode.installTap(onBus: 0, bufferSize: 1024, format: inputAudioFormat) { [weak self] pcmBuffer, _ in
                    self?.streamAudioRequest?.append(pcmBuffer)
                }
                
                standaloneEngine.prepare()
                
                do {
                    try standaloneEngine.start()
                } catch {
                    print("Failed to start audio engine: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopRecognition() {
        activeRecognitionWorker?.cancel()
        streamAudioRequest?.endAudio()
        
        if let runningEngine = coreAudioPipeline, runningEngine.isRunning {
            runningEngine.inputNode.removeTap(onBus: 0)
            runningEngine.stop()
        }
        
        coreAudioPipeline = nil
        activeRecognitionWorker = nil
        streamAudioRequest = nil
        
        do {
            try activeMediaSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    private func displayMicAccessWarning() {
        let permissionDialog = UIAlertController(
            title: "Microphone Access Required",
            message: "Please allow access to your Microphone in Settings",
            preferredStyle: .alert
        )
        permissionDialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        permissionDialog.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let targetSettingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(targetSettingsURL) {
                UIApplication.shared.open(targetSettingsURL)
            }
        })
        vc?.present(permissionDialog, animated: true)
    }
}
