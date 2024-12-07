import Foundation
import Combine
import RealityKit

class ARExperienceManager: ObservableObject {
    @Published var isReady = false
    @Published var nearestLogoDistance: Float?
    @Published var visibleLogos: [LogoLocation] = []
    
    func updateNearestLogoDistance(userPosition: SIMD3<Float>) {
        let distances = LogoLocation.predefinedLocations.map { location in
            let dx = location.position.x - userPosition.x
            let dy = location.position.y - userPosition.y
            let dz = location.position.z - userPosition.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
        nearestLogoDistance = distances.min()
    }
    
    func updateVisibleLogos(userPosition: SIMD3<Float>) {
        visibleLogos = LogoLocation.predefinedLocations.filter { location in
            let dx = location.position.x - userPosition.x
            let dy = location.position.y - userPosition.y
            let dz = location.position.z - userPosition.z
            let distance = sqrt(dx*dx + dy*dy + dz*dz)
            return distance <= 10.0 // Logos within 10 meters are considered visible
        }
    }
}
