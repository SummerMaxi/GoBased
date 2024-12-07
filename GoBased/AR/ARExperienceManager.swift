// ARExperienceManager.swift
import Foundation
import CoreLocation
import Combine

class ARExperienceManager: ObservableObject {
    @Published var isReady = false
    @Published var logoLocation: CLLocation?
    
    init() {
        isReady = true
    }
}
