import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingQRScanner = false
    @State private var showingTransactionSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Wallet Connection Card
                    WalletStatusCard()
                    
                    if walletManager.isConnected {
                        // Balance Card
                        BalanceCard()
                        
                        // Actions Card
                        ActionsCard(showingTransactionSheet: $showingTransactionSheet)
                        
                        // Quest Progress
                        QuestProgressCard()
                        
                        // Collected NFTs
                        CollectedNFTsCard()
                    } else {
                        // Connection Guide
                        ConnectionGuideCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Wallet")
            .sheet(isPresented: $walletManager.showingConnectSheet) {
                WalletConnectSheet()
            }
            .sheet(isPresented: $showingTransactionSheet) {
                TransactionSheet()
            }
        }
    }
}

// MARK: - Subviews
struct WalletStatusCard: View {
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Status Icon
                Image(systemName: walletManager.isConnected ? "checkmark.circle.fill" : "wallet.pass")
                    .foregroundColor(walletManager.statusColor)
                    .font(.title2)
                
                // Status Text
                Text(walletManager.statusMessage)
                    .font(.headline)
                
                Spacer()
                
                // Loading Indicator
                if walletManager.isLoading {
                    ProgressView()
                }
            }
            
            if walletManager.isConnected {
                // Wallet Address
                if let address = walletManager.shortAddress {
                    HStack {
                        Text(address)
                            .font(.system(.body, design: .monospaced))
                        
                        Button(action: {
                            UIPasteboard.general.string = walletManager.walletAddress
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                // Connect Button
                Button(action: { walletManager.connectWalletInApp() }) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Connect Wallet")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct BalanceCard: View {
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance")
                .font(.headline)
            
            if let balance = walletManager.balance {
                Text(walletManager.formatBalance(balance))
                    .font(.system(.title, design: .rounded))
                    .bold()
            } else {
                Text("Loading...")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct ActionsCard: View {
    @EnvironmentObject var walletManager: WalletManager
    @Binding var showingTransactionSheet: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Send Button
            Button(action: { showingTransactionSheet = true }) {
                VStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                    Text("Send")
                }
                .frame(maxWidth: .infinity)
            }
            
            // Receive Button
            Button(action: {
                if let address = walletManager.walletAddress {
                    UIPasteboard.general.string = address
                }
            }) {
                VStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                    Text("Receive")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.blue)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct QuestProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quest Progress")
                .font(.headline)
            
            // Add your quest progress implementation here
            Text("No active quests")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct CollectedNFTsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collected NFTs")
                .font(.headline)
            
            // Add your NFT collection implementation here
            Text("No NFTs collected yet")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct ConnectionGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Connect")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                GuideStep(number: 1, text: "Tap 'Connect Wallet' above")
                GuideStep(number: 2, text: "Enter your wallet address or scan QR code")
                GuideStep(number: 3, text: "Verify your wallet ownership")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct GuideStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct TransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipient")) {
                    TextField("Address", text: $recipientAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount in ETH", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    if let balance = walletManager.balance {
                        Text("Available: \(walletManager.formatBalance(balance))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: sendTransaction) {
                        HStack {
                            Spacer()
                            if walletManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValidTransaction)
                }
            }
            .navigationTitle("Send ETH")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Transaction Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    private var isValidTransaction: Bool {
        guard !recipientAddress.isEmpty,
              !amount.isEmpty,
              walletManager.validateAddress(recipientAddress),
              let amountValue = Double(amount),
              amountValue > 0 else {
            return false
        }
        return true
    }
    
    private func sendTransaction() {
        guard isValidTransaction else {
            errorMessage = "Invalid transaction details"
            showError = true
            return
        }
        
        // Convert ETH to Wei
        let weiAmount = String(Int(Double(amount)! * pow(10, 18)))
        
        walletManager.sendTransaction(to: recipientAddress, amount: weiAmount)
        dismiss()
    }
}

// MARK: - Preview Provider
#if DEBUG
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WalletView()
                .environmentObject(WalletManager.preview)
            
            // Dark mode preview
            WalletView()
                .environmentObject(WalletManager.preview)
                .preferredColorScheme(.dark)
        }
    }
}

struct TransactionSheet_Previews: PreviewProvider {
    static var previews: some View {
        TransactionSheet()
            .environmentObject(WalletManager.preview)
    }
}

struct WalletStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        WalletStatusCard()
            .environmentObject(WalletManager.preview)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct BalanceCard_Previews: PreviewProvider {
    static var previews: some View {
        BalanceCard()
            .environmentObject(WalletManager.preview)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct ActionsCard_Previews: PreviewProvider {
    static var previews: some View {
        ActionsCard(showingTransactionSheet: .constant(false))
            .environmentObject(WalletManager.preview)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct QuestProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        QuestProgressCard()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct CollectedNFTsCard_Previews: PreviewProvider {
    static var previews: some View {
        CollectedNFTsCard()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct ConnectionGuideCard_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionGuideCard()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct GuideStep_Previews: PreviewProvider {
    static var previews: some View {
        GuideStep(number: 1, text: "Test step")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
