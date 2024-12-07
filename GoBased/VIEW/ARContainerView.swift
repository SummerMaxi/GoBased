import SwiftUI

struct ARContainerView: View {
    @StateObject private var arExperience = ARExperienceManager()
    @State private var showDebugInfo = false
    
    var body: some View {
        ZStack {
            ARViewRepresentable()
                .environmentObject(arExperience)
                .ignoresSafeArea()
            
            VStack {
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Logo Positions:")
                            .font(.headline)
                        
                        ForEach(LogoLocation.predefinedLocations) { logo in
                            Text(logo.debugDescription())
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Text("Find and tap on logos to mint NFTs")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 44)
            
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
    }
}
