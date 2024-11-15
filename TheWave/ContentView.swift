import SwiftUI
import MapKit
import CoreLocation
import AudioToolbox

class RippleState: ObservableObject {
    static let shared = RippleState()

    @Published var rippleLocations: [RippleLocation] = []
    @Published var lastError: String?
    @Published var currentRippleId: String?
    @Published var showJoinedMessage = false
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
    let message: String?
    let nearbyRipples: [RippleDaata]
    let ripple_id: String? // The ripple we've joined
}

struct RippleOrigin: Codable {
    let coordinates: [Double]
    let type: String
}

struct CoordinateData: Codable {
    let longitude: Double
    let latitude: Double
}

func runSound() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
}

// Display model
struct RippleLocation: Identifiable, Decodable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let memberCount: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        let origin = try container.decode(RippleOrigin.self, forKey: .origin)
        self.coordinate = CLLocationCoordinate2D(
            latitude: origin.coordinates[0],
            longitude: origin.coordinates[1]
        )

        let members = try container.decode([String].self, forKey: .members)
        self.memberCount = members.count
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case origin
        case members
    }

    init(id: String, coordinate: CLLocationCoordinate2D, memberCount: Int) {
        self.id = id
        self.coordinate = coordinate
        self.memberCount = memberCount
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
        @State private var cameraPosition: MapCameraPosition = .region(.init(center: CLLocationCoordinate2D(), span: MKCoordinateSpan()))
        @State private var showingShareSheet = false

        let METRES_PAN = 5000.0

        var userLocation: CLLocationCoordinate2D {
            locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }

        init(){
            for family in UIFont.familyNames {
                 print(family)

                 for names in UIFont.fontNames(forFamilyName: family){
                 print("== \(names)")
                 }
            }
        }

        var body: some View {
            NavigationStack(path: $path) {
                ZStack {
                    Map(
                        position: $cameraPosition,
                        bounds: MapCameraBounds(
                            centerCoordinateBounds: MKCoordinateRegion(
                                center: userLocation,
                                latitudinalMeters: METRES_PAN * 2,
                                longitudinalMeters: METRES_PAN * 2
                            ),
                            minimumDistance: 1000,
                            maximumDistance: METRES_PAN * 2
                        )
                    ) {
                        // Now use rippleState.rippleLocations
                        ForEach(rippleState.rippleLocations) { location in
                            RippleView(
                                population: location.memberCount,
                                color: rippleColors[abs(location.id.hashValue) % rippleColors.count],
                                position: location.coordinate
                            )
                        }

                        // Show user's location with a blue dot and pulse effect
                        if let location = locationManager.lastLocation {
                            RippleView(
                                population: 1,
                                color: .blue,
                                position: location.coordinate
                            )

                            // Add a central dot for precise location
                            Annotation("Me", coordinate: location.coordinate) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .mapControlVisibility(.hidden)
                    .mapStyle(.standard(pointsOfInterest: []))
                    .ignoresSafeArea()

                    VStack(spacing: 16) {
//                        Color.clear.frame(height: 50)
                        if let error = rippleState.lastError {
                            Text("⚠️ \(error)")
                                .padding()
                                .bold()
                                .background(.regularMaterial)
                                .cornerRadius(10)
                        }


                        if rippleState.showJoinedMessage {
                            Text("You joined a ripple")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                // .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.top, 60) // Adjust for status bar
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        } else if rippleState.currentRippleId != nil {
                            ZStack {
                                Text("You're in a ripple")
                                    .padding()
                                    .bold()
                                    .background(.regularMaterial)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }

                        HStack(alignment: .center) {
//                            Button {
//                                showingShareSheet.toggle()
//                            } label: {
//                                Image(systemName: "square.and.arrow.up")
//                                    .font(.system(size: 24))
//                                    .padding(12)
//                                    .background(Circle().fill(.black))
//                                    .foregroundColor(.white)
//                            }

                            Spacer()

                            ReactionView()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .animation(.spring(response: 0.3), value: rippleState.showJoinedMessage)
                }
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
                .onAppear {
                    // Ensure location updates are started
                    locationManager.startUpdatingLocation()

                    // Set initial camera position centered on user
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: userLocation,
                        distance: METRES_PAN,
                        heading: 0,
                        pitch: 0
                    ))
                }
                .onDisappear {
                    // Optionally stop updates when view disappears
                    locationManager.stopUpdatingLocation()
                }
                // Update camera position when location changes
                .onChange(of: locationManager.lastLocation) { _, newLocation in
                    guard let location = newLocation else { return }
                    withAnimation {
                        cameraPosition = .camera(MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: METRES_PAN,
                            heading: 0,
                            pitch: 0
                        ))
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareView(isPresented: $showingShareSheet, userLocation: userLocation)
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

                let rippleData = try JSONDecoder().decode(RippleData.self, from: data)

                // Check if we joined a ripple
                if let rippleId = rippleData.ripple_id {
                    // PRESENT USER WITH MESSAGE SAYING THEY ARE IN A RIPPLE

                    await MainActor.run {
                        RippleState.shared.currentRippleId = rippleId
                        RippleState.shared.showJoinedMessage = true

                        // Hide the message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                RippleState.shared.showJoinedMessage = false
                            }
                        }
                    }
                }

                // Check if there's a message about nearby ripples
                if let message = rippleData.message, message.contains("nearby") {
                    await MainActor.run {
                        HapticManager.shared.nearbyRipple()
                    }
                }

                let locations = rippleData.nearbyRipples.map { ripple in
                    RippleLocation(
                        id: ripple._id,
                        coordinate: CLLocationCoordinate2D(
                            latitude: ripple.origin.coordinates[0],
                            longitude: ripple.origin.coordinates[1]
                        ),
                        memberCount: ripple.members.count
                    )
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
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

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
        locationManager.allowsBackgroundLocationUpdates = true // If you want background updates
        locationManager.pausesLocationUpdatesAutomatically = false
        checkLocationAuthorization()
    }

    func startUpdatingLocation() {
        print("Starting location updates")
        checkLocationAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        print("Stopping location updates")
        locationManager.stopUpdatingLocation()
    }

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Handle unauthorized state
            print("Location access denied")
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }

    // Delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate)")
        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
}

// Add this at the top of ContentView or in a separate Colors extension file
private let rippleColors: [Color] = [
    Color(hex: "1A00E2"),  // Blue
    Color(hex: "00E2DE"),  // Cyan
    Color(hex: "155FFF"),  // Light Blue
    Color(hex: "0B116B"),  // Dark Blue
    Color(hex: "5C00FA")   // Purple
]

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this helper view for the notification badge
struct NotificationBadge: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 24, height: 24)
    }
}
