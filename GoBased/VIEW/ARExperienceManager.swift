import SwiftUI
import Combine
import RealityKit
import ARKit

class ARExperienceManager: ObservableObject {
    // Published properties for UI updates
    @Published var isReady = false
    @Published var collectedCount: Int = 0
    @Published var totalLogos: Int = 15
    @Published var nearestLogoDistance: Float?
    @Published var visibleLogos: [LogoLocation] = []
    @Published var errorMessage: String?
    
    // AR session state
    @Published var isARSessionActive = false
    
    // Initialize the manager
    init() {
        checkARCapabilities()
    }
    
    // Check if device supports AR
    private func checkARCapabilities() {
        if ARWorldTrackingConfiguration.isSupported {
            isReady = true
        } else {
            errorMessage = "AR is not supported on this device"
        }
    }
    
    // Increment collected logos count
    func incrementCollected() {
        DispatchQueue.main.async {
            self.collectedCount += 1
            
            // Optional: Add completion feedback
            if self.collectedCount == self.totalLogos {
                self.showCompletionAlert()
            }
        }
    }
    
    // Update nearest logo distance
    func updateNearestLogoDistance(userPosition: SIMD3<Float>) {
        let distances = LogoLocation.predefinedLocations.map { location in
            let dx = location.position.x - userPosition.x
            let dy = location.position.y - userPosition.y
            let dz = location.position.z - userPosition.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
        nearestLogoDistance = distances.min()
    }
    
    // Update visible logos based on distance
    func updateVisibleLogos(userPosition: SIMD3<Float>) {
        visibleLogos = LogoLocation.predefinedLocations.filter { location in
            let dx = location.position.x - userPosition.x
            let dy = location.position.y - userPosition.y
            let dz = location.position.z - userPosition.z
            let distance = sqrt(dx*dx + dy*dy + dz*dz)
            return distance <= 100.0 // Logos within 100 meters are visible
        }
    }
    
    // Reset the experience
    func resetExperience() {
        DispatchQueue.main.async {
            self.collectedCount = 0
            self.visibleLogos = []
            self.nearestLogoDistance = nil
            self.errorMessage = nil
        }
    }
    
    // Show completion alert
    private func showCompletionAlert() {
        DispatchQueue.main.async {
            // You can implement custom completion behavior here
            self.errorMessage = "Congratulations! You've collected all logos!"
        }
    }
    
    // Get progress percentage
    var progressPercentage: Double {
        return Double(collectedCount) / Double(totalLogos) * 100
    }
    
    // Check if all logos are collected
    var isCompleted: Bool {
        return collectedCount >= totalLogos
    }
    
    // Get remaining logos count
    var remainingLogos: Int {
        return totalLogos - collectedCount
    }
    
    // Format distance for display
    func formatDistance(_ distance: Float?) -> String {
        guard let distance = distance else { return "Unknown" }
        return String(format: "%.1f meters", distance)
    }
    
    // Start AR session
    func startARSession() {
        isARSessionActive = true
    }
    
    // Stop AR session
    func stopARSession() {
        isARSessionActive = false
    }
    
    // Handle AR session errors
    func handleARError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}

// Extension for additional formatting and utilities
extension ARExperienceManager {
    // Get progress description
    var progressDescription: String {
        return "\(collectedCount)/\(totalLogos) Logos Collected"
    }
    
    // Get status description
    var statusDescription: String {
        if isCompleted {
            return "Collection Complete!"
        } else if collectedCount == 0 {
            return "Start collecting logos!"
        } else {
            return "\(remainingLogos) logos remaining"
        }
    }
    
    // Clear error message
    func clearError() {
        errorMessage = nil
    }
}
