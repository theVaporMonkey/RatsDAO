import SwiftUI

/// Central brand palette for Pool Duck. Values mirror the asset catalog
/// entries so the colors are available at compile time if the catalog is
/// absent and can still be themed per-trait via the asset catalog.
enum PoolDuckTheme {
    /// Primary teal (matches the square brand art background).
    static let teal = Color(red: 0.42, green: 0.78, blue: 0.76)

    /// Deeper teal used for water accents in the logo mark.
    static let deepTeal = Color(red: 0.18, green: 0.60, blue: 0.60)

    /// Vibrant duck green used on the mascot body.
    static let duckGreen = Color(red: 0.30, green: 0.66, blue: 0.32)

    /// Near-black used on the logo banner backdrop.
    static let inkBlack = Color(red: 0.09, green: 0.10, blue: 0.11)

    /// Soft cream used for the brand tagline text.
    static let cream = Color(red: 0.96, green: 0.92, blue: 0.93)

    static let surface = Color(.systemBackground)
    static let surfaceMuted = Color(.secondarySystemBackground)

    static func gradient() -> LinearGradient {
        LinearGradient(
            colors: [teal, deepTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDestructive ? Color.red : PoolDuckTheme.deepTeal)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PoolDuckTheme.deepTeal)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PoolDuckTheme.deepTeal, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PoolDuckTheme.surfaceMuted)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}
