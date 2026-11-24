import AppKit
import Combine
import Foundation
import PortWatchCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: LiveTrackerState?
    @Published private(set) var isRefreshing = false
    @Published private(set) var isOffline = false

    private var refreshTask: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?

    init() {
        guard !SnapshotCommandLine.wantsSnapshot else { return }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshNow()
            }
        }

        startAutoRefresh()
        Task { @MainActor in
            await refreshNow()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let interval = SettingsStore.shared.refreshInterval.seconds
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await self?.refreshNow()
            }
        }
    }

    func refreshNow() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let next = try await TrackerSnapshotBuilder.fetch()
            isOffline = false

            if let previous = state {
                NotificationService.notifyIfChanged(
                    from: previous,
                    to: next,
                    enabled: SettingsStore.shared.notificationsEnabled
                )
            } else {
                NotificationService.seedBaseline(from: next)
            }

            state = next
        } catch {
            isOffline = true
            NSLog("PortWatch refresh failed: \(error.localizedDescription)")
        }
    }

    var displayPercent: Int {
        Int((state?.overall.score ?? 0).rounded())
    }

    var menuBarProgress: Double {
        min(1, max(0, (state?.overall.score ?? 0) / 100))
    }

    /// Used by `--snapshot` rendering without starting menu bar refresh timers.
    func adoptForSnapshot(_ liveState: LiveTrackerState) {
        state = liveState
        isOffline = false
        isRefreshing = false
    }
}