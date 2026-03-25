import SwiftUI

/// Pulse App Icon — Placeholder preview
/// This file renders the brand icon concept for visual reference.
/// Replace with actual asset catalog icons (Assets.xcassets/AppIcon.appiconset)
/// before shipping.
struct PulseAppIconView: View {
    var body: some View {
        PulseIconShape()
            .frame(width: 256, height: 256)
    }
}

struct PulseIconShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Dark charcoal background
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(hex: "1E1E2E"))

                // Shadow
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(0.3), radius: size * 0.05, x: 0, y: size * 0.04)

                // Circular monitor ring with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "4ADE80"),
                                Color(hex: "FBBF24"),
                                Color(hex: "F87171")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: size * 0.015
                    )
                    .frame(width: size * 0.62, height: size * 0.62)

                // Inner dark surface
                Circle()
                    .fill(Color(hex: "2A2A3E"))
                    .frame(width: size * 0.58, height: size * 0.58)

                // Concentric grid rings
                ForEach([0.2, 0.35, 0.48], id: \.self) { ringSize in
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: size * 0.008)
                        .frame(width: size * ringSize, height: size * ringSize)
                }

                // ECG pulse waveform
                PulseWave(size: size)
                    .stroke(
                        Color(hex: "6C9EFF"),
                        style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.18)
                    .shadow(color: Color(hex: "6C9EFF").opacity(0.6), radius: size * 0.02)

                // Center dot (heart of the monitor)
                Circle()
                    .fill(Color(hex: "6C9EFF"))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .shadow(color: Color(hex: "6C9EFF").opacity(0.8), radius: size * 0.015)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct PulseWave: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.5))

        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.5))

        // P wave
        path.addQuadCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.35),
            control: CGPoint(x: w * 0.14, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.5),
            control: CGPoint(x: w * 0.22, y: h * 0.6)
        )

        // Q dip
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.7))

        // R peak (tall)
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.05))

        // S dip
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.75))

        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))

        // T wave
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.3),
            control: CGPoint(x: w * 0.58, y: h * 0.28)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.5),
            control: CGPoint(x: w * 0.68, y: h * 0.6)
        )

        path.addLine(to: CGPoint(x: w, y: h * 0.5))

        return path
    }
}

#Preview {
    PulseAppIconView()
        .frame(width: 512, height: 512)
}
