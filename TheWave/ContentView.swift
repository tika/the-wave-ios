//
//  ContentView.swift
//  The Wave
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D {
    static let newYork: Self = .init(
        latitude: 40.730610,
        longitude: -73.935242
    )
    
    static let seattle: Self = .init(
        latitude: 47.608013,
        longitude: -122.335167
    )
    
    static let sanFrancisco: Self = .init(
        latitude: 37.733795,
        longitude: -122.446747
    )
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        Map() {
            Annotation("Wave", coordinate: .newYork) {
                PulsatingCircleView(color: .blue)
            }
        }
        .ignoresSafeArea()
        .overlay(
            Text("Lat: \(locationManager.lastLocation?.coordinate.latitude ?? 0), Lon: \(locationManager.lastLocation?.coordinate.longitude ?? 0)")
                .padding()
                .background(.white.opacity(0.7))
                .cornerRadius(10)
                .padding(),
            alignment: .top
        )
    }
}

// Location Manager class to handle location updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Timer to log location every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let location = self?.lastLocation {
                print("Current Location - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        region.center = location.coordinate
    }
}
