import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 3
    var size: CGFloat = 44
    var showsTrack: Bool = true
    var emphasize: Bool = false

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            if showsTrack {
                Circle()
                    .stroke(trackColor, lineWidth: lineWidth)
                    .padding(lineWidth / 2)
            }
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress \(Int(clamped * 100)) percent")
    }

    private var ringColor: Color {
        if emphasize { return Color.accentColor }
        return Color.primary
    }

    private var trackColor: Color {
        if emphasize {
            return Color.accentColor.opacity(0.2)
        }
        return Color.primary.opacity(0.22)
    }
}

/// Template-friendly ring for the menu bar (~16×16pt, stroke inset so edges are not clipped).
struct MenuBarTemplateRingView: View {
    var progress: Double
    var isOffline: Bool

    private let canvas: CGFloat = 16
    private let lineWidth: CGFloat = 2

    private var clamped: Double { min(1, max(0, progress)) }
    private var diameter: CGFloat { canvas - lineWidth }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.35), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.black,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        dash: isOffline ? [2, 2] : []
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)
        }
        .frame(width: canvas, height: canvas, alignment: .center)
        .accessibilityHidden(true)
    }
}