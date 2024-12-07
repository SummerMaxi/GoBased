// AppDelegate.swift
import UIKit
import CoinbaseWalletSDK

class AppDelegateClass: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize SDK
        CoinbaseWalletSDK.configure(
            host: URL(string: "https://wallet.coinbase.com")!, callback: URL(string: "gobased://")!
        )
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            return try CoinbaseWalletSDK.shared.handleResponse(url)
        } catch {
            print("Error handling URL: \(error)")
            return false
        }
    }
}
