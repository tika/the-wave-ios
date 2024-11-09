import SwiftUI
import MapKit
import CoreLocation

// Request models remain the same
struct LocationRequest: Codable {
    let userID: String
    let location: CoordinateData
    let preference: String
    let emoji: String
}

struct CoordinateData: Codable {
    let longitude: Double
    let latitude: Double
}

// New response model to match the API format
struct LocationResponse: Codable {
    let location: [Double]
    
    var coordinate: CLLocationCoordinate2D {
        // API sends [longitude, latitude]
        CLLocationCoordinate2D(
            latitude: location[1],
            longitude: location[0]
        )
    }
}

// Display model
struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    
    init(from response: LocationResponse) {
        self.coordinate = response.coordinate
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var otherLocations: [Location] = []
    @State private var lastError: String?
    
    let apiBaseURL = "http://127.0.0.1:5000/api/location"  // Make sure to update this
    
    var body: some View {
        Map() {
            // Show other users' locations
            ForEach(otherLocations) { location in
                Annotation("Other", coordinate: location.coordinate) {
                    Circle()
                        .fill((location.coordinate.latitude == locationManager.lastLocation?.coordinate.latitude && location.coordinate.longitude == locationManager.lastLocation?.coordinate.longitude) ? .red : .blue)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }
        }
        .ignoresSafeArea()
        .overlay(
            VStack {
                Text("Lat: \(locationManager.lastLocation?.coordinate.latitude ?? 0), Lon: \(locationManager.lastLocation?.coordinate.longitude ?? 0)")
                    .padding()
                    .background(.white.opacity(0.7))
                    .cornerRadius(10)
                
                if let error = lastError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(.white.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .padding(),
            alignment: .top
        )
        .onReceive(locationManager.$lastLocation) { location in
            if let location = location {
                Task {
                    await sendLocationUpdate(location: location)
                }
            }
        }
    }
    
    func sendLocationUpdate(location: CLLocation) async {
        guard let url = URL(string: apiBaseURL) else { return }
        
        let requestBody = LocationRequest(
            userID: locationManager.deviceID,
            location: CoordinateData(
                longitude: location.coordinate.longitude,
                latitude: location.coordinate.latitude
            ),
            preference: "test string",
            emoji: "test emoji"
        )
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(locationManager.deviceID, forHTTPHeaderField: "userID")
            
            let jsonData = try JSONEncoder().encode(requestBody)
            print("Sending request:", String(data: jsonData, encoding: .utf8) ?? "")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status:", httpResponse.statusCode)
            }
            print("Response data:", String(data: data, encoding: .utf8) ?? "")
            
            let locations = try JSONDecoder().decode([LocationResponse].self, from: data)
            print("Decoded \(locations.count) locations")
            
            await MainActor.run {
                otherLocations = locations.map { Location(from: $0) }
                lastError = nil
            }
            
        } catch {
            print("Error sending location update: \(error)")
            await MainActor.run {
                lastError = "Error: \(error.localizedDescription)"
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    
    var deviceID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
    }
}
