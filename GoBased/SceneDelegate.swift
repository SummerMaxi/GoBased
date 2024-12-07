//
//  SceneDelegate.swift
//  GoBased
//
//  Created by NAVEEN on 08/12/24.
//


import UIKit
import CoinbaseWalletSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        do {
            if try CoinbaseWalletSDK.shared.handleResponse(url) {
                print("✅ Successfully handled Coinbase Wallet callback")
                // Notify the app that we've returned from wallet
                NotificationCenter.default.post(
                    name: .didReturnFromWallet,
                    object: nil
                )
            }
        } catch {
            print("❌ Error handling wallet callback: \(error)")
        }
    }
}

extension Notification.Name {
    static let didReturnFromWallet = Notification.Name("didReturnFromWallet")
}
