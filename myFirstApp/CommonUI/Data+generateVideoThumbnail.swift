import AVFoundation
import UIKit

extension Data {
    func generateVideoThumbnail(at time: CMTime = CMTime(value: 60, timescale: 60)) -> UIImage? {
        let temporaryFileName = UUID().uuidString + ".mp4"
        let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(temporaryFileName)

        do {
            try self.write(to: temporaryFileURL, options: .atomic)
        } catch {
            print("ERROR: Failed to write video data to temporary file: \(error)")
            return nil
        }

        let asset = AVAsset(url: temporaryFileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            try? FileManager.default.removeItem(at: temporaryFileURL)
            
            return thumbnail
            
        } catch {
            print("ERROR: Failed to generate thumbnail from video data: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: temporaryFileURL)
            return nil
        }
    }
}
