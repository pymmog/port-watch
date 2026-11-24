import AppKit
import SwiftUI
import PortWatchCore

struct DetailPopoverView: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            metricsGrid
            Divider()
            newsSection
            Divider()
            settingsSection
            actionButtons
        }
        .padding(16)
        .frame(width: 360)
    }

  private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ProgressRingView(
                progress: app.menuBarProgress,
                lineWidth: 6,
                size: 68,
                emphasize: true
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("GTA VI on PC")
                    .font(.headline)
                if let state = app.state {
                    Text(state.playableAnswer)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(app.displayPercent)% overall")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if app.isOffline {
                    Text("Offline")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text("Loading…")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var metricsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            if let state = app.state {
                metricRow("Leader", leaderLine(for: state))
                metricRow("Top 3 average", String(format: "%.1f%%", state.overall.top3))
                metricRow("Furthest milestone", state.overall.furthest.label)
                metricRow("Efforts tracked", "\(state.overall.trackedCount)")
                metricRow("Executable", state.document.exe.status.capitalized)
                metricRow(
                    "Data updated",
                    state.document.updated.formatted(date: .abbreviated, time: .shortened)
                )
                if app.isOffline {
                    metricRow("Status", "Using last good data")
                }
            }
        }
        .font(.callout)
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }

    private func leaderLine(for state: LiveTrackerState) -> String {
        guard let leader = state.overall.leader else { return "—" }
        return "\(leader.effort.name) · \(leader.reachedLabel) (\(leader.score.roundedString)%)"
    }

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest news")
                .font(.subheadline.weight(.semibold))
            if let state = app.state {
                ForEach(state.newestNews) { item in
                    Link(destination: item.url()) {
                        Text(item.title)
                            .font(.callout)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No stories yet.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show % in menu bar", isOn: $settings.showMenuBarPercentage)
            Toggle("Notify on progress changes", isOn: $settings.notificationsEnabled)
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
            Picker("Refresh every", selection: $settings.refreshInterval) {
                ForEach(RefreshInterval.allCases) { interval in
                    Text(interval.label).tag(interval)
                }
            }
            .onChange(of: settings.refreshInterval) { _, _ in
                app.startAutoRefresh()
            }
        }
        .font(.callout)
    }

    private var actionButtons: some View {
        HStack {
            Button("Refresh now") {
                Task { @MainActor in
                    await app.refreshNow()
                }
            }
            .disabled(app.isRefreshing)

            Spacer()

            Button("Open PortWatch VI") {
                NSWorkspace.shared.open(PortWatchURLs.siteRoot)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

private extension Double {
    var roundedString: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }
}