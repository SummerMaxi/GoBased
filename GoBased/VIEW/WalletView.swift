import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Card
            VStack {
                Text(walletManager.statusMessage)
                    .foregroundColor(walletManager.statusColor)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                
                // Wallet Info
                if walletManager.isConnected {
                    if let address = walletManager.shortAddress {
                        HStack {
                            Text("Address:")
                            Text(address)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    
                    if let balance = walletManager.balance {
                        HStack {
                            Text("Balance:")
                            Text(walletManager.formatBalance(balance))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(15)
            
            // Connect/Disconnect Button
            Button(action: {
                if walletManager.isConnected {
                    walletManager.disconnect()  // Changed from disconnectWallet to disconnect
                } else {
                    walletManager.connectWallet()
                }
            }) {
                HStack {
                    Image(systemName: walletManager.isConnected ? "link.badge.minus" : "link.badge.plus")
                    Text(walletManager.isConnected ? "Disconnect Wallet" : "Connect Wallet")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(walletManager.isConnected ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(walletManager.isLoading)
            
            // Loading Indicator
            if walletManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            // Error Message
            if let error = walletManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Wallet")
    }
}

#if DEBUG
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
            .environmentObject(WalletManager.preview)
    }
}
#endif
