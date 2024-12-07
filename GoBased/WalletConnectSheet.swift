import SwiftUI
import CoinbaseWalletSDK

struct WalletConnectSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
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
                    
                    // Connection Status
                    if walletManager.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Connecting to wallet...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Wallet Options Section
                    VStack(spacing: 16) {
                        // Coinbase Wallet Button
                        Button(action: {
                            walletManager.connectWalletInApp()
                        }) {
                            HStack {
                                Image("coinbase-wallet-logo") // Add this image to your assets
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .cornerRadius(12)
                                
                                Text("Coinbase Wallet")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if walletManager.isLoading {
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
                        .disabled(walletManager.isLoading)
                    }
                    .padding(.horizontal)
                    
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
            .alert("Connection Error", isPresented: $walletManager.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(walletManager.error ?? "An unknown error occurred")
            }
        }
        .onChange(of: walletManager.isConnected) { connected in
            if connected {
                dismiss()
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
            
            Spacer()
        }
    }
}

// MARK: - QR Scanner Sheet
struct QRScannerSheet: View {
    @Environment(\.dismiss) var dismiss
    var handleScan: (String) -> Void
    
    var body: some View {
        NavigationView {
            QRScannerView(handleScan: { code in
                handleScan(code)
                dismiss()
            })
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .navigationTitle("Scan QR Code")
        }
    }
}

// MARK: - Custom Modifiers
struct WalletButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

extension View {
    func walletButtonStyle() -> some View {
        modifier(WalletButtonStyle())
    }
}

// MARK: - Preview Provider
#if DEBUG
struct WalletConnectSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            WalletConnectSheet()
                .environmentObject(WalletManager())
            
            // Loading state
            WalletConnectSheet()
                .environmentObject({
                    let manager = WalletManager()
                    manager.isLoading = true
                    return manager
                }())
            
            // Error state
            WalletConnectSheet()
                .environmentObject({
                    let manager = WalletManager()
                    manager.error = "Connection failed"
                    manager.showError = true
                    return manager
                }())
            
            // Dark mode
            WalletConnectSheet()
                .environmentObject(WalletManager())
                .preferredColorScheme(.dark)
        }
    }
}
#endif
