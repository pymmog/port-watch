import Combine
import Foundation
import PortWatchCore

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case thirty = 30
    case sixty = 60

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) minutes"
    }

    var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var showMenuBarPercentage: Bool {
        didSet { UserDefaults.standard.set(showMenuBarPercentage, forKey: Keys.showMenuBarPercentage) }
    }

    @Published var refreshInterval: RefreshInterval {
        didSet { UserDefaults.standard.set(refreshInterval.rawValue, forKey: Keys.refreshInterval) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var launchAtLogin: Bool {
        didSet { LoginItemService.setEnabled(launchAtLogin) }
    }

    private enum Keys {
        static let showMenuBarPercentage = "showMenuBarPercentage"
        static let refreshInterval = "refreshInterval"
        static let notificationsEnabled = "notificationsEnabled"
    }

    private init() {
        let defaults = UserDefaults.standard
        showMenuBarPercentage = defaults.object(forKey: Keys.showMenuBarPercentage) as? Bool ?? true
        let minutes = defaults.integer(forKey: Keys.refreshInterval)
        refreshInterval = RefreshInterval(rawValue: minutes == 0 ? 10 : minutes) ?? .ten
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        launchAtLogin = LoginItemService.isEnabled()
    }
}