import Foundation
import CoinbaseWalletSDK
import Combine
import SwiftUI

// MARK: - WalletConnectRequest
struct WalletConnectRequest {
    let chainId: String
    let methods: [String]
    let appName: String
    let appLogoUrl: String?
    let description: String?
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "chainId": chainId,
            "methods": methods,
            "appName": appName
        ]
        
        if let logo = appLogoUrl {
            dict["appLogoUrl"] = logo
        }
        
        if let desc = description {
            dict["description"] = desc
        }
        
        return dict
    }
}

// MARK: - Response Models
struct WalletResponse: Codable {
    let chain: String
    let networkId: Int
    let address: String
}

class WalletManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var walletAddress: String?
    @Published var error: String?
    @Published var isLoading = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var showingConnectSheet = false
    @Published var balance: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
        
        var description: String {
            switch self {
            case .disconnected:
                return "Not connected"
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            case .failed(let message):
                return "Failed: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .didReturnFromWallet)
            .sink { [weak self] notification in
                print("📱 Received return from wallet notification")
                if let url = notification.userInfo?["url"] as? URL {
                    print("📱 Processing callback URL: \(url)")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func connectWalletInApp() {
        print("🔄 Starting wallet connection...")
        isLoading = true
        connectionStatus = .connecting
        
        let action = Action(
            method: "eth_requestAccounts",
            params: [
                "chainId": "0x1",
                "jsonrpc": "2.0",
                "id": 1
            ],
            optional: false
        )
        
        do {
            print("📤 Initiating handshake with Coinbase Wallet...")
            try CoinbaseWalletSDK.shared.initiateHandshake(
                initialActions: [action]
            ) { [weak self] result, account in
                print("📥 Received wallet response")
                self?.handleConnectionResponse(result: result, account: account)
            }
        } catch {
            print("❌ Failed to initiate handshake: \(error)")
            handleError(error)
        }
    }
    
    func disconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.walletAddress = nil
            self?.error = nil
            self?.connectionStatus = .disconnected
            self?.balance = nil
            NotificationCenter.default.post(name: .walletDisconnected, object: nil)
        }
    }
    
    // MARK: - Private Methods
    private func handleConnectionResponse(result: Result<BaseMessage<[Result<JSONString, ActionError>]>, Error>, account: Account?) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            
            switch result {
            case .success(let message):
                print("✅ Success message: \(message)")
                if let firstResult = message.content.first {
                    switch firstResult {
                    case .success(let jsonString):
                        print("📝 Response data: \(jsonString)")
                        
                        // Parse the JSON response
                        if let data = jsonString.description.data(using: .utf8),
                           let json = try? JSONDecoder().decode(WalletResponse.self, from: data) {
                            print("✅ Extracted address: \(json.address)")
                            self?.handleSuccessfulConnection(address: json.address)
                        } else {
                            // Fallback manual parsing
                            if let data = jsonString.description.data(using: .utf8),
                               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let address = dict["address"] as? String {
                                print("✅ Manually extracted address: \(address)")
                                self?.handleSuccessfulConnection(address: address)
                            } else {
                                print("❌ Failed to parse wallet address")
                                self?.handleError(NSError(domain: "", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse wallet address"]))
                            }
                        }
                        
                    case .failure(let error):
                        print("❌ Action error: \(error)")
                        self?.handleError(error)
                    }
                }
            case .failure(let error):
                print("❌ Connection error: \(error)")
                self?.handleError(error)
            }
        }
    }
    
    private func handleSuccessfulConnection(address: String) {
        print("🎉 Handling successful connection for address: \(address)")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.walletAddress = address
            self?.connectionStatus = .connected
            self?.isLoading = false
            self?.showingConnectSheet = false
            
            print("✅ Wallet connected: \(address)")
            NotificationCenter.default.post(name: .walletConnected, object: nil)
            
            // Check balance with proper address
            self?.checkBalance(for: address)
        }
    }
    
    private func handleError(_ error: Error) {
        print("❌ Error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.error = error.localizedDescription
            self?.connectionStatus = .failed(error.localizedDescription)
            self?.showError = true
        }
    }
    
    private func checkBalance(for address: String) {
        print("📊 Checking balance for address: \(address)")
        
        let action = Action(
            method: "eth_getBalance",
            params: [
                address:
                "latest"
            ],
            optional: false
        )
        
        do {
            try CoinbaseWalletSDK.shared.makeRequest(
                Request(actions: [action])
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let balanceString) = firstResult {
                            print("💰 Received balance: \(balanceString)")
                            if let formattedBalance = self?.formatBalance(balanceString.description) {
                                print("💰 Formatted balance: \(formattedBalance)")
                                self?.balance = formattedBalance
                            }
                        } else {
                            print("⚠️ No balance data in response")
                            self?.balance = "0.00 ETH"
                        }
                    case .failure(let error):
                        print("❌ Balance check failed: \(error)")
                        self?.balance = "Error"
                    }
                }
            }
        } catch {
            print("❌ Failed to check balance: \(error)")
            balance = "Error"
        }
    }
    
    // MARK: - Helper Methods
    func formatBalance(_ balanceString: String?) -> String {
        guard let balanceString = balanceString else { return "0.00 ETH" }
        
        // Remove quotes and 0x prefix
        let cleanString = balanceString
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "0x", with: "")
        
        // Convert hex to decimal
        guard let balanceValue = Int(cleanString, radix: 16) else {
            return "0.00 ETH"
        }
        
        // Convert wei to ETH (1 ETH = 10^18 wei)
        let ethValue = Double(balanceValue) / pow(10, 18)
        return String(format: "%.4f ETH", ethValue)
    }
    
    func validateAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.utf16.count)
        return regex?.firstMatch(in: address, range: range) != nil
    }
    
    // MARK: - Helper Properties
    var statusColor: Color {
        switch connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .failed:
            return .red
        }
    }
    
    var statusMessage: String {
        if isLoading {
            return "Processing..."
        }
        return connectionStatus.description
    }
    
    var isTransactionEnabled: Bool {
        return isConnected && !isLoading
    }
    
    var shortAddress: String? {
        guard let address = walletAddress else { return nil }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
    
    // MARK: - Transaction Methods
    func sendTransaction(to: String, amount: String) {
        guard let fromAddress = walletAddress else {
            handleError(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Wallet not connected"]))
            return
        }
        
        print("💸 Sending transaction from \(fromAddress) to \(to)")
        
        let params: [String: Any] = [
            "from": fromAddress,
            "to": to,
            "value": amount,
            "data": "0x"
        ]
        
        let action = Action(
            method: "eth_sendTransaction",
            params: params,
            optional: false
        )
        
        do {
            try CoinbaseWalletSDK.shared.makeRequest(
                Request(actions: [action])
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let jsonString) = firstResult {
                            print("✅ Transaction sent: \(jsonString.description)")
                            self?.checkBalance(for: fromAddress)
                            NotificationCenter.default.post(name: .transactionSent, object: nil)
                        }
                    case .failure(let error):
                        print("❌ Transaction failed: \(error)")
                        self?.handleError(error)
                    }
                }
            }
        } catch {
            print("❌ Failed to send transaction: \(error)")
            handleError(error)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let walletConnected = Notification.Name("walletConnected")
    static let walletDisconnected = Notification.Name("walletDisconnected")
    static let transactionSent = Notification.Name("transactionSent")
}

// MARK: - Preview Helper
#if DEBUG
extension WalletManager {
    static var preview: WalletManager {
        let manager = WalletManager()
        manager.isConnected = true
        manager.walletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
        manager.connectionStatus = .connected
        manager.balance = "1.0000 ETH"
        return manager
    }
}
#endif
