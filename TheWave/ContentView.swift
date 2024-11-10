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

    @State private var path = NavigationPath()

    let apiBaseURL = "https://the-wave-backend.onrender.com/api/location"  // Make sure to update this

    let METRES_PAN = 5000.0;

    var userLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: locationManager.lastLocation?.coordinate.latitude ?? 0 + (METRES_PAN * 0.001), longitude: locationManager.lastLocation?.coordinate.longitude ?? 0 + (METRES_PAN * 0.001))
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
                // Show other users' locations
                ForEach(otherLocations) { location in
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
                        await sendLocationUpdate(location: location)
                    }
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

// The settings tab
struct SettingsView: View {
    @AppStorage("isGhostModeEnabled") private var isGhostModeEnabled = false
    @AppStorage("areNotificationsEnabled") private var areNotificationsEnabled = false
    @State private var showDeleteConfirmation = false
    

    var body: some View {
        Form {
            Section {
                Toggle("Ghost Mode", isOn: $isGhostModeEnabled)
                    .onChange(of: isGhostModeEnabled) {
                        oldValue, newValue in
                    }
            } footer: {
                Text("Ghost mode stops you from being seen")
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
