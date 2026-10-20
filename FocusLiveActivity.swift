import ActivityKit
import SwiftUI
import WidgetKit

let neon = Color.white

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
            Text("Готово").font(.focusTimer(16, weight: .medium))
        } else {
            Text(timerInterval: state.start...state.end, countsDown: true)
                .font(.focusTimer(22, weight: .medium))
                .monospacedDigit()
                .multilineTextAlignment(.center)
        }
    }
}

// === Дуга ===
struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Центр смещен вниз, чтобы дуга была более пологой
        let center = CGPoint(x: rect.midX, y: rect.maxY + 12)
        let radius = min(rect.width / 2, rect.height)
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0),
                 clockwise: false)
        return p
    }
}

struct WhiteArcProgress: View {
    let state: FocusSnap
    let isStale: Bool

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            ZStack {
                // 1. Фоновая дуга (белая, но полупрозрачная)
                ArcShape()
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                // 2. Заполненная дуга (ярко-белая)
                ArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                // 3. Точка на конце (белая с черной обводкой для контраста)
                if !isStale && progress > 0.02 && progress < 0.98 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2)) // Черная обводка, чтобы точка не сливалась с дугой
                        .offset(x: markerX(width: width, height: height),
                                y: markerY(width: width, height: height) - height/2)
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

    private func markerX(width: CGFloat, height: CGFloat) -> CGFloat {
        let angle = Double.pi - (Double(progress) * Double.pi)
        let radius = min(width / 2, height)
        return CGFloat(cos(angle)) * radius
    }

    private func markerY(width: CGFloat, height: CGFloat) -> CGFloat {
        let angle = Double.pi - (Double(progress) * Double.pi)
        let radius = min(width / 2, height)
        return -CGFloat(sin(angle)) * radius
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

// === Компактное кольцо (тоже белое) ===
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
                    .foregroundStyle(.white)
                Spacer()
                ThickRing(state: context.state, size: 30, lineWidth: 4)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── ЛЕВО: Иконка ──
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 20)
                        .padding(.leading, 8)
                        .padding(.top, 2)
                }
                
                // ── ПРАВО: Название в углу ──
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.kind.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.trailing, 8)
                        .padding(.top, 2)
                }
                
                // ── ЦЕНТР: Дуга ──
                DynamicIslandExpandedRegion(.center) {
                    WhiteArcProgress(state: context.state, isStale: context.isStale)
                        .frame(height: 40)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }
                
                // ── НИЗ: Таймер ──
                DynamicIslandExpandedRegion(.bottom) {
                    FocusTime(state: context.state, stale: context.isStale)
                        .offset(y: -4)
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
