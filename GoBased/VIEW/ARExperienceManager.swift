//
//  ARExperienceManager.swift
//  GoBased
//
//  Created by NAVEEN on 07/12/24.
//


import Foundation
import CoreLocation
import Combine

final class ARExperienceManager: ObservableObject {
    @Published var isReady = false
    @Published var logoLocation: CLLocation?
    
    init() {
        isReady = true
    }
}
