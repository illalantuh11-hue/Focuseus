import ActivityKit
import SwiftUI
import WidgetKit
import Foundation // Важно для математических функций cos/sin

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
            Text("Готово").font(.focusTimer(20, weight: .medium))
        } else {
            Text(timerInterval: state.start...state.end, countsDown: true)
                .font(.focusTimer(36, weight: .medium))
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
        let center = CGPoint(x: rect.midX, y: rect.maxY + 35)
        let radius = min(rect.width / 2, rect.height + 35)
        
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
            let radius = min(width / 2, height + 35)
            let centerY = height + 35
            
            ZStack {
                WideArcShape()
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                WideArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                if !isStale && progress > 0.02 && progress < 0.98 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .position(markerPosition(width: width, centerY: centerY, radius: radius))
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
    
    // Разбил математику на шаги, чтобы компилятор не сошел с ума
    private func markerPosition(width: CGFloat, centerY: CGFloat, radius: CGFloat) -> CGPoint {
        let angleDouble = Double.pi - (Double(progress) * Double.pi)
        let xOffset = CGFloat(cos(angleDouble)) * radius
        let yOffset = CGFloat(sin(angleDouble)) * radius
        
        let x = width / 2 + xOffset
        let y = centerY - yOffset
        
        return CGPoint(x: x, y: y)
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
            HStack(spacing: 14) {
                FocusIcon(kind: context.state.kind, size: 24)
                FocusTime(state: context.state, stale: context.isStale)
                    .font(.focusTimer(40, weight: .light))
                Spacer()
                ThickRing(state: context.state, size: 30, lineWidth: 5)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 22)
                        .padding(.leading, 12)
                        .padding(.top, 6)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.kind.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 12)
                        .padding(.top, 6)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ZStack(alignment: .bottom) {
                        WideArcProgress(state: context.state, isStale: context.isStale)
                            .frame(height: 40)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                        
                        FocusTime(state: context.state, stale: context.isStale)
                            .offset(y: -2)
                    }
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                FocusIcon(kind: context.state.kind, size: 18)
            } compactTrailing: {
                ThickRing(state: context.state, size: 22, lineWidth: 5)
            } minimal: {
                ThickRing(state: context.state, size: 18, lineWidth: 4)
            }
        }
    }
}
