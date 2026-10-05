import UIKit

final class SplashViewController: UIViewController {
    
    var onFinish: (() -> Void)?
    
    override func loadView() {
        self.view = SplashView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startTimer()
    }
    
    private func startTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.onFinish?()
        }
    }
}
