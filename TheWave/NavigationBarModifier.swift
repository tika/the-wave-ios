import SwiftUI

struct ClashDisplayNavBar: ViewModifier {
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "ClashDisplayVariable-Bold_Bold", size: 34)!
        ]

        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "ClashDisplayVariable-Bold_Bold", size: 20)!
        ]
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func clashDisplayNavBar() -> some View {
        self.modifier(ClashDisplayNavBar())
    }
} 
