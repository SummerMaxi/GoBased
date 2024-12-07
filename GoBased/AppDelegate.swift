import UIKit
import CoinbaseWalletSDK

class AppDelegateClass: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Check if Coinbase Wallet is installed
        if CoinbaseWalletSDK.isCoinbaseWalletInstalled() {
            print("📱 Coinbase Wallet is installed")
            CoinbaseWalletSDK.configure(
                host: URL(string: "cbwallet://")!,
                callback: URL(string: "gobased://")!
            )
        } else {
            print("📱 Coinbase Wallet not installed, using web flow")
            CoinbaseWalletSDK.configure(
                host: URL(string: "https://wallet.coinbase.com")!,
                callback: URL(string: "gobased://")!
            )
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            if try CoinbaseWalletSDK.shared.handleResponse(url) {
                print("Successfully handled Coinbase Wallet response")
                NotificationCenter.default.post(name: .walletConnected, object: nil)
                return true
            }
        } catch {
            print("Error handling Coinbase Wallet response: \(error)")
        }
        return false
    }
}
