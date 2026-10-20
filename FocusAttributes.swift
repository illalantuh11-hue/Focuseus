var symbol: String {
        switch self {
        case .work: return "briefcase.fill"
        case .study: return "book.closed.fill" // Книга
        case .read: return "text.book.closed.fill" // Альтернативная книга для чтения
        case .sport: return "figure.run" // Оставляем спорт
        case .create: return "star.fill" // Звезда
        case .calm: return "moon.stars.fill" // Луна
        }
    }
