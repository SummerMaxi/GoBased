import SwiftUI
import ARKit
import RealityKit
import Photos

struct ARViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var arExperience: ARExperienceManager
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewRepresentable
        var arView: ARView?
        var logoEntities: [UUID: Entity] = [:]
        private var frontCameraSession: AVCaptureSession?
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        func setupARView() {
            guard let arView = arView else { return }
            
            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            arView.addGestureRecognizer(tapGesture)
            
            // Place logos in predefined positions
            for location in LogoLocation.predefinedLocations {
                placeLogo(at: location)
            }
        }
        
        // MARK: - Camera Setup
        private func setupFrontCamera() -> AVCaptureSession? {
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("❌ Could not find front camera")
                return nil
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    return session
                }
            } catch {
                print("❌ Error setting up front camera: \(error)")
            }
            return nil
        }
        
        // MARK: - Logo Placement
        private func placeLogo(at location: LogoLocation) {
            guard let arView = arView else { return }
            
            let anchor = AnchorEntity()
            
            if let modelEntity = try? ModelEntity.load(named: "baselogo.usdz") {
                modelEntity.position = location.position
                modelEntity.scale = SIMD3<Float>(repeating: 0.15)
                modelEntity.generateCollisionShapes(recursive: true)
                modelEntity.setValue(location.url, forKey: "mintingURL")
                
                // Create rotation animation
                let rotationDuration: TimeInterval = 12.0
                Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak modelEntity] timer in
                    guard let entity = modelEntity else {
                        timer.invalidate()
                        return
                    }
                    
                    let rotationAngle = Float(Date().timeIntervalSince1970).remainder(dividingBy: Float(rotationDuration)) * (2 * .pi / Float(rotationDuration))
                    let currentRotation = entity.orientation
                    let targetRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                    let smoothFactor: Float = 0.05
                    entity.orientation = simd_slerp(currentRotation, targetRotation, smoothFactor)
                }
                
                anchor.addChild(modelEntity)
                logoEntities[location.id] = modelEntity
            }
            
            arView.scene.addAnchor(anchor)
        }
        
        // MARK: - Tap Handling
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            if let hitEntity = arView.entity(at: location) {
                for (id, logoEntity) in logoEntities {
                    if hitEntity == logoEntity || hitEntity.isDescendant(of: logoEntity) {
                        if let urlString = logoEntity.getValue(forKey: "mintingURL") as? String,
                           let url = URL(string: urlString) {
                            
                            // Animate logo disappearance
                            var transform = logoEntity.transform
                            transform.scale = .zero
                            logoEntity.move(to: transform, relativeTo: logoEntity.parent, duration: 0.5)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                logoEntity.removeFromParent()
                                self?.logoEntities.removeValue(forKey: id)
                                
                                // Update collected count
                                DispatchQueue.main.async {
                                    self?.parent.arExperience.incrementCollected()
                                }
                            }
                            
                            // Open URL
                            DispatchQueue.main.async {
                                let safariVC = SFSafariViewController(url: url)
                                UIApplication.shared.windows.first?.rootViewController?.present(safariVC, animated: true)
                            }
                        }
                        break
                    }
                }
            }
        }
        
        // MARK: - Photo Capture
        func captureSelfie(completion: @escaping (Bool) -> Void) {
            guard let arView = arView else {
                completion(false)
                return
            }
            
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                guard status == .authorized else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    UIGraphicsBeginImageContextWithOptions(arView.bounds.size, true, UIScreen.main.scale)
                    arView.drawHierarchy(in: arView.bounds, afterScreenUpdates: true)
                    
                    if let image = UIGraphicsGetImageFromCurrentImageContext() {
                        UIGraphicsEndImageContext()
                        
                        // Save to photo library
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    print("✅ Photo saved successfully")
                                    completion(true)
                                } else {
                                    print("❌ Failed to save photo: \(error?.localizedDescription ?? "Unknown error")")
                                    completion(false)
                                }
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        // Enable auto focus
        if let camera = arView.session.configuration?.videoFormat.captureDevice() {
            try? camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            camera.unlockForConfiguration()
        }
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        context.coordinator.setupARView()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
