import SwiftUI
import ARKit
import RealityKit
import Photos

struct ARContainerView: View {
    @StateObject private var arExperience = ARExperienceManager()
    @EnvironmentObject var walletManager: WalletManager
    @State private var showCameraAlert = false
    @State private var showPhotoSavedAlert = false
    @State private var errorMessage: String? = nil
    @State private var isCapturingPhoto = false
    @State private var isFrontCamera = false
    
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
                
                Spacer()
                
                // Bottom Control Bar
                HStack(spacing: 25) {
                    // Debug Info Button
                    Button(action: {
                        arExperience.toggleDebugInfo()
                    }) {
                        Image(systemName: arExperience.showDebugInfo ? "info.circle.fill" : "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    // Camera Button
                    Button(action: {
                        capturePhoto()
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .disabled(isCapturingPhoto)
                    
                    // Camera Switch Button
                    Button(action: {
                        toggleCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
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
                .padding(.bottom, 50)
            }
            
            // Flash Effect
            if showCameraAlert {
                Color.white
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Photo Saved Alert
            if showPhotoSavedAlert {
                VStack {
                    Text("Photo saved!")
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .position(x: UIScreen.main.bounds.width/2, y: 100)
                .transition(.move(edge: .top))
            }
            
            // Error Message
            if let error = errorMessage {
                VStack {
                    Text(error)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .position(x: UIScreen.main.bounds.width/2, y: 100)
                .transition(.move(edge: .top))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        errorMessage = nil
                    }
                }
            }
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Helper Methods
    private func checkPermissions() {
        // Check camera permission
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DispatchQueue.main.async {
                    errorMessage = "Camera access is required for AR features"
                }
            }
        }
        
        // Check photo library permission
        PHPhotoLibrary.requestAuthorization { status in
            if status != .authorized {
                DispatchQueue.main.async {
                    errorMessage = "Photo library access is required to save captures"
                }
            }
        }
    }
    
    private func capturePhoto() {
        guard !isCapturingPhoto else { return }
        
        isCapturingPhoto = true
        showCameraAlert = true
        
        // Simulate flash effect
        withAnimation(.easeInOut(duration: 0.2)) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCameraAlert = false
                
                // Capture photo using coordinator
                if let arView = UIApplication.shared.windows.first?.rootViewController?.view as? ARView,
                   let coordinator = arView.session.delegate as? ARViewRepresentable.Coordinator {
                    coordinator.captureSelfie { success in
                        DispatchQueue.main.async {
                            isCapturingPhoto = false
                            if success {
                                showPhotoSavedAlert = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showPhotoSavedAlert = false
                                }
                            } else {
                                errorMessage = "Failed to save photo"
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func toggleCamera() {
        isFrontCamera.toggle()
        // Implement camera switch logic here
        // This will require additional implementation in ARViewRepresentable
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ARContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ARContainerView()
            .environmentObject(WalletManager())
    }
}
#endif
