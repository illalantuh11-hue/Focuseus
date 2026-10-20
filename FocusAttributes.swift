import ActivityKit
import Foundation

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
    }
    var title: String
}
