// WalletManager.swift
import Foundation
import CoinbaseWalletSDK
import Combine

class WalletManager: ObservableObject {
    @Published var isConnected = false
    @Published var walletAddress: String?
    @Published var error: String?
    
    func connectWallet() {
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
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let jsonString) = firstResult,
                           let data = jsonString.description.data(using: .utf8),
                           let addresses = try? JSONDecoder().decode([String].self, from: data),
                           let firstAddress = addresses.first {
                            self?.isConnected = true
                            self?.walletAddress = firstAddress
                        }
                    case .failure(let error):
                        self?.error = error.localizedDescription
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func sendTransaction(to: String, amount: String) {
        guard isConnected, let from = walletAddress else { return }
        
        let params: [String: Any] = [
            "from": from,
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
            try CoinbaseWalletSDK.shared.initiateHandshake(
                initialActions: [action]
            ) { [weak self] result, account in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let jsonString) = firstResult {
                            print("Transaction hash: \(jsonString.description)")
                        }
                    case .failure(let error):
                        self?.error = error.localizedDescription
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func checkConnection() {
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
                    switch result {
                    case .success(let message):
                        if let firstResult = message.content.first,
                           case .success(let jsonString) = firstResult,
                           let data = jsonString.description.data(using: .utf8),
                           let addresses = try? JSONDecoder().decode([String].self, from: data),
                           let firstAddress = addresses.first {
                            self?.isConnected = true
                            self?.walletAddress = firstAddress
                        }
                    case .failure(let error):
                        self?.isConnected = false
                        self?.walletAddress = nil
                        self?.error = error.localizedDescription
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// Helper structures
struct EthereumTransaction: Codable {
    let from: String
    let to: String
    let value: String
    let data: String
}
