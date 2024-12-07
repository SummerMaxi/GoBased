import UIKit
import CoinbaseWalletSDK

class AppDelegateClass: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure SDK with proper URLs
        CoinbaseWalletSDK.configure(
            host: URL(string: "https://wallet.coinbase.com")!,
            callback: URL(string: "gobased://")!
        )
        
        print("Coinbase Wallet App installed: \(CoinbaseWalletSDK.isCoinbaseWalletInstalled())")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            if try CoinbaseWalletSDK.shared.handleResponse(url) {
                print("Successfully handled Coinbase Wallet response")
                return true
            }
        } catch {
            print("Error handling Coinbase Wallet response: \(error)")
        }
        return false
    }
}
