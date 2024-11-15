import SwiftUI
import MapKit

struct ShareView: View {
    @Binding var isPresented: Bool
    let userLocation: CLLocationCoordinate2D

    var body: some View {
        VStack(spacing: 20) {

            Text("Share Location")
                .font(.title3)
                .bold()

            // Map preview
            Map(position: .constant(.region(MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )))) {
                Annotation("Me", coordinate: userLocation) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            .disabled(true)

            Button(action: {
                let renderer = ImageRenderer(content: Map(position: .constant(.region(MKCoordinateRegion(
                    center: userLocation,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )))) {
                    Annotation("Me", coordinate: userLocation) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }
                .frame(width: 300, height: 300)
                .cornerRadius(12))

                if let image = renderer.uiImage {
                    let activityVC = UIActivityViewController(
                        activityItems: [image],
                        applicationActivities: nil
                    )

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        activityVC.popoverPresentationController?.sourceView = rootVC.view
                        rootVC.present(activityVC, animated: true)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}
