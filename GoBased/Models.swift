//
//  NFTItem.swift
//  GoBased
//
//  Created by NAVEEN on 07/12/24.
//


// Models.swift
import Foundation

struct NFTItem: Identifiable {
    let id: UUID = UUID()
    let latitude: Double
    let longitude: Double
    let tokenURI: String
    let metadata: NFTMetadata
}

struct NFTMetadata: Codable {
    let name: String
    let description: String
    let image: String
}