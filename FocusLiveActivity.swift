import ActivityKit
import SwiftUI
import WidgetKit

typealias FocusState = FocusAttributes.ContentState

let neon = Color.white

struct FocusTime: View {
    let state: FocusState
    let stale: Bool

    var body: some View {
        if stale {
            Text("Готово")
        } else {
            Text(timerInterval: state.start...state.end, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.center)
        }
    }
}

struct FocusRing: View {
    let state: FocusState
    let size: CGFloat

    var body: some View {
        ProgressView(timerInterval: state.start...state.end, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(neon)
        .frame(width: size, height: size)
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

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            HStack(spacing: 14) {
                FocusIcon(kind: context.state.kind, size: 22)
                FocusTime(state: context.state, stale: context.isStale)
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(.white)
                Spacer()
                RingOrCheck(state: context.state, stale: context.isStale, size: 36)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    FocusIcon(kind: context.state.kind, size: 22)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RingOrCheck(state: context.state, stale: context.isStale, size: 30)
                }
                DynamicIslandExpandedRegion(.center) {
                    FocusTime(state: context.state, stale: context.isStale)
                        .font(.system(size: 34, weight: .ultraLight))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.kind.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                FocusIcon(kind: context.state.kind, size: 15)
            } compactTrailing: {
                RingOrCheck(state: context.state, stale: context.isStale, size: 22)
            } minimal: {
                FocusRing(state: context.state, size: 20)
            }
        }
    }
}
