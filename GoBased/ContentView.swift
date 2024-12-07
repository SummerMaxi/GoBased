import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var walletManager = WalletManager() // Create WalletManager instance
    
    var body: some View {
        TabView {
            ARContainerView()
                .environmentObject(locationManager)
                .environmentObject(walletManager) // Inject WalletManager
                .ignoresSafeArea()
                .tabItem {
                    Label("AR", systemImage: "camera")
                }
            
            WalletView()
                .environmentObject(walletManager)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
        }
    }
}
