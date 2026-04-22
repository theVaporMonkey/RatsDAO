import SwiftUI

/// Renders the Pool Duck logo. Prefers the bundled `DuckLogo` asset; falls
/// back to a vector approximation so the app still looks branded if the
/// asset hasn't been dropped in yet.
struct DuckLogo: View {
    var size: CGFloat = 140
    var showsWordmark: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PoolDuckTheme.teal)
                    .frame(width: size * 1.2, height: size * 1.2)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                if UIImage(named: "DuckLogo") != nil {
                    Image("DuckLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                } else {
                    DuckSilhouette()
                        .fill(PoolDuckTheme.duckGreen)
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "sunglasses.fill")
                                .font(.system(size: size * 0.28))
                                .foregroundStyle(.black)
                                .offset(y: -size * 0.08)
                        )
                }
            }

            if showsWordmark {
                Text("POOL DUCK")
                    .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
                    .foregroundStyle(PoolDuckTheme.inkBlack)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                    )
            }
        }
    }
}

/// Rough duck-shaped path used when the bundled logo art is missing.
private struct DuckSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.9))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.9),
            control: CGPoint(x: w * 0.5, y: h * 1.05)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.5),
            control1: CGPoint(x: w * 0.95, y: h * 0.85),
            control2: CGPoint(x: w, y: h * 0.7)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.1),
            control1: CGPoint(x: w * 0.92, y: h * 0.22),
            control2: CGPoint(x: w * 0.75, y: h * 0.1)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.5),
            control1: CGPoint(x: w * 0.3, y: h * 0.1),
            control2: CGPoint(x: w * 0.1, y: h * 0.3)
        )
        p.addLine(to: CGPoint(x: w * 0.2, y: h * 0.9))
        p.closeSubpath()
        return p
    }
}
