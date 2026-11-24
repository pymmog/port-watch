import Foundation
import PortWatchCore
import UserNotifications

enum NotificationService {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @MainActor
    static func seedBaseline(from state: LiveTrackerState) {
        _ = state
    }

    @MainActor
    static func notifyIfChanged(from previous: LiveTrackerState, to next: LiveTrackerState, enabled: Bool) {
        guard enabled else { return }

        let score = next.overall.score
        let furthest = next.overall.furthest.key

        guard previous.overall.score != score || previous.overall.furthest.key != furthest else { return }

        let content = UNMutableNotificationContent()
        content.title = "PortWatch VI"
        if previous.overall.furthest.key != furthest {
            content.body = "Furthest milestone is now \(next.overall.furthest.label) · \(next.playableAnswer)"
        } else {
            let old = Int(previous.overall.score.rounded())
            let new = Int(score.rounded())
            content.body = "Overall progress is now \(new)% (was \(old)%)"
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}