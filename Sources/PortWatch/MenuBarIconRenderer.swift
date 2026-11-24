import AppKit
import SwiftUI

@MainActor
enum MenuBarIconRenderer {
    /// Renders a template ring for `Image(nsImage:)` in menu bar labels (appearance-aware).
    static func templateRingNSImage(progress: Double, isOffline: Bool) -> NSImage? {
        let view = MenuBarTemplateRingView(progress: progress, isOffline: isOffline)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = true
        return image
    }
}