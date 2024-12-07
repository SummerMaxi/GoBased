import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var arExperience: ARExperienceManager
    @EnvironmentObject var locationManager: LocationManager
    
    class Coordinator: NSObject {
        var parent: ARViewRepresentable
        var arView: ARView?
        var logoAnchor: AnchorEntity?
        var debugSpheres: [Entity] = []
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
        }
        
        func updateLogoPosition(userLocation: CLLocation) {
            guard let logoLocation = parent.arExperience.logoLocation else { return }
            let arPosition = parent.translateGPSToARPosition(userLocation: userLocation,
                                                           logoLocation: logoLocation)
            logoAnchor?.position = arPosition
            updateDebugMarkers(at: arPosition)
        }
        
        func updateDebugMarkers(at position: SIMD3<Float>) {
            // Remove old debug markers
            debugSpheres.forEach { $0.removeFromParent() }
            debugSpheres.removeAll()
            
            guard let arView = arView else { return }
            
            // Add debug sphere at logo position
            let sphereMesh = MeshResource.generateSphere(radius: 0.2) // Smaller radius
            let sphereMaterial = SimpleMaterial(color: .red, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
            sphereEntity.position = position
            
            // Add vertical pole (cylinder) from ground to logo
            let poleHeight = position.y
            let poleMesh = MeshResource.generateCylinder(height: poleHeight, radius: 0.02)
            let poleMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let poleEntity = ModelEntity(mesh: poleMesh, materials: [poleMaterial])
            poleEntity.position = SIMD3<Float>(position.x, poleHeight/2, position.z)
            
            // Add ground marker (larger flat cylinder)
            let groundMarkerMesh = MeshResource.generateCylinder(height: 0.02, radius: 0.3)
            let groundMarkerMaterial = SimpleMaterial(color: .green, isMetallic: false)
            let groundMarkerEntity = ModelEntity(mesh: groundMarkerMesh, materials: [groundMarkerMaterial])
            groundMarkerEntity.position = SIMD3<Float>(position.x, 0.01, position.z)
            
            // Add directional arrows every 1 meter for close range
            let distance = sqrt(position.x * position.x + position.z * position.z)
            let steps = max(Int(distance), 5) // Ensure at least 5 markers
            for i in 1...steps {
                let ratio = Float(i) / Float(steps)
                let arrowPosition = SIMD3<Float>(
                    position.x * ratio,
                    0.5,
                    position.z * ratio
                )
                let arrowEntity = createArrowMarker()
                arrowEntity.position = arrowPosition
                
                // Point arrow towards logo
                let angle = atan2(position.x, position.z)
                arrowEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
                
                let anchor = AnchorEntity(world: arrowPosition)
                anchor.addChild(arrowEntity)
                arView.scene.addAnchor(anchor)
                debugSpheres.append(anchor)
            }
            
            // Add boundary markers (create a box around the logo)
            let boxSize: Float = 1.0
            for x in [-boxSize, boxSize] {
                for z in [-boxSize, boxSize] {
                    let cornerPosition = SIMD3<Float>(
                        position.x + x,
                        position.y,
                        position.z + z
                    )
                    let cornerMarker = createCornerMarker()
                    cornerMarker.position = cornerPosition
                    let cornerAnchor = AnchorEntity(world: cornerPosition)
                    cornerAnchor.addChild(cornerMarker)
                    arView.scene.addAnchor(cornerAnchor)
                    debugSpheres.append(cornerAnchor)
                }
            }
            
            // Add all markers to scene
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(sphereEntity)
            anchor.addChild(poleEntity)
            anchor.addChild(groundMarkerEntity)
            arView.scene.addAnchor(anchor)
            debugSpheres.append(anchor)
            
            // Add distance text
            let textEntity = createDistanceMarker(distance: distance)
            textEntity.position = position + SIMD3<Float>(0, 0.3, 0)
            let textAnchor = AnchorEntity(world: textEntity.position)
            textAnchor.addChild(textEntity)
            arView.scene.addAnchor(textAnchor)
            debugSpheres.append(textAnchor)
        }
        
        private func createCornerMarker() -> ModelEntity {
            let cornerMesh = MeshResource.generateSphere(radius: 0.05)
            let cornerMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            return ModelEntity(mesh: cornerMesh, materials: [cornerMaterial])
        }
        
        private func createArrowMarker() -> ModelEntity {
            let arrowMesh = MeshResource.generateBox(size: [0.2, 0.2, 0.4])
            let arrowMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            return ModelEntity(mesh: arrowMesh, materials: [arrowMaterial])
        }
        
        private func createDistanceMarker(distance: Float) -> ModelEntity {
            let text = MeshResource.generateText(
                "\(Int(distance))m",
                extrusionDepth: 0.1,
                font: .systemFont(ofSize: 1.0),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: text, materials: [textMaterial])
            textEntity.scale = SIMD3<Float>(repeating: 0.3)
            
            return textEntity
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.worldAlignment = .gravity
        
        // Run session
        arView.session.run(config)
        
        // Place logo when we have initial location
        if let userLocation = locationManager.location {
            placeLogo(in: arView, userLocation: userLocation, coordinator: context.coordinator)
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update logo position when user location changes
        if let userLocation = locationManager.location {
            context.coordinator.updateLogoPosition(userLocation: userLocation)
        }
    }
    
    private func placeLogo(in arView: ARView, userLocation: CLLocation, coordinator: Coordinator) {
        guard let modelEntity = try? ModelEntity.load(named: "baselogo.usdz") else {
            print("Failed to load model")
            return
        }
        
        // Calculate logo position 5 meters north of user
        let logoLocation = calculateLogoLocation(from: userLocation, distanceMeters: 5)
        
        // Convert GPS coordinates to AR world coordinates
        let arPosition = translateGPSToARPosition(userLocation: userLocation,
                                                logoLocation: logoLocation)
        
        // Set fixed size - make it smaller for closer viewing
        let targetHeight: Float = 1.0  // Reduced from 1.7 to 1.0 meters
        let bounds = modelEntity.visualBounds(relativeTo: nil)
        let currentHeight = bounds.max.y - bounds.min.y
        let scale = targetHeight / currentHeight
        modelEntity.scale = SIMD3<Float>(repeating: scale)
        
        // Adjust height to be at eye level
        let adjustedPosition = SIMD3<Float>(arPosition.x, 1.6, arPosition.z) // Set to approximate eye level
        
        // Create anchor and add logo
        let anchor = AnchorEntity()
        anchor.position = adjustedPosition
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        
        // Store anchor reference
        coordinator.logoAnchor = anchor
        
        // Add debug markers
        coordinator.updateDebugMarkers(at: adjustedPosition)
        
        // Save logo's GPS location
        arExperience.logoLocation = logoLocation
        print("Logo placed at GPS: \(logoLocation.coordinate), AR Position: \(adjustedPosition)")
    }
    
    private func calculateLogoLocation(from userLocation: CLLocation,
                                     distanceMeters: Double) -> CLLocation {
        // Calculate location 50 meters north of user
        let earth = 6378137.0 // Earth's radius in meters
        let lat1 = userLocation.coordinate.latitude * .pi / 180
        let lon1 = userLocation.coordinate.longitude * .pi / 180
        let distance = distanceMeters
        
        // Calculate new latitude (moving north)
        let lat2 = lat1 + (distance / earth)
        
        // Convert back to degrees
        let newLat = lat2 * 180 / .pi
        
        return CLLocation(latitude: newLat,
                         longitude: userLocation.coordinate.longitude)
    }
    
    private func translateGPSToARPosition(userLocation: CLLocation,
                                        logoLocation: CLLocation) -> SIMD3<Float> {
        // Calculate distance and bearing between points
        let distance = Float(userLocation.distance(from: logoLocation))
        let bearing = getBearing(from: userLocation, to: logoLocation)
        
        // Convert polar coordinates (distance, bearing) to Cartesian (x, z)
        let x = distance * sin(bearing)
        let z = -distance * cos(bearing) // Negative because AR-Z is opposite to North
        
        return SIMD3<Float>(x, 0.85, z) // 0.85m above ground
    }
    
    private func getBearing(from: CLLocation, to: CLLocation) -> Float {
        let lat1 = from.coordinate.latitude * .pi / 180
        let lon1 = from.coordinate.longitude * .pi / 180
        let lat2 = to.coordinate.latitude * .pi / 180
        let lon2 = to.coordinate.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return Float(bearing)
    }
}

