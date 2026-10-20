import ActivityKit
import SwiftUI
import WidgetKit

extension Font {
    static func focusTimer(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct FocusTime: View {
    let state: FocusSnap
    let stale: Bool

    var body: some View {
        if stale {
            Text("Готово").font(.focusTimer(22, weight: .medium))
        } else {
            Text(timerInterval: state.start...state.end, countsDown: true)
                .font(.focusTimer(36, weight: .regular)) // Сделал чуть больше и плотнее
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
    }
}

// === Форма широкой дуги ===
struct WideArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Центр берем далеко внизу, чтобы дуга была пологой (как мост)
        let center = CGPoint(x: rect.midX, y: rect.maxY + 30)
        let radius = min(rect.width / 2, rect.height + 30)
        
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(0),
                    clockwise: false)
        return path
    }
}

struct WideArcProgress: View {
    let state: FocusSnap
    let isStale: Bool

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            // Вычисляем радиус и угол для позиции белой точки
            let radius = min(width / 2, height + 30)
            let centerY = height + 30
            
            ZStack {
                // 1. Темно-серая подложка
                WideArcShape()
                    .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                
                // 2. Белая заполняющаяся дуга
                WideArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                
                // 3. Точка на конце
                if !isStale && progress > 0.02 && progress < 0.98 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14) // Точка крупнее
                        .position(
                            x: width / 2 + cos(Double.pi - Double(progress) * Double.pi) * radius,
                            y: centerY - sin(Double.pi - Double(progress) * Double.pi) * radius
                        )
                }
            }
        }
    }

    private var progress: CGFloat {
        if isStale { return 1 }
        let total = state.end.timeIntervalSince(state.start)
        guard total > 0 else { return 0 }
        let remaining = max(0, state.end.timeIntervalSinceNow)
        return CGFloat(1 - remaining / total)
    }
}

struct FocusIcon: View {
    let kind: FocusKind
    var size: CGFloat = 15

    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.white)
    }
}

// === Компактное кольцо ===
struct ThickRing: View {
    let state: FocusSnap
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
            
            ProgressView(timerInterval: state.start...state.end, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(.white)
            .frame(width: size, height: size)
            .scaleEffect(1.0 + (lineWidth / size) * 0.8)
        }
        .frame(width: size, height: size)
    }
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            // Экран блокировки
            HStack(spacing: 14) {
                FocusIcon(kind: context.state.kind, size: 22)
                FocusTime(state: context.state, stale: context.isStale)
                    .font(.focusTimer(40, weight: .light))
                Spacer()
                ThickRing(state: context.state, size: 30, lineWidth: 4)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── ЛЕВО: Иконка (строго в углу) ──
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 20)
                        .padding(.leading, 12)
                        .padding(.top, 4)
                }
                
                // ── ПРАВО: Текст (строго в углу, без обрезки) ──
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.kind.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 12)
                        .padding(.top, 4)
                }
                
                // ── ЦЕНТР: Оставляем пустым (чтобы не сжимало дугу) ──
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                
                // ── НИЗ: Вся широкая дуга + таймер ──
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 2) {
                        // Дуга растягивается на всю доступную ширину
                        WideArcProgress(state: context.state, isStale: context.isStale)
                            .frame(height: 35)
                            .padding(.horizontal, 20)
                        
                        // Таймер ровно под дугой
                        FocusTime(state: context.state, stale: context.isStale)
                            .offset(y: -8) // Поднимаем таймер, чтобы он был внутри дуги, как на референсе
                    }
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                FocusIcon(kind: context.state.kind, size: 16)
            } compactTrailing: {
                ThickRing(state: context.state, size: 22, lineWidth: 5)
            } minimal: {
                ThickRing(state: context.state, size: 18, lineWidth: 4)
            }
        }
    }
}
