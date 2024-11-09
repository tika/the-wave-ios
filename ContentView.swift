import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        Map(Annotation(coordinateRegion: $locationManager.region, showsUserLocation: true)) {
            // Custom marker at user's location
            if let location = locationManager.lastLocation {
                Marker("Current Location", coordinate: location.coordinate)
                    .tint(.blue)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
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
