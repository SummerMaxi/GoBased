import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        TabView {
            ARContainerView()
                .environmentObject(locationManager)
                .environmentObject(walletManager)
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
