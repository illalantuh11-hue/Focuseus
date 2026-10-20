import ActivityKit
import SwiftUI
import WidgetKit

typealias FocusState = FocusAttributes.ContentState
let neon = Color.white

extension Font {
    static func focusTimer(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct FocusTime: View {
    let state: FocusState
    let stale: Bool
    var body: some View {
        if stale {
            Text("Готово").font(.focusTimer(20, weight: .medium))
        } else {
            Text(timerInterval: state.start...state.end, countsDown: true)
                .font(.focusTimer(34, weight: .light))
                .monospacedDigit()
                .multilineTextAlignment(.center)
        }
    }
}

// === Дуга (полукруг) для expanded ===
struct ExpandedArc: View {
    let state: FocusState
    let isStale: Bool

    var body: some View {
        ZStack {
            ArcShape()
                .stroke(Color.white.opacity(0.25),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ArcShape()
                .trim(from: 0, to: progress)
                .stroke(neon, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .softNeon(6)
        }
    }

    private var progress: CGFloat {
        if isStale { return 1 }
        let total = state.end.timeIntervalSince(state.start)
        guard total > 0 else { return 0 }
        let remaining = max(0, state.end.timeIntervalSinceNow)
        return CGFloat(1 - remaining / total) // заполняется слева направо
    }
}

struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0),
                 clockwise: false)
        return p
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

struct FocusRing: View {
    let state: FocusState
    let size: CGFloat
    var body: some View {
        ProgressView(timerInterval: state.start...state.end, countsDown: true) {
            EmptyView()
        } currentValueLabel: { EmptyView() }
        .progressViewStyle(.circular)
        .tint(neon)
        .frame(width: size, height: size)
    }
}

struct RingOrCheck: View {
    let state: FocusState
    let stale: Bool
    let size: CGFloat
    var body: some View {
        if stale {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundStyle(neon)
        } else {
            FocusRing(state: state, size: size)
        }
    }
}

struct ThickRing: View {
    let state: FocusState
    let size: CGFloat
    let lineWidth: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(neon, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
    private var progress: CGFloat {
        let total = state.end.timeIntervalSince(state.start)
        guard total > 0 else { return 0 }
        let remaining = max(0, state.end.timeIntervalSinceNow)
        return CGFloat(remaining / total)
    }
}

extension View {
    func softNeon(_ radius: CGFloat = 6, opacity: Double = 0.7) -> some View {
        self
            .shadow(color: neon.opacity(opacity), radius: radius / 2, x: 0, y: 0)
            .shadow(color: neon.opacity(opacity * 0.8), radius: radius, x: 0, y: 0)
            .shadow(color: neon.opacity(opacity * 0.5), radius: radius * 1.8, x: 0, y: 0)
    }
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            // ── Lock Screen ──
            HStack(spacing: 14) {
                FocusIcon(kind: context.state.kind, size: 22)
                FocusTime(state: context.state, stale: context.isStale)
                    .font(.focusTimer(40, weight: .light))
                    .foregroundStyle(.white)
                Spacer()
                RingOrCheck(state: context.state, stale: context.isStale, size: 36)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {

                // ── СЛЕВА: иконка категории ──
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 20)
                        .softNeon(4)
                        .padding(.leading, 4)
                        .padding(.top, 2)
                }

                // ── СПРАВА: "Name" (название категории) ──
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.kind.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.trailing, 6)
                        .padding(.top, 2)
                }

                // ── ЦЕНТР: дуга + таймер + "Fills up" ──
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: -6) {
                        Text("Fills up")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)

                        ZStack(alignment: .bottom) {
                            ExpandedArc(state: context.state, isStale: context.isStale)
                                .frame(height: 30)
                                .padding(.horizontal, 6)

                            FocusTime(state: context.state, stale: context.isStale)
                                .font(.focusTimer(30, weight: .light))
                                .offset(y: -2)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }

            } compactLeading: {
                // ── COMPACT LEFT: иконка + неон ──
                FocusIcon(kind: context.state.kind, size: 15)
                    .softNeon(6)
            } compactTrailing: {
                // ── COMPACT RIGHT: утолщённое кольцо ×2 + неон ──
                ThickRing(state: context.state, size: 22, lineWidth: 6)
                    .softNeon(8)
            } minimal: {
                ThickRing(state: context.state, size: 20, lineWidth: 5)
                    .softNeon(6)
            }
        }
    }
}
