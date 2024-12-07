import Foundation

struct LogoLocation: Identifiable {
    let id = UUID()
    let position: SIMD3<Float>
    let url: String
    
    static let predefinedLocations: [LogoLocation] = generateRandomLocations(count: 15)
    
    static func generateRandomLocations(count: Int) -> [LogoLocation] {
        var locations: [LogoLocation] = []
        
        // Define the list of URLs
        let urls = [
            "https://portal.cdp.coinbase.com/quest",
            "https://www.basefairy.xyz/",
            "https://www.base.org/names"
        ]
        
        for _ in 0..<count {
            // Generate random angles and distance
            let angle = Float.random(in: 0...(2 * .pi))
            let distance = Float.random(in: 8...80)     // Increased distance range
            let height = Float.random(in: 0.5...6)    // Adjusted height range
            
            // Convert polar coordinates to Cartesian coordinates
            let x = distance * sin(angle)
            let z = -distance * cos(angle)
            
            let position = SIMD3<Float>(x, height, z)
            
            // Randomly select a URL from the list
            let randomURL = urls.randomElement() ?? urls[0]
            
            locations.append(LogoLocation(
                position: position,
                url: randomURL
            ))
        }
        
        return locations
    }
    
    func debugDescription() -> String {
        return String(format: "Logo at: %.1fm right, %.1fm up, %.1fm forward",
                     position.x, position.y, -position.z)
    }
}
