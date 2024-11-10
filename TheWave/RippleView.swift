//
//  RippleView.swift
//  TheWave
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI
import MapKit

struct RippleView: MapContent {
    @State private var isAnimating = false
    let population: Int
    let color: Color
    let position: CLLocationCoordinate2D
    
    // Based on the population, let's change the size
    var rippleScale: Double {
        10 * log(Double(population)) + 50
    }
    
    var body: some MapContent {
        MapCircle(center: position, radius: rippleScale)
            .foregroundStyle(color.opacity(0.5))
            .mapOverlayLevel(level: .aboveRoads)
    }
}

#Preview {
    Map() {
        RippleView(population: 5, color: .red, position: CLLocationCoordinate2D(latitude: 5, longitude: 5))
    }
}
