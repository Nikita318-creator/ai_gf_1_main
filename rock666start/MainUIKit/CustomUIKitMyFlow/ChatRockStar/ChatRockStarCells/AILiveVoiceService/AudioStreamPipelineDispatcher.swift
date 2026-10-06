import Foundation

final class AudioStreamPipelineDispatcher {
    static let shared = AudioStreamPipelineDispatcher()
    
    private init() {}
    
    func dispatchOnMainThread(_ executionBlock: @escaping () -> Void) {
        if Thread.isMainThread {
            executionBlock()
        } else {
            DispatchQueue.main.async(execute: executionBlock)
        }
    }
}
