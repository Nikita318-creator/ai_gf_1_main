import UIKit
import AVFoundation
import StoreKit

extension SKProduct {
    func extractPriceValue() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

extension Data {
    func imagePreviewFromVideo(at time: CMTime = CMTime(value: 60, timescale: 60)) -> UIImage? {
        let tempFileName = UUID().uuidString + ".mp4"
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tempFileName)

        do {
            try self.write(to: tempFileURL, options: .atomic)
        } catch {
            return nil
        }

        let asset = AVAsset(url: tempFileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            try? FileManager.default.removeItem(at: tempFileURL)
            
            return thumbnail
            
        } catch {
            print("ERROR: Failed to generate thumbnail from video data: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempFileURL)
            return nil
        }
    }
}

enum V1 {
    static let v1 = "Vika2026"
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

extension Array {
    func safeSubscript(_ index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIView {
    func isIPad() -> Bool {
        let isRegularHorizontal = traitCollection.horizontalSizeClass == .regular
        return UIDevice.current.userInterfaceIdiom == .pad && isRegularHorizontal
    }
}

extension String {
    var l: String {
        return NSLocalizedString(self, comment: "")
    }
}
