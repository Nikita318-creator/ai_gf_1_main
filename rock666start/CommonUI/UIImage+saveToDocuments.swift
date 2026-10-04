import UIKit

extension UIImage {
    func saveToDocuments(withName name: String) -> String? {
        guard let data = self.jpegData(compressionQuality: 0.9) else { return nil }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(name).jpg"
        let fileURL = docsURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName   // возвращаем только имя файла
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}
