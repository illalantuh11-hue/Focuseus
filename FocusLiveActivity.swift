import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

let neon = Color.white

struct FocusTime: View {
    let state: FocusSnap
    let stale: Bool

    private var key: Int {
        if state.pausedRemaining != nil { return 0 }
        return stale ? 2 : 1
    }

    var body: some View {
        Group {
            if let rem = state.pausedRemaining {
                Text(focusFormat(rem)).monospacedDigit()
            } else if stale {
                Text("Готово")
            } else {
                Text(timerInterval: state.start...state.end, countsDown: true)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            }
        }
        .id(key)
        .transition(.blurReplace)
    }
}

/// Ring made of two stacked circular progress views, so the line is about twice as thick.
struct FocusRing: View {
    let state: FocusSnap
    let size: CGFloat
    var glow: CGFloat = 5

    @ViewBuilder
    private func one(_ d: CGFloat) -> some View {
        Group {
            if let rem = state.pausedRemaining {
                ProgressView(value: rem, total: max(state.total, 1))
            } else {
                ProgressView(timerInterval: state.start...state.end, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.circular)
        .tint(neon)
        .frame(width: d, height: d)
    }

    var body: some View {
        ZStack {
            one(size)
            one(size - 3)
        }
        .frame(width: size, height: size)
        .shadow(color: neon.opacity(0.9), radius: 2)
        .shadow(color: neon.opacity(0.5), radius: glow)
    }
}

struct FocusBar: View {
    let state: FocusSnap

    var body: some View {
        Group {
            if let rem = state.pausedRemaining {
                ProgressView(value: rem, total: max(state.total, 1))
            } else {
                ProgressView(timerInterval: state.start...state.end, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(neon)
        .scaleEffect(x: 1, y: 2.5)
        .shadow(color: neon.opacity(0.8), radius: 3)
        .padding(.vertical, 4)
    }
}

struct ArcPoint {
    let x: CGFloat
    let y: CGFloat
    let angle: Double
}

/// Evenly spaced points (by arc length) along the top half of an ellipse, left to right.
func arcPoints(count n: Int, a: CGFloat, b: CGFloat) -> [ArcPoint] {
    let steps = 400
    let ad = Double(a)
    let bd = Double(b)
    func pos(_ t: Double) -> (Double, Double) { (ad * cos(t), -bd * sin(t)) }

    var thetas: [Double] = [Double.pi]
    var cum: [Double] = [0]
    var prev = pos(Double.pi)
    for k in 1...steps {
        let t: Double = Double.pi - Double.pi * Double(k) / Double(steps)
        let p = pos(t)
        cum.append(cum[k - 1] + hypot(p.0 - prev.0, p.1 - prev.1))
        thetas.append(t)
        prev = p
    }
    let total = cum[steps]

    var out: [ArcPoint] = []
    var j = 0
    for i in 0..<n {
        let target = total * (Double(i) + 0.5) / Double(n)
        while j < steps - 1 && cum[j + 1] < target { j += 1 }
        let seg = cum[j + 1] - cum[j]
        let f = seg > 0 ? (target - cum[j]) / seg : 0
        let t = thetas[j] + (thetas[j + 1] - thetas[j]) * f
        let p = pos(t)
        let ang = atan2(bd * cos(t), ad * sin(t)) * 180 / Double.pi
        out.append(ArcPoint(x: CGFloat(p.0), y: CGFloat(p.1), angle: ang))
    }
    return out
}

/// Wide arc that fills left to right. Built from small progress bars laid along the arc,
/// because only system progress views keep animating on their own in a Live Activity.
struct ArcGauge: View {
    let state: FocusSnap
    var a: CGFloat = 140
    var b: CGFloat = 46
    private let n = 26

    @ViewBuilder
    private func segment(_ i: Int, dur: Double) -> some View {
        if let rem = state.pausedRemaining {
            let elapsed = max(state.total, 1) - rem
            let f = min(max(elapsed / dur - Double(i), 0), 1)
            ProgressView(value: f)
        } else {
            let s0 = state.start.addingTimeInterval(dur * Double(i))
            ProgressView(timerInterval: s0...s0.addingTimeInterval(dur), countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        }
    }

    var body: some View {
        let pts = arcPoints(count: n, a: a, b: b)
        let dur = max(state.total, 1) / Double(n)
        ZStack {
            ForEach(0..<n, id: \.self) { i in
                segment(i, dur: dur)
                    .progressViewStyle(.linear)
                    .tint(neon)
                    .frame(width: 11)
                    .scaleEffect(x: 1, y: 2)
                    .rotationEffect(.degrees(pts[i].angle))
                    .offset(x: pts[i].x, y: pts[i].y + b / 2)
            }
        }
        .frame(width: 2 * a + 20, height: b + 16)
        .shadow(color: neon.opacity(0.6), radius: 3)
    }
}

struct FocusIcon: View {
    let kind: FocusKind
    var size: CGFloat = 15

    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.6), radius: 3)
    }
}

struct PauseButton: View {
    let paused: Bool

    var body: some View {
        Button(intent: TogglePauseIntent()) {
            Image(systemName: paused ? "play.fill" : "pause.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.6), radius: 3)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}

struct RingOrCheck: View {
    let state: FocusSnap
    let stale: Bool
    let size: CGFloat

    var body: some View {
        Group {
            if stale && state.pausedRemaining == nil {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.6, weight: .semibold))
                    .foregroundStyle(neon)
                    .shadow(color: neon.opacity(0.9), radius: 3)
            } else {
                FocusRing(state: state, size: size, glow: size < 25 ? 2.5 : 5)
            }
        }
        .id(stale)
        .transition(.blurReplace)
    }
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            VStack(spacing: 10) {
                HStack {
                    FocusIcon(kind: context.state.kind, size: 22)
                    Spacer()
                    PauseButton(paused: context.state.pausedRemaining != nil)
                }
                ArcGauge(state: context.state)
                FocusTime(state: context.state, stale: context.isStale)
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(.white)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 22)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PauseButton(paused: context.state.pausedRemaining != nil)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.kind.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: -4) {
                        ArcGauge(state: context.state)
                        FocusTime(state: context.state, stale: context.isStale)
                            .font(.system(size: 30, weight: .ultraLight))
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                FocusIcon(kind: context.state.kind, size: 16)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                RingOrCheck(state: context.state, stale: context.isStale, size: 20)
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 5)
            } minimal: {
                FocusRing(state: context.state, size: 18, glow: 2.5)
                    .frame(width: 20, height: 20)
            }
        }
    }
}
