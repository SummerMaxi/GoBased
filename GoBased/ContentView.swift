// ContentView.swift
import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var walletManager = WalletManager()
    
    var body: some View {
        TabView {
            MapView()
                .environmentObject(locationManager)
                .environmentObject(walletManager)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
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

#Preview {
    ContentView()
}
