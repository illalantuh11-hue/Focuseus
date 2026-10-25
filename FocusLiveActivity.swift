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
            Circle()
                .fill(neon)
                .frame(width: max(size * 0.2, 3), height: max(size * 0.2, 3))
                .shadow(color: neon.opacity(0.9), radius: 2)
        }
        .frame(width: size, height: size)
        .shadow(color: neon.opacity(glow > 0 ? 0.9 : 0), radius: 2)
        .shadow(color: neon.opacity(glow > 0 ? 0.5 : 0), radius: max(glow, 1))
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
        .scaleEffect(x: 1, y: 2.2)
        .shadow(color: neon.opacity(0.8), radius: 3)
        .padding(.vertical, 4)
    }
}

struct FocusIcon: View {
    let kind: FocusKind
    var size: CGFloat = 15
    var glow = true

    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(glow ? 0.6 : 0), radius: 3)
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
                .background(Circle().fill(Color.white.opacity(0.18)))
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
                ZStack {
                    Circle().stroke(neon, lineWidth: 2)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(neon)
                }
                .frame(width: size - 2, height: size - 2)
                .frame(width: size, height: size)
            } else {
                FocusRing(state: state, size: size, glow: size < 25 ? 0 : 5)
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
                FocusBar(state: context.state)
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
                    VStack(spacing: 10) {
                        FocusBar(state: context.state)
                        FocusTime(state: context.state, stale: context.isStale)
                            .font(.system(size: 34, weight: .ultraLight))
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                FocusIcon(kind: context.state.kind, size: 16, glow: false)
                    .frame(width: 20, height: 20)
                    .padding(.leading, 3)
            } compactTrailing: {
                RingOrCheck(state: context.state, stale: context.isStale, size: 20)
                    .frame(width: 20, height: 20)
            } minimal: {
                FocusRing(state: context.state, size: 18, glow: 0)
                    .frame(width: 20, height: 20)
            }
        }
    }
}
