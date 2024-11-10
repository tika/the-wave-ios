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
        population == 1 ? 5 : (10 * Double(population) + 50)
    }

    var body: some MapContent {
        MapCircle(center: position, radius: rippleScale * 0.5 * animator.scale1 + 20)
            .foregroundStyle(color.opacity(0.5))
            .mapOverlayLevel(level: .aboveRoads)
    }
}

class RippleAnimator: ObservableObject {
    @Published var scale1: Double = 0.5
    @Published var scale2: Double = 0.5
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            self?.updateScales()
        }
    }

    private func updateScales() {
        scale1 += 0.02
        scale2 += 0.02

        if scale1 >= 2.0 {
            scale1 = 0.5
        }
        if scale2 >= 2.0 {
            scale2 = 0.5
        }
    }

    deinit {
        timer?.invalidate()
    }
}

#Preview {
    Map {
        RippleView(population: 5, color: .red, position: CLLocationCoordinate2D(latitude: 5, longitude: 5))
    }
    .mapStyle(.standard)
}
