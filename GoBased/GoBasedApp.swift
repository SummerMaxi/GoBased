import SwiftUI
import CoinbaseWalletSDK

@main
struct GoBasedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateClass.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
