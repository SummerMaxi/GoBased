// NFTClaimView.swift
import SwiftUI

struct NFTClaimView: View {
    @EnvironmentObject var walletManager: WalletManager
    let latitude: Double
    let longitude: Double
    let tokenURI: String
    
    var body: some View {
        VStack {
            Text("NFT Found!")
                .font(.title)
            
            Button("Claim NFT") {
                claimNFT()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!walletManager.isConnected)
        }
    }
    
    private func claimNFT() {
        // Implement NFT claiming logic
    }
}
