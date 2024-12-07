import SwiftUI
import ARKit
import RealityKit
import SafariServices

struct ARViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var arExperience: ARExperienceManager
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewRepresentable
        var arView: ARView?
        var logoEntities: [UUID: Entity] = [:]
        
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
        
        func placeLogo(at location: LogoLocation) {
            guard let arView = arView else { return }
            
            let anchor = AnchorEntity()
            
            if let modelEntity = try? ModelEntity.load(named: "baselogo.usdz") {
                modelEntity.position = location.position
                modelEntity.scale = SIMD3<Float>(repeating: 0.15) // Reduced size to 0.15
                modelEntity.generateCollisionShapes(recursive: true)
                modelEntity.setValue(location.url, forKey: "mintingURL")
                
                // Create slower, smoother rotation
                let rotationDuration: TimeInterval = 12.0 // Increased duration for slower rotation
                
                // Start continuous rotation using Timer with smaller increments
                Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak modelEntity] timer in
                    guard let entity = modelEntity else {
                        timer.invalidate()
                        return
                    }
                    
                    let rotationAngle = Float(Date().timeIntervalSince1970).remainder(dividingBy: Float(rotationDuration)) * (2 * .pi / Float(rotationDuration))
                    
                    // Smooth rotation transition
                    let currentRotation = entity.orientation
                    let targetRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                    
                    // Interpolate between current and target rotation
                    let smoothFactor: Float = 0.05 // Lower value = smoother transition
                    let smoothedRotation = simd_slerp(currentRotation, targetRotation, smoothFactor)
                    
                    entity.orientation = smoothedRotation
                }
                
                anchor.addChild(modelEntity)
                logoEntities[location.id] = modelEntity
            }
            
            arView.scene.addAnchor(anchor)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            if let hitEntity = arView.entity(at: location) {
                for (id, logoEntity) in logoEntities {
                    if hitEntity == logoEntity || hitEntity.isDescendant(of: logoEntity) {
                        if let urlString = logoEntity.getValue(forKey: "mintingURL") as? String,
                           let url = URL(string: urlString) {
                            
                            // Animate the logo disappearing
                            var transform = logoEntity.transform
                            transform.scale = .zero
                            
                            // Create disappearing animation
                            logoEntity.move(to: transform, relativeTo: logoEntity.parent, duration: 0.5)
                            
                            // Remove the entity after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                logoEntity.removeFromParent()
                                self?.logoEntities.removeValue(forKey: id)
                                
                                // Update the collected count
                                DispatchQueue.main.async {
                                    self?.parent.arExperience.incrementCollected()
                                }
                            }
                            
                            // Open the URL
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        arView.session.run(config)
        context.coordinator.setupARView()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

extension Entity {
    func isDescendant(of entity: Entity) -> Bool {
        var current = self.parent
        while let parent = current {
            if parent == entity {
                return true
            }
            current = parent.parent
        }
        return false
    }
    
    private static var propertyKey: UInt8 = 0
    
    func setValue(_ value: Any?, forKey key: String) {
        var dictionary = objc_getAssociatedObject(self, &Entity.propertyKey) as? [String: Any] ?? [:]
        dictionary[key] = value
        objc_setAssociatedObject(self, &Entity.propertyKey, dictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func getValue(forKey key: String) -> Any? {
        let dictionary = objc_getAssociatedObject(self, &Entity.propertyKey) as? [String: Any]
        return dictionary?[key]
    }
}
