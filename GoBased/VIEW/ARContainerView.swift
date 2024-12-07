import SwiftUI
import RealityKit
import Photos
import AVFoundation

struct ARContainerView: View {
    @StateObject private var arExperience = ARExperienceManager()
    @State private var showDebugInfo = false
    @State private var showCameraAlert = false
    @State private var lastCaptureDate: Date? = nil
    @State private var showPhotoSavedAlert = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        ZStack {
            // AR View
            ARViewRepresentable()
                .environmentObject(arExperience)
                .ignoresSafeArea()
            
            // Overlay Content
            VStack {
                // Top Counter
                Text("Collected: \(arExperience.collectedCount)/\(arExperience.totalLogos)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 44)
                
                // Debug Info Panel
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
                }
                
                Spacer()
                
                // Bottom Control Bar
                HStack(spacing: 25) {
                    // Debug Info Toggle
                    Button(action: { showDebugInfo.toggle() }) {
                        Image(systemName: showDebugInfo ? "info.circle.fill" : "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    // Camera Button
                    Button(action: {
                        if let coordinator = (UIApplication.shared.windows.first?.rootViewController?.view as? ARView)?.session.delegate as? ARViewRepresentable.Coordinator {
                            coordinator.captureSelfie()
                        }
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevents tab navigation
                    
                    // Wallet Button
                    Button(action: {
                        if !walletManager.isConnected {
                            walletManager.connectWallet()
                        }
                    }) {
                        Image(systemName: walletManager.isConnected ? "wallet.pass.fill" : "wallet.pass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(25)
                .padding(.bottom, 90) // Increased to account for TabView
                .padding(.horizontal)
            }
            
            // Flash Effect Overlay
            if showCameraAlert {
                Color.white
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Success Message Overlay
            if showPhotoSavedAlert {
                Text("Photo saved!")
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .top))
                    .position(x: UIScreen.main.bounds.width/2, y: 100)
            }
            
            // Error Message Overlay
            if let error = errorMessage {
                Text(error)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .top))
                    .position(x: UIScreen.main.bounds.width/2, y: 100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            errorMessage = nil
                        }
                    }
            }
        }
        .onAppear {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
    }
    
    private func takeSelfie() {
        // Check cooldown
        if let lastCapture = lastCaptureDate,
           Date().timeIntervalSince(lastCapture) < 2.0 {
            return
        }
        
        // Request photo permission and take photo
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    if let coordinator = (UIApplication.shared.windows.first?.rootViewController?.view as? ARView)?.session.delegate as? ARViewRepresentable.Coordinator {
                        coordinator.captureSelfie()
                        lastCaptureDate = Date()
                        
                        // Show flash effect
                        withAnimation {
                            showCameraAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showCameraAlert = false
                            }
                        }
                        
                        // Show success message
                        withAnimation {
                            showPhotoSavedAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showPhotoSavedAlert = false
                            }
                        }
                    }
                } else {
                    errorMessage = "Please enable photo library access in Settings"
                }
            }
        }
    }
}

#if DEBUG
struct ARContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ARContainerView()
            .environmentObject(WalletManager())
    }
}
#endif
