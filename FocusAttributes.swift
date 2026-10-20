import ActivityKit
import Foundation

enum FocusKind: String, Codable, Hashable, CaseIterable {
    case work, study, read, sport, create, calm

    var symbol: String {
        switch self {
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .read: return "book.closed.fill"
        case .sport: return "figure.run"
        case .create: return "star.fill"
        case .calm: return "moon.stars.fill"
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
    }
    var title: String
}

typealias FocusSnap = FocusAttributes.ContentState
