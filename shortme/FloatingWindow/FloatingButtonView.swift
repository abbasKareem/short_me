import Combine
import SwiftUI

@MainActor
final class FloatingButtonVisualState: ObservableObject {
    @Published var isHovered = false
    @Published var isDragging = false
    @Published var isMenuOpen = false
    @Published var isContextMenuOpen = false

    var opacity: Double {
        isHovered || isDragging || isMenuOpen || isContextMenuOpen ? 1 : 0.5
    }
}

struct FloatingButtonView: View {
    @ObservedObject var state: FloatingButtonVisualState

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.indigo, .purple.opacity(0.82), .blue.opacity(0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.42), radius: 3)

            Image(systemName: "bolt.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .opacity(state.opacity)
        .scaleEffect(state.isDragging ? 1.05 : 1)
        .animation(.easeInOut(duration: 0.18), value: state.opacity)
        .animation(.easeInOut(duration: 0.15), value: state.isDragging)
        .contentShape(Rectangle())
        .accessibilityLabel("Open Shortcuts")
    }
}
