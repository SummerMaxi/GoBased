import SwiftUI
import CoinbaseWalletSDK

struct WalletConnectSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @State private var isConnecting = false
    @State private var showQRScanner = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        Image(systemName: "wallet.pass.fill")
                            .imageScale(.large)
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Connect Your Wallet")
                            .font(.title2)
                            .bold()
                        
                        Text("Connect to explore quests and collect NFTs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical)
                    
                    // Wallet Options Section
                    VStack(spacing: 16) {
                        // Coinbase Wallet Button
                        Button(action: connectWallet) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .font(.title3)
                                Text("Connect Wallet")
                                Spacer()
                                if isConnecting {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(isConnecting)
                    }
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why connect a wallet?")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow(icon: "map.fill", text: "Track quest progress")
                            benefitRow(icon: "cube.fill", text: "Collect and store NFTs")
                            benefitRow(icon: "star.fill", text: "Earn rewards")
                            benefitRow(icon: "lock.fill", text: "Secure ownership")
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationBarItems(
                leading: Text("Connect Wallet")
                    .font(.headline),
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    private func connectWallet() {
        isConnecting = true
        walletManager.connectWalletInApp()
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#if DEBUG
struct WalletConnectSheet_Previews: PreviewProvider {
    static var previews: some View {
        WalletConnectSheet()
            .environmentObject(WalletManager())
    }
}
#endif
