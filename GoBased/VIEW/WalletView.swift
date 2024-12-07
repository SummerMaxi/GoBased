// WalletView.swift
import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        VStack {
            if walletManager.isConnected {
                VStack {
                    Text("Connected Wallet")
                        .font(.headline)
                    Text(walletManager.walletAddress ?? "")
                        .font(.subheadline)
                }
            } else {
                Button("Connect Wallet") {
                    walletManager.connectWallet()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if let error = walletManager.error {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            walletManager.checkConnection()
        }
    }
}
