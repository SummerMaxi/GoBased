import UIKit
import CoinbaseWalletSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            print("❌ No URL in openURLContexts")
            return
        }
        
        print("📱 Received URL in SceneDelegate: \(url)")
        
        // Forward to AppDelegate
        UIApplication.shared.delegate?.application?(
            UIApplication.shared,
            open: url,
            options: [:]
        )
    }
}
