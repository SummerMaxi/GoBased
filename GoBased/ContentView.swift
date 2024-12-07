import SwiftUI

struct ContentView: View {
    @StateObject private var walletManager = WalletManager()
    
    var body: some View {
        TabView {
            ARContainerView()
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
