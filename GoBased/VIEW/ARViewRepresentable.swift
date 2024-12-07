import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var arExperience: ARExperienceManager
    @EnvironmentObject var locationManager: LocationManager
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewRepresentable
        var arView: ARView?
        var logoAnchors: [UUID: AnchorEntity] = [:]
        var debugMarkers: [UUID: [Entity]] = [:]
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR Session failed: \(error)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR Session interruption ended")
            
            // Reload logos when session resumes
            if let userLocation = parent.locationManager.location,
               let arView = self.arView {
                parent.placeLogos(in: arView, userLocation: userLocation, coordinator: self)
            }
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            // Get tap location
            let location = recognizer.location(in: arView)
            
            // Perform hit test
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // Add a debug sphere at tap location
                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1),
                                      materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                anchor.addChild(sphere)
                arView.scene.addAnchor(anchor)
                
                print("🎯 Tapped at world position: \(firstResult.worldTransform.columns.3)")
            }
        }
        
        func updateLogoPositions(userLocation: CLLocation) {
            for location in LogoLocation.predefinedLocations {
                let logoLocation = CLLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                let arPosition = parent.translateGPSToARPosition(
                    userLocation: userLocation,
                    logoLocation: logoLocation
                )
                
                if let anchor = logoAnchors[location.id] {
                    anchor.position = arPosition
                    updateDebugMarkers(for: location.id, at: arPosition)
                }
            }
        }
        
        func updateDebugMarkers(for id: UUID, at position: SIMD3<Float>) {
            debugMarkers[id]?.forEach { $0.removeFromParent() }
            debugMarkers[id]?.removeAll()
            
            guard let arView = arView else { return }
            var markers: [Entity] = []
            
            // Add sphere at logo position
            let sphereMesh = MeshResource.generateSphere(radius: 0.2)
            let sphereMaterial = SimpleMaterial(color: .red, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
            sphereEntity.position = position
            
            // Add vertical pole
            let poleHeight = position.y
            let poleMesh = MeshResource.generateCylinder(height: poleHeight, radius: 0.02)
            let poleMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let poleEntity = ModelEntity(mesh: poleMesh, materials: [poleMaterial])
            poleEntity.position = SIMD3<Float>(position.x, poleHeight/2, position.z)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(sphereEntity)
            anchor.addChild(poleEntity)
            
            arView.scene.addAnchor(anchor)
            markers.append(anchor)
            
            debugMarkers[id] = markers
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
        config.worldAlignment = .gravityAndHeading // Use true north
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .tracking
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
        
        // Run session with error handling
        arView.session.delegate = context.coordinator
        do {
            try arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            print("✅ AR session started successfully")
        } catch {
            print("❌ Failed to start AR session: \(error)")
        }
        
        // Add tap gesture for debug purposes
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        if let userLocation = locationManager.location {
            placeLogos(in: arView, userLocation: userLocation, coordinator: context.coordinator)
            print("📍 Initial user location: \(userLocation.coordinate)")
        } else {
            print("⚠️ No initial user location available")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let userLocation = locationManager.location {
            context.coordinator.updateLogoPositions(userLocation: userLocation)
        }
    }
    
    private func placeLogos(in arView: ARView, userLocation: CLLocation, coordinator: Coordinator) {
        print("Current user location: \(userLocation.coordinate)")
        
        for location in LogoLocation.predefinedLocations {
            guard let modelEntity = try? ModelEntity.load(named: "baselogo.usdz") else {
                print("❌ Failed to load baselogo.usdz model")
                continue
            }
            
            let logoLocation = CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            let distance = userLocation.distance(from: logoLocation)
            print("📍 Logo at \(logoLocation.coordinate) is \(Int(distance))m away")
            
            let arPosition = translateGPSToARPosition(
                userLocation: userLocation,
                logoLocation: logoLocation
            )
            
            let targetHeight: Float = 3.0
            let bounds = modelEntity.visualBounds(relativeTo: nil)
            let currentHeight = bounds.max.y - bounds.min.y
            let scale = targetHeight / currentHeight
            modelEntity.scale = SIMD3<Float>(repeating: scale)
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity()
            anchor.position = arPosition
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            coordinator.logoAnchors[location.id] = anchor
            coordinator.updateDebugMarkers(for: location.id, at: arPosition)
            
            print("🎯 Placed logo at AR Position: x: \(arPosition.x), y: \(arPosition.y), z: \(arPosition.z)")
        }
    }
    
    private func translateGPSToARPosition(userLocation: CLLocation, logoLocation: CLLocation) -> SIMD3<Float> {
        let distance = Float(userLocation.distance(from: logoLocation))
        let bearing = getBearing(from: userLocation, to: logoLocation)
        
        print("📊 Distance: \(distance)m, Bearing: \(bearing) radians")
        
        let x = distance * sin(bearing)
        let z = -distance * cos(bearing)
        
        // Adjust height based on distance
        let y: Float = 1.6 // Eye level
        
        let position = SIMD3<Float>(x, y, z)
        print("🌍 Translated to AR position: \(position)")
        return position
    }
    
    private func getBearing(from: CLLocation, to: CLLocation) -> Float {
        let lat1 = Float(from.coordinate.latitude * .pi / 180)
        let lon1 = Float(from.coordinate.longitude * .pi / 180)
        let lat2 = Float(to.coordinate.latitude * .pi / 180)
        let lon2 = Float(to.coordinate.longitude * .pi / 180)
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return bearing
    }
}
