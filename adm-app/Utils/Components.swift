import SwiftUI

struct InfoChip: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = .accentColor
    var filled: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(filled ? tint.opacity(0.14) : Color(.secondarySystemBackground))
        .foregroundStyle(tint)
        .overlay(
            Capsule()
                .stroke(tint.opacity(filled ? 0 : 0.5), lineWidth: filled ? 0 : 1)
        )
        .clipShape(Capsule())
    }
}

struct DimmedLoadingOverlay: ViewModifier {
    let isPresented: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented)
            if isPresented {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()
                VStack(spacing: 8) {
                    ProgressView()
                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

extension View {
    func loadingOverlay(isPresented: Bool, message: String? = nil) -> some View {
        modifier(DimmedLoadingOverlay(isPresented: isPresented, message: message))
    }
}
