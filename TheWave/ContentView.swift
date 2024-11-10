import SwiftUI
import MapKit
import CoreLocation

class RippleState: ObservableObject {
    static let shared = RippleState()
    
    @Published var rippleLocations: [RippleLocation] = []
    @Published var lastError: String?
}

// Request models remain the same
struct LocationRequest: Codable {
    let userID: String
    let location: CoordinateData
    let partyMode: Bool
}

// The actual ripple
struct RippleDaata: Codable {
    let _id: String
    let members: [String]
    let origin: RippleOrigin
}

// The ripple response
struct RippleData: Codable {
    let message: String
    let nearbyRipples: [RippleDaata]
    let ripple_id: String?  // Optional since it's not always present
}

struct RippleOrigin: Codable {
    let coordinates: [Double]
    let type: String
}

struct CoordinateData: Codable {
    let longitude: Double
    let latitude: Double
}

// Display model
struct RippleLocation: Identifiable, Decodable {
    let id: String
    let coordinate: CLLocationCoordinate2D

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        let origin = try container.decode(RippleOrigin.self, forKey: .origin)
        self.coordinate = CLLocationCoordinate2D(
            latitude: origin.coordinates[0],
            longitude: origin.coordinates[1]
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case origin
    }

    init(id: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

//struct Location: Identifiable {
//    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//
//    init(from response: LocationResponse) {
//        self.coordinate = response.coordinate
//    }
//}

let apiBaseURL = "https://the-wave-backend.onrender.com/api/location"

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
        @StateObject private var rippleState = RippleState.shared
        @AppStorage("isPartyModeEnabled") private var isPartyModeEnabled = false
        @State private var path = NavigationPath()

        let METRES_PAN = 5000.0

        var userLocation: CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: locationManager.lastLocation?.coordinate.latitude ?? 0 + (METRES_PAN * 0.001),
                longitude: locationManager.lastLocation?.coordinate.longitude ?? 0 + (METRES_PAN * 0.001)
            )
        }

        var body: some View {
            NavigationStack(path: $path) {
                Map(
                    bounds: MapCameraBounds(
                        centerCoordinateBounds: MKMapRect(
                            origin: MKMapPoint(userLocation),
                            size: MKMapSize(width: METRES_PAN * 2, height: METRES_PAN * 2)
                        ),
                        minimumDistance: 100,
                        maximumDistance: 1000
                    )
                ) {
                    // Now use rippleState.rippleLocations
                    ForEach(rippleState.rippleLocations) { location in
                        RippleView(population: 1, color: .red, position: location.coordinate)
                    }
                }
                .mapStyle(.standard(pointsOfInterest: []))
                .ignoresSafeArea()
                .overlay(
                    VStack {
                        Text("Lat: \(locationManager.lastLocation?.coordinate.latitude ?? 0), Lon: \(locationManager.lastLocation?.coordinate.longitude ?? 0)")
                            .padding()
                            .background(.white.opacity(0.7))
                            .cornerRadius(10)

                        if let error = rippleState.lastError {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: InfoView()) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onReceive(locationManager.$lastLocation) { location in
                if let location = location {
                    Task {
                        await ContentView.sendLocationUpdate(location: location, partyMode: isPartyModeEnabled)
                    }
                }
            }
        }
    }


    static func sendLocationUpdate(location: CLLocation, partyMode: Bool) async {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
            let timestamp = dateFormatter.string(from: Date())
            print("📍 [\(timestamp)] Sending location update - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")

            guard let url = URL(string: apiBaseURL) else { return }

            let requestBody = LocationRequest(
                userID: LocationManager.deviceID,
                location: CoordinateData(
                    longitude: location.coordinate.longitude,
                    latitude: location.coordinate.latitude
                ),
                partyMode: partyMode
            )

            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(LocationManager.deviceID, forHTTPHeaderField: "userID")

                let jsonData = try JSONEncoder().encode(requestBody)
                request.httpBody = jsonData

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status:", httpResponse.statusCode)
                }
                print("Response data:", String(data: data, encoding: .utf8) ?? "")

                let locations = try JSONDecoder().decode(RippleData.self, from: data)
                    .nearbyRipples.map { ripple in
                        RippleLocation(id: ripple._id, coordinate: CLLocationCoordinate2D(
                            latitude: ripple.origin.coordinates[0],
                            longitude: ripple.origin.coordinates[1]
                        ))
                    }
                print("Decoded \(locations.count) locations")

                await MainActor.run {
                    RippleState.shared.rippleLocations = locations
                    RippleState.shared.lastError = nil
                    print("Updated rippleLocations count: \(RippleState.shared.rippleLocations.count)")
                }
            } catch {
                print("Error sending location update: \(error)")
                await MainActor.run {
                    RippleState.shared.rippleLocations = []
                    RippleState.shared.lastError = "Error: \(error.localizedDescription)"
                }
            }
        }
}

// The settings tab
struct SettingsView: View {
    @AppStorage("isPartyModeEnabled") private var isPartyModeEnabled = false
    @AppStorage("areNotificationsEnabled") private var areNotificationsEnabled = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle("Party Mode", isOn: $isPartyModeEnabled)
                    .onChange(of: isPartyModeEnabled) {
                        oldValue, newValue in
                    }
            } footer: {
                Text("Party mode allows you to join ripples")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Section {
                Toggle("Notifications", isOn: $areNotificationsEnabled)
                    .onChange(of: areNotificationsEnabled) {
                        oldValue, newValue in
                        if newValue {
                            requestNotificationPermissions()
                        }
                        else {
                            revokeNotificationPermissions()
                        }
                    }
            } footer: {
                Text("You will receive notifications when near ripples")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Section {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }

            Section {
                NavigationLink("Terms of Service") {
                    Text("Terms of Service Content")
                }

                NavigationLink("Privacy Policy") {
                    Text("Privacy Policy Content")
                }
            }

            // Static version number at the bottom
            Section {
                Text("Version 1.0")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Settings")
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Add delete account logic here
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}

private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
        if let error = error {
            print("Error requesting notifications: \(error)")
        }
    }
}

private func revokeNotificationPermissions() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        Task { @MainActor in
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// The info tab
struct InfoView: View {
    var body: some View {
        Form {
            Section(header: Text("About The Wave")) {
                Text("The Wave is a social discovery app that helps you find and connect with people around you through digital ripples.")
                    .padding(.vertical, 8)
            }

            Section(header: Text("How It Works")) {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "location.circle.fill",
                           title: "Location Sharing",
                           description: "Share your location to create ripples that others can see")

                    InfoRow(icon: "wave.3.right",
                           title: "Ripples",
                           description: "See ripples from other users in your area")

                    InfoRow(icon: "bell.fill",
                           title: "Notifications",
                           description: "Get notified when you're near other users' ripples")
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Contact")) {
                Link("Email Support", destination: URL(string: "mailto:support@thewaveapp.com")!)
                Link("Twitter", destination: URL(string: "https://twitter.com/thewaveapp")!)
                Link("Website", destination: URL(string: "https://thewaveapp.com")!)
            }

            Section {
                Text("Made in HackUMass 2024")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Information")
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    static var deviceID: String {
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
