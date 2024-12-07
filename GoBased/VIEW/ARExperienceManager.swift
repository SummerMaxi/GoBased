import Foundation
import CoreLocation
import Combine

class ARExperienceManager: ObservableObject {
    @Published var isReady = false
    @Published var nearestLogoDistance: Double?
    @Published var visibleLogos: [LogoLocation] = []
    
    func updateNearestLogoDistance(userLocation: CLLocation) {
        let distances = LogoLocation.predefinedLocations.map { location in
            userLocation.distance(from: CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
        }
        nearestLogoDistance = distances.min()
    }
}
