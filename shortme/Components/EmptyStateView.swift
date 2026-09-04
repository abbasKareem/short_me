import SwiftUI

struct EmptyStateView: View {
    let title: String
    var detail: String?
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .controlSize(.small)
                    .padding(.top, 3)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
