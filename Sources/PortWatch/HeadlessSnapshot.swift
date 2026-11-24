import AppKit
import PortWatchCore
import SwiftUI

@MainActor
enum HeadlessSnapshot {
    static let outputFiles = [
        "menubar-light.png",
        "menubar-dark.png",
        "popover-light.png",
        "popover-dark.png",
        "appicon.png",
    ]

    static func run(outputDirectory: URL) async throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let liveState = try await TrackerSnapshotBuilder.fetch()
        let appModel = AppModel()
        appModel.adoptForSnapshot(liveState)

        let progress = appModel.menuBarProgress
        let percent = appModel.displayPercent

        try renderMenuBar(
            progress: progress,
            percent: percent,
            to: outputDirectory.appendingPathComponent("menubar-light.png"),
            isDark: false
        )
        try renderMenuBar(
            progress: progress,
            percent: percent,
            to: outputDirectory.appendingPathComponent("menubar-dark.png"),
            isDark: true
        )

        try renderPopover(
            appModel: appModel,
            to: outputDirectory.appendingPathComponent("popover-light.png"),
            colorScheme: .light
        )
        try renderPopover(
            appModel: appModel,
            to: outputDirectory.appendingPathComponent("popover-dark.png"),
            colorScheme: .dark
        )

        try exportAppIcon(to: outputDirectory.appendingPathComponent("appicon.png"))
    }

    private static func renderMenuBar(
        progress: Double,
        percent: Int,
        to url: URL,
        isDark: Bool
    ) throws {
        let content = MenuBarSnapshotCanvas(isDark: isDark) {
            MenuBarSnapshotLabel(
                progress: progress,
                percent: percent,
                showPercent: true,
                isDark: isDark,
                isOffline: false
            )
        }
        try render(view: content, label: url.lastPathComponent, to: url)
    }

    private static func renderPopover(
        appModel: AppModel,
        to url: URL,
        colorScheme: ColorScheme
    ) throws {
        let content = PopoverSnapshotCanvas(appModel: appModel, colorScheme: colorScheme)
        try render(
            view: content,
            label: url.lastPathComponent,
            to: url,
            proposedSize: ProposedViewSize(width: 360, height: nil)
        )
    }

    private static func exportAppIcon(to url: URL) throws {
        if let bundled = Bundle.main.url(forResource: "appicon-512", withExtension: "png") {
            let data = try Data(contentsOf: bundled)
            try data.write(to: url, options: .atomic)
            return
        }
        throw SnapshotError.renderFailed("appicon-512.png")
    }

    private static func render<V: View>(
        view: V,
        label: String,
        to url: URL,
        proposedSize: ProposedViewSize? = nil
    ) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        if let proposedSize {
            renderer.proposedSize = proposedSize
        }
        guard let cgImage = renderer.cgImage else {
            throw SnapshotError.renderFailed(label)
        }
        try SnapshotPNGWriter.write(cgImage: cgImage, to: url)
    }
}

private struct MenuBarSnapshotCanvas<Content: View>: View {
    var isDark: Bool
    @ViewBuilder var content: Content

    private var barColor: Color {
        if isDark {
            return Color(nsColor: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.17, alpha: 1))
        }
        return Color(nsColor: NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.94, alpha: 1))
    }

    var body: some View {
        ZStack {
            barColor
            content
        }
        .padding(.horizontal, 10)
        .frame(height: 22)
        .fixedSize(horizontal: true, vertical: true)
        .environment(\.colorScheme, isDark ? .dark : .light)
    }
}

private struct PopoverSnapshotCanvas: View {
    var appModel: AppModel
    var colorScheme: ColorScheme

    var body: some View {
        DetailPopoverView()
            .environmentObject(appModel)
            .frame(width: 360)
            .background(Color(nsColor: .windowBackgroundColor).opacity(1))
            .clipShape(Rectangle())
            .preferredColorScheme(colorScheme)
            .environment(\.colorScheme, colorScheme)
    }
}