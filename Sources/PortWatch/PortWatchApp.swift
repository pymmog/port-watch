import AppKit
import SwiftUI
import PortWatchCore

struct PortWatchApp: App {
    @StateObject private var appModel = AppModel()
    @ObservedObject private var settings = SettingsStore.shared

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        NotificationService.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            DetailPopoverView()
                .environmentObject(appModel)
        } label: {
            MenuBarStatusLabel(
                progress: appModel.menuBarProgress,
                percent: appModel.displayPercent,
                showPercent: settings.showMenuBarPercentage,
                isOffline: appModel.isOffline
            )
        }
        .menuBarExtraStyle(.window)
    }
}