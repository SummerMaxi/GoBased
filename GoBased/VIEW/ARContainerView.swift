import SwiftUI

struct ARContainerView: View {
    @StateObject private var arExperience = ARExperienceManager()
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            ARViewRepresentable()
                .environmentObject(arExperience)
                .environmentObject(locationManager)
            
            // Display distance to logo if available
            if let userLocation = locationManager.location,
               let logoLocation = arExperience.logoLocation {
                VStack {
                    let distance = userLocation.distance(from: logoLocation)
                    Text(String(format: "Distance to logo: %.1f meters", distance))
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .ignoresSafeArea()
    }
}
