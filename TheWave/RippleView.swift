//
//  RippleView.swift
//  TheWave
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI
import MapKit

struct RippleView: MapContent {
    @StateObject private var animator = RippleAnimator()
    let population: Int
    let color: Color
    let position: CLLocationCoordinate2D

    var rippleScale: Double {
        10 * log(Double(population)) + 5
    }

    var body: some MapContent {
        MapCircle(center: position, radius: rippleScale * animator.scale)
            .foregroundStyle(color.opacity(0.5))
            .mapOverlayLevel(level: .aboveRoads)
    }
}

class RippleAnimator: ObservableObject {
    @Published var scale: Double = 1.0
    private var timer: Timer?
    private var ascending = true

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateScale()
        }
    }

    private func updateScale() {
        if ascending {
            scale += 0.01
            if scale >= 1.3 { ascending = false }
        } else {
            scale -= 0.01
            if scale <= 0.7 { ascending = true }
        }
    }

    deinit {
        timer?.invalidate()
    }
}

#Preview {
    Map() {
        RippleView(population: 5, color: .red, position: CLLocationCoordinate2D(latitude: 5, longitude: 5))
    }
}
