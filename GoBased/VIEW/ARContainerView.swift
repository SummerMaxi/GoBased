import SwiftUI
import CoreLocation

struct ARContainerView: View {
    @StateObject private var arExperience = ARExperienceManager()
    @EnvironmentObject var locationManager: LocationManager
    @State private var showDebugInfo = true
    
    var body: some View {
        ZStack {
            ARViewRepresentable()
                .environmentObject(arExperience)
                .environmentObject(locationManager)
            
            if showDebugInfo {
                VStack {
                    if let userLocation = locationManager.location {
                        Text("📱 Your Location:")
                            .font(.caption)
                        Text("Lat: \(String(format: "%.6f", userLocation.coordinate.latitude))")
                            .font(.system(.caption, design: .monospaced))
                        Text("Lon: \(String(format: "%.6f", userLocation.coordinate.longitude))")
                            .font(.system(.caption, design: .monospaced))
                        Text("Accuracy: \(String(format: "%.1f", userLocation.horizontalAccuracy))m")
                            .font(.system(.caption, design: .monospaced))
                        
                        Divider()
                        
                        Text("🎯 Nearby Logos:")
                            .font(.caption)
                        ForEach(LogoLocation.predefinedLocations) { location in
                            let distance = userLocation.distance(from: CLLocation(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            ))
                            Text("\(Int(distance))m away")
                                .font(.system(.caption, design: .monospaced))
                        }
                    } else {
                        Text("Waiting for location...")
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            Button(action: { showDebugInfo.toggle() }) {
                Image(systemName: showDebugInfo ? "info.circle.fill" : "info.circle")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding()
        }
        .ignoresSafeArea()
    }
}
