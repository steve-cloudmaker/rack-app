import SwiftUI

struct SplashScreenView: View {
    var onComplete: () -> Void

    @State private var textOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            TartanView()
                .ignoresSafeArea()

            Text("RACK")
                .font(.system(size: 96, weight: .black, design: .default))
                .tracking(24)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
                .offset(x: textOffset)
        }
        .opacity(opacity)
        .onAppear { animate() }
    }

    private func animate() {
        let screenWidth = UIScreen.main.bounds.width

        // Slide in from left
        withAnimation(.easeOut(duration: 0.65)) {
            textOffset = 0
        }

        // Pause, then slide out to right
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.5)) {
                textOffset = screenWidth
            }
        }

        // Fade out and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
            onComplete()
        }
    }
}

// MARK: - MacKinnon Hunting Tartan

struct TartanView: View {
    // MacKinnon Hunting sett — forest green, black overcheck, dark red accent
    private static let green  = Color(red: 0.11, green: 0.33, blue: 0.13)
    private static let black  = Color(red: 0.05, green: 0.05, blue: 0.05)
    private static let red    = Color(red: 0.52, green: 0.06, blue: 0.06)

    // (color, thread-count) — mirrors at each end for a balanced sett
    private static let sett: [(Color, CGFloat)] = [
        (green, 40),
        (black,  6),
        (green,  6),
        (black,  6),
        (red,    4),
        (black,  6),
        (green,  6),
        (black,  6),
        (green, 40),  // pivot — mirrors back
        (black,  6),
        (green,  6),
        (black,  6),
        (red,    4),
        (black,  6),
        (green,  6),
        (black,  6),
    ]

    private static let repeatWidth: CGFloat = sett.reduce(0) { $0 + $1.1 }

    var body: some View {
        Canvas { ctx, size in
            // Fill background green first
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Self.green))

            // Vertical stripes
            drawStripes(ctx: ctx, size: size, vertical: true, opacity: 1.0)

            // Horizontal stripes at partial opacity — creates the woven intersection effect
            drawStripes(ctx: ctx, size: size, vertical: false, opacity: 0.55)
        }
    }

    private func drawStripes(ctx: GraphicsContext, size: CGSize, vertical: Bool, opacity: Double) {
        var pos: CGFloat = 0
        let total = Self.repeatWidth
        // Tile enough repeats to cover the full dimension
        let dimension = vertical ? size.width : size.height
        while pos < dimension + total {
            for (color, width) in Self.sett {
                let rect: CGRect = vertical
                    ? CGRect(x: pos, y: 0, width: width, height: size.height)
                    : CGRect(x: 0, y: pos, width: size.width, height: width)
                ctx.fill(Path(rect), with: .color(color.opacity(opacity)))
                pos += width
            }
        }
    }
}
