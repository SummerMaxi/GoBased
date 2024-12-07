import UIKit
import CoinbaseWalletSDK

class AppDelegate: NSObject, UIApplicationDelegate {
    private var walletManager: WalletManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🚀 Configuring Coinbase Wallet SDK...")
        
        // Use the primary callback URL from your bundle identifier
        let callbackURL = URL(string: "com.charnockite.gobased://")!
        print("📱 Using callback URL: \(callbackURL)")
        
        // Print debug info
        print("📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("📱 Coinbase Wallet Installed: \(CoinbaseWalletSDK.isCoinbaseWalletInstalled())")
        
        if CoinbaseWalletSDK.isCoinbaseWalletInstalled() {
            print("📱 Coinbase Wallet is installed")
            CoinbaseWalletSDK.configure(
                host: URL(string: "cbwallet://wsegue")!,
                callback: callbackURL
            )
        } else {
            print("🌐 Using web flow")
            CoinbaseWalletSDK.configure(
                host: URL(string: "https://wallet.coinbase.com/wsegue")!,
                callback: callbackURL
            )
        }
        
        print("✅ Coinbase Wallet SDK configured")
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            forName: .didReturnFromWallet,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📱 Received return from wallet notification")
            if let url = notification.userInfo?["url"] as? URL {
                print("📱 Processing callback URL: \(url)")
                self?.processWalletCallback(url)
            }
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("📱 Received URL in AppDelegate: \(url)")
        return processWalletCallback(url)
    }
    
    private func processWalletCallback(_ url: URL) -> Bool {
        print("🔄 Processing wallet callback: \(url)")
        
        do {
            if try CoinbaseWalletSDK.shared.handleResponse(url) {
                print("✅ Successfully handled Coinbase Wallet response")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .walletConnected,
                        object: nil,
                        userInfo: ["url": url]
                    )
                }
                return true
            } else {
                print("⚠️ handleResponse returned false")
            }
        } catch {
            print("❌ Error handling wallet callback: \(error)")
        }
        return false
    }
    
    // MARK: - Scene Configuration
    func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didReturnFromWallet = Notification.Name("didReturnFromWallet")
}

// MARK: - URL Handling Helper
extension AppDelegate {
    private func isValidCallbackURL(_ url: URL) -> Bool {
        let validSchemes = ["com.charnockite.gobased", "gobased"]
        return validSchemes.contains(url.scheme ?? "")
    }
}

#if DEBUG
extension AppDelegate {
    func printDebugInfo() {
        print("📱 Debug Info:")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("Valid URL Schemes: com.charnockite.gobased, gobased")
        print("Coinbase Wallet Installed: \(CoinbaseWalletSDK.isCoinbaseWalletInstalled())")
    }
}
#endif
