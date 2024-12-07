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
            
            // Create anchor at the specified position
            let anchor = AnchorEntity()
            
            if let modelEntity = try? ModelEntity.load(named: "baselogo.usdz") {
                modelEntity.position = location.position
                modelEntity.scale = SIMD3<Float>(repeating: 0.3) // Adjust size as needed
                modelEntity.generateCollisionShapes(recursive: true)
                modelEntity.setValue(location.url, forKey: "mintingURL")
                
                // Add continuous rotation
                let rotationAngle = Float.pi * 2
                let duration: TimeInterval = 8.0 // 8 seconds per rotation
                
                // Create and start continuous rotation animation
                modelEntity.transform.rotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                
                // Using AsyncStream for continuous rotation
                Task {
                    while true {
                        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                        DispatchQueue.main.async {
                            modelEntity.transform.rotation = simd_quatf(
                                angle: rotationAngle,
                                axis: [0, 1, 0]
                            )
                        }
                    }
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
                for (_, logoEntity) in logoEntities {
                    if hitEntity == logoEntity || hitEntity.isDescendant(of: logoEntity) {
                        if let urlString = logoEntity.getValue(forKey: "mintingURL") as? String,
                           let url = URL(string: urlString) {
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
