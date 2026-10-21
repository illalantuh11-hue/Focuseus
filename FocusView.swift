import ActivityKit
import SwiftUI
import UserNotifications

final class FocusController: ObservableObject {
    @Published var minutes = 25
    @Published var kind: FocusKind = .work
    @Published var startDate = Date()
    @Published var endDate: Date?
    @Published var pausedRemaining: Double?
    private var activity: Activity<FocusAttributes>?
    private var observer: Task<Void, Never>?

    func start() {
        let now = Date()
        let total = Double(minutes) * 60
        let end = now.addingTimeInterval(total)
        startDate = now
        endDate = end
        pausedRemaining = nil
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let state = FocusSnap(start: now, end: end, kind: kind, pausedRemaining: nil, total: total)
            let content = ActivityContent(state: state, staleDate: end)
            activity = try? Activity.request(attributes: FocusAttributes(title: "Фокус"), content: content)
            if let a = activity { observe(a) }
        }
        scheduleNotification(after: total)
    }

    func togglePause() {
        if activity == nil, let end = endDate {
            // no live activity: pause locally only
            if let rem = pausedRemaining {
                let newEnd = Date().addingTimeInterval(rem)
                endDate = newEnd
                startDate = newEnd.addingTimeInterval(-Double(minutes) * 60)
                pausedRemaining = nil
                scheduleNotification(after: rem)
            } else {
                pausedRemaining = max(0, end.timeIntervalSinceNow)
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            return
        }
        Task { await focusTogglePause() }
    }

    func stop() {
        observer?.cancel()
        observer = nil
        let a = activity
        activity = nil
        endDate = nil
        pausedRemaining = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Task { await a?.end(nil, dismissalPolicy: .immediate) }
    }

    private func observe(_ a: Activity<FocusAttributes>) {
        observer?.cancel()
        observer = Task { [weak self] in
            for await c in a.contentUpdates {
                let s = c.state
                await MainActor.run {
                    self?.startDate = s.start
                    self?.endDate = s.end
                    self?.pausedRemaining = s.pausedRemaining
                }
            }
        }
    }

    private func scheduleNotification(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Фокус завершён"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
            center.add(UNNotificationRequest(identifier: "focus-end", content: content, trigger: trigger))
        }
    }
}

struct FocusView: View {
    @StateObject private var f = FocusController()
    private let options = [15, 25, 50, 90]

    private func pill(_ text: String, h: CGFloat = 36) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .light))
            .foregroundStyle(.white)
            .padding(.horizontal, h)
            .padding(.vertical, 13)
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .white.opacity(0.35), radius: 6)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                if let end = f.endDate {
                    VStack(spacing: 40) {
                        Image(systemName: f.kind.symbol)
                            .font(.system(size: 26, weight: .light))
                            .shadow(color: .white.opacity(0.7), radius: 6)
                        Group {
                            if let rem = f.pausedRemaining {
                                Text(focusFormat(rem))
                            } else {
                                Text(timerInterval: f.startDate...end, countsDown: true)
                            }
                        }
                        .font(.system(size: 76, weight: .ultraLight))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .shadow(color: .white.opacity(0.35), radius: 10)
                        HStack(spacing: 14) {
                            Button { f.togglePause() } label: {
                                pill(f.pausedRemaining == nil ? "Пауза" : "Продолжить", h: 24)
                            }
                            Button {
                                withAnimation(.easeInOut(duration: 0.45)) { f.stop() }
                            } label: { pill("Завершить", h: 24) }
                        }
                    }
                    .transition(.blurReplace)
                } else {
                    VStack(spacing: 40) {
                        Text(String(format: "%d:00", f.minutes))
                            .font(.system(size: 76, weight: .ultraLight))
                            .monospacedDigit()
                            .shadow(color: .white.opacity(0.35), radius: 10)
                        HStack(spacing: 26) {
                            ForEach(options, id: \.self) { m in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) { f.minutes = m }
                                } label: {
                                    Text("\(m)")
                                        .font(.system(size: 20, weight: .light))
                                        .opacity(f.minutes == m ? 1 : 0.35)
                                }
                            }
                        }
                        HStack(spacing: 22) {
                            ForEach(FocusKind.allCases, id: \.self) { k in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) { f.kind = k }
                                } label: {
                                    Image(systemName: k.symbol)
                                        .font(.system(size: 22, weight: .light))
                                        .opacity(f.kind == k ? 1 : 0.35)
                                        .shadow(color: .white.opacity(f.kind == k ? 0.7 : 0), radius: 5)
                                }
                            }
                        }
                        Text(f.kind.title)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                        Button {
                            withAnimation(.easeInOut(duration: 0.45)) { f.start() }
                        } label: { pill("Начать") }
                    }
                    .transition(.blurReplace)
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding()
        }
    }
}
