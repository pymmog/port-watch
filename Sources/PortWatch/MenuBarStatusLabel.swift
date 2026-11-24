import SwiftUI
import AppKit

/// Native menu bar label: template ring + status text (text follows appearance automatically).
struct MenuBarStatusLabel: View {
    var progress: Double
    var percent: Int
    var showPercent: Bool
    var isOffline: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if let ring = MenuBarIconRenderer.templateRingNSImage(progress: progress, isOffline: isOffline) {
                Image(nsImage: ring)
                    .accessibilityHidden(true)
            }

            if showPercent {
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .fixedSize()
            }
        }
        .frame(height: 22, alignment: .center)
        .id("\(percent)-\(showPercent)-\(isOffline)-\(colorScheme == .dark ? "dark" : "light")")
    }
}

/// Snapshot / export preview matching template tint on synthetic menu bar chrome.
struct MenuBarSnapshotLabel: View {
    var progress: Double
    var percent: Int
    var showPercent: Bool
    var isDark: Bool
    var isOffline: Bool

    private var foreground: Color {
        isDark ? .white : .black
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            MenuBarTemplateRingView(progress: progress, isOffline: isOffline)
                .foregroundStyle(foreground)

            if showPercent {
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(foreground)
            }
        }
        .frame(height: 22, alignment: .center)
    }
}