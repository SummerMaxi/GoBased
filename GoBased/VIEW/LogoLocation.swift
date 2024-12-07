// LogoLocation.swift
import CoreLocation

struct LogoLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    
    static let predefinedLocations: [LogoLocation] = [
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979747, longitude: 77.718440)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979549, longitude: 77.718523)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979508, longitude: 77.719004)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.980024, longitude: 77.718541)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979389, longitude: 77.719326)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979883, longitude: 77.719426)),
        LogoLocation(coordinate: CLLocationCoordinate2D(latitude: 12.979732, longitude: 77.718686))
    ]
}
