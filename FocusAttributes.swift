import ActivityKit
import AppIntents
import Foundation
import UserNotifications

enum FocusKind: String, Codable, Hashable, CaseIterable {
    case work, study, read, sport, create, calm

    var symbol: String {
        switch self {
        case .work: return "briefcase.fill"
        case .study: return "graduationcap.fill"
        case .read: return "book.fill"
        case .sport: return "figure.run"
        case .create: return "paintbrush.fill"
        case .calm: return "leaf.fill"
        }
    }

    var title: String {
        switch self {
        case .work: return "Работа"
        case .study: return "Учёба"
        case .read: return "Чтение"
        case .sport: return "Спорт"
        case .create: return "Творчество"
        case .calm: return "Спокойствие"
        }
    }
}

struct FocusAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var start: Date
        var end: Date
        var kind: FocusKind
        var pausedRemaining: Double?
        var total: Double
    }
    var title: String
}

typealias FocusSnap = FocusAttributes.ContentState

func focusFormat(_ t: Double) -> String {
    let s = max(0, Int(t.rounded()))
    return String(format: "%d:%02d", s / 60, s % 60)
}

/// Pause / resume the running focus session. Used by the app and by the island button.
func focusTogglePause() async {
    guard let a = Activity<FocusAttributes>.activities.first else { return }
    var s = a.content.state
    let center = UNUserNotificationCenter.current()
    if let rem = s.pausedRemaining {
        let end = Date().addingTimeInterval(rem)
        s.end = end
        s.start = end.addingTimeInterval(-s.total)
        s.pausedRemaining = nil
        await a.update(ActivityContent(state: s, staleDate: end))
        let content = UNMutableNotificationContent()
        content.title = "Фокус завершён"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(rem, 1), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "focus-end", content: content, trigger: trigger))
    } else {
        s.pausedRemaining = max(0, s.end.timeIntervalSinceNow)
        center.removeAllPendingNotificationRequests()
        await a.update(ActivityContent(state: s, staleDate: nil))
    }
}

struct TogglePauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Пауза"

    func perform() async throws -> some IntentResult {
        await focusTogglePause()
        return .result()
    }
}
