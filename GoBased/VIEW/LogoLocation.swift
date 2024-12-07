import Foundation

struct LogoLocation: Identifiable {
    let id = UUID()
    let position: SIMD3<Float>
    let url: String
    
    static let predefinedLocations: [LogoLocation] = generateRandomLocations(count: 10)
    
    static func generateRandomLocations(count: Int) -> [LogoLocation] {
        var locations: [LogoLocation] = []
        
        for i in 0..<count {
            // Generate random angles and distance
            let angle = Float.random(in: 0...(2 * .pi))
            let distance = Float.random(in: 3...15)
            let height = Float.random(in: 0...2)
            
            // Convert polar coordinates to Cartesian coordinates
            let x = distance * sin(angle)
            let z = -distance * cos(angle)
            
            let position = SIMD3<Float>(x, height, z)
            
            locations.append(LogoLocation(
                position: position,
                url: "https://your-minting-website.com/\(i + 1)"
            ))
        }
        
        return locations
    }
    
    func debugDescription() -> String {
        return String(format: "Logo at: %.1fm right, %.1fm up, %.1fm forward",
                     position.x, position.y, -position.z)
    }
}
