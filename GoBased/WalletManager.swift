import Foundation
import CoinbaseWalletSDK
import Combine
import SwiftUI

class WalletManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var walletAddress: String?
    @Published var error: String?
    @Published var isLoading = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var showingConnectSheet = false
    @Published var balance: String?
    
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
        checkWalletAvailability()
    }
    
    // MARK: - Public Methods
    func connectWalletInApp() {
        isLoading = true
        connectionStatus = .connecting
        
        let action = Action(
            method: "eth_requestAccounts",
            params: [:],
            optional: false
        )
        
        do {
            try CoinbaseWalletSDK.shared.initiateHandshake(
                initialActions: [action]
            ) { [weak self] result, account in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let jsonString) = firstResult {
                            self?.handleWalletConnection(addressString: jsonString.description)
                        }
                    case .failure(let error):
                        print("❌ Connection failed: \(error)")
                        self?.handleError(error)
                    }
                }
            }
        } catch {
            print("❌ Failed to initiate handshake: \(error)")
            handleError(error)
        }
    }
    
    private func handleWalletConnection(addressString: String) {
        if let data = addressString.data(using: .utf8),
           let addresses = try? JSONDecoder().decode([String].self, from: data),
           let firstAddress = addresses.first {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = true
                self?.walletAddress = firstAddress
                self?.connectionStatus = .connected
                print("✅ Wallet connected: \(firstAddress)")
                self?.checkBalance()
                NotificationCenter.default.post(name: .walletConnected, object: nil)
            }
        } else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse wallet address"]))
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
    
    private func checkWalletAvailability() {
        let isAvailable = CoinbaseWalletSDK.isCoinbaseWalletInstalled()
        print("📱 Coinbase Wallet available: \(isAvailable)")
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.error = error.localizedDescription
            self?.connectionStatus = .failed(error.localizedDescription)
            print("❌ Wallet error: \(error.localizedDescription)")
        }
    }
    
    func sendTransaction(to: String, amount: String) {
        guard let fromAddress = walletAddress else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wallet not connected"]))
            return
        }
        
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
                            self?.checkBalance()
                        }
                    case .failure(let error):
                        self?.handleError(error)
                    }
                }
            }
        } catch {
            handleError(error)
        }
    }
    
    private func checkBalance() {
        guard let address = walletAddress else { return }
        
        let params: [String: Any] = [
            "to": address,
            "data": "0x70a08231000000000000000000000000" + address.dropFirst(2)
        ]
        
        let action = Action(
            method: "eth_call",
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
                            self?.balance = jsonString.description
                        }
                    case .failure(let error):
                        self?.handleError(error)
                    }
                }
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Helper Methods
    func validateAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.utf16.count)
        return regex?.firstMatch(in: address, range: range) != nil
    }
    
    func formatBalance(_ balanceString: String?) -> String {
        guard let balanceString = balanceString,
              let balanceInt = Int(balanceString) else {
            return "0.00"
        }
        let balanceDecimal = Decimal(balanceInt) / pow(10, 18) // Convert from wei to ETH
        return String(format: "%.4f ETH", NSDecimalNumber(decimal: balanceDecimal).doubleValue)
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
        manager.balance = "1000000000000000000" // 1 ETH in wei
        return manager
    }
}
#endif
