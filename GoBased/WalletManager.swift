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
    @Published var isWalletAppAvailable = false
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
    
    enum WalletError: LocalizedError {
        case notConnected
        case invalidAddress
        case invalidAmount
        case networkError(String)
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Wallet is not connected"
            case .invalidAddress:
                return "Invalid wallet address"
            case .invalidAmount:
                return "Invalid transaction amount"
            case .networkError(let message):
                return "Network error: \(message)"
            case .unknown(let message):
                return "Unknown error: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        isWalletAppAvailable = CoinbaseWalletSDK.isCoinbaseWalletInstalled()
    }
    
    // MARK: - Public Methods
    func connectWallet() {
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
                            self?.handleSuccessfulConnection(jsonString: jsonString.description)
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
    
    func disconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.walletAddress = nil
            self?.error = nil
            self?.connectionStatus = .disconnected
            self?.balance = nil
        }
    }
    
    func sendTransaction(to: String, amount: String) {
        guard let fromAddress = walletAddress else {
            handleError(WalletError.notConnected)
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
                            print("Transaction sent: \(jsonString.description)")
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
    
    // MARK: - Private Methods
    private func handleSuccessfulConnection(jsonString: String) {
        if let data = jsonString.data(using: .utf8),
           let addresses = try? JSONDecoder().decode([String].self, from: data),
           let firstAddress = addresses.first {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = true
                self?.walletAddress = firstAddress
                self?.connectionStatus = .connected
                self?.checkBalance()
            }
        } else {
            handleError(WalletError.unknown("Failed to parse wallet address"))
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.error = error.localizedDescription
            self?.connectionStatus = .failed(error.localizedDescription)
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
    
    func formatBalance(_ balanceString: String?) -> String {
        guard let balanceString = balanceString,
              let balanceInt = Int(balanceString) else {
            return "0.00"
        }
        let balanceDecimal = Decimal(balanceInt) / pow(10, 18)
        return String(format: "%.4f ETH", NSDecimalNumber(decimal: balanceDecimal).doubleValue)
    }
    
    // MARK: - Debug Methods
    #if DEBUG
    func printWalletStatus() {
        print("Wallet Status:")
        print("Connected: \(isConnected)")
        print("Address: \(walletAddress ?? "None")")
        print("Balance: \(balance ?? "Unknown")")
        print("Status: \(connectionStatus.description)")
        print("App Available: \(isWalletAppAvailable)")
    }
    
    func simulateConnection() {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.walletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
            self?.connectionStatus = .connected
            self?.balance = "1000000000000000000" // 1 ETH in wei
        }
    }
    
    func simulateDisconnection() {
        disconnect()
    }
    
    func simulateError() {
        handleError(WalletError.networkError("Simulated error for testing"))
    }
    #endif
    
    // MARK: - Extensions
    func reset() {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.walletAddress = nil
            self?.error = nil
            self?.isLoading = false
            self?.connectionStatus = .disconnected
            self?.balance = nil
        }
    }
    
    func refreshWalletState() {
        if isConnected {
            checkBalance()
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let walletConnected = Notification.Name("walletConnected")
    static let walletDisconnected = Notification.Name("walletDisconnected")
    static let walletTransactionCompleted = Notification.Name("walletTransactionCompleted")
}

// MARK: - Preview Helper
#if DEBUG
extension WalletManager {
    static var preview: WalletManager {
        let manager = WalletManager()
        manager.simulateConnection()
        return manager
    }
}
#endif
