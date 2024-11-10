import Foundation
import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func joinedRipple() {
        // Three medium impacts in succession
        Task { @MainActor in
            impact.impactOccurred()
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            impact.impactOccurred()
            try? await Task.sleep(nanoseconds: 200_000_000)
            impact.impactOccurred()
        }
    }

    func nearbyRipple() {
        notification.notificationOccurred(.warning)
    }
} 
