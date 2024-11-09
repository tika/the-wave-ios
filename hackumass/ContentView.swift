//
//  ContentView.swift
//  hackumass
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI
import MapboxMaps

struct ContentView: View {
    
    var body: some View {
        let center = CLLocationCoordinate2D(latitude: 42.3909093, longitude: -72.6081182)
        Map(initialViewport: .camera(center: center, zoom: 5, bearing: 0, pitch: 0))
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
