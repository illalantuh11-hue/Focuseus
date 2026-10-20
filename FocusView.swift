import ActivityKit
import SwiftUI
import UserNotifications

final class FocusController: ObservableObject {
    @Published var minutes = 25
    @Published var kind: FocusKind = .work
    @Published var startDate = Date()
    @Published var endDate: Date?
    private var activity: Activity<FocusAttributes>?

    func start() {
        let now = Date()
        let end = now.addingTimeInterval(Double(minutes) * 60)
        startDate = now
        endDate = end
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let content = ActivityContent(state: FocusState(start: now, end: end, kind: kind), staleDate: end)
            activity = try? Activity.request(attributes: FocusAttributes(title: "Фокус"), content: content)
        }
        scheduleNotification(after: Double(minutes) * 60)
    }

    func stop() {
        let a = activity
        activity = nil
        endDate = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Task { await a?.end(nil, dismissalPolicy: .immediate) }
    }

    private func scheduleNotification(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Фокус завершён"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            center.add(UNNotificationRequest(identifier: "focus-end", content: content, trigger: trigger))
        }
    }
}

struct FocusView: View {
    @StateObject private var f = FocusController()
    private let options = [15, 25, 50, 90]

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .light))
            .foregroundStyle(.white)
            .padding(.horizontal, 36)
            .padding(.vertical, 13)
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                if let end = f.endDate {
                    Image(systemName: f.kind.symbol).font(.system(size: 26, weight: .light))
                    Text(timerInterval: f.startDate...end, countsDown: true)
                        .font(.system(size: 76, weight: .ultraLight))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                    Button { f.stop() } label: { pill("Завершить") }
                } else {
                    Text(String(format: "%d:00", f.minutes))
                        .font(.system(size: 76, weight: .ultraLight))
                        .monospacedDigit()
                    HStack(spacing: 26) {
                        ForEach(options, id: \.self) { m in
                            Button { f.minutes = m } label: {
                                Text("\(m)")
                                    .font(.system(size: 20, weight: .light))
                                    .opacity(f.minutes == m ? 1 : 0.35)
                            }
                        }
                    }
                    HStack(spacing: 22) {
                        ForEach(FocusKind.allCases, id: \.self) { k in
                            Button { f.kind = k } label: {
                                Image(systemName: k.symbol)
                                    .font(.system(size: 22, weight: .light))
                                    .opacity(f.kind == k ? 1 : 0.35)
                            }
                        }
                    }
                    Text(f.kind.title)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                    Button { f.start() } label: { pill("Начать") }
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding()
        }
    }
}
