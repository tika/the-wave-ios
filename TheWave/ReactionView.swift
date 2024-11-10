import SwiftUI

struct ReactionView: View {
    @State private var expanded = false
    private let emojis = ["🔥", "🍾", "💩", "🍀"]

    var body: some View {
        VStack(spacing: 12) {
            if expanded {
                ForEach(emojis.dropLast(), id: \.self) { emoji in
                    ReactionButton(emoji: emoji) {
                        print("Tapped \(emoji)")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            ReactionButton(emoji: emojis.last ?? "🔥") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    expanded.toggle()
                }
            }
            .rotationEffect(.degrees(expanded ? 45 : 0))
        }
        .padding(.vertical, expanded ? 12 : 8)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.black)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.trailing, 16)
        .padding(.bottom, 24)
    }
}

struct ReactionButton: View {
    let emoji: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }

            // Reset the press state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isPressed = false
                }
            }
        } label: {
            Text(emoji)
                .font(.system(size: 24))
                .padding(8)
                .background(Circle().fill(.black))
                .scaleEffect(isPressed ? 1.2 : 1.0)
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        ReactionView()
    }
}
