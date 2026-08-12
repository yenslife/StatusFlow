import Combine
import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var sessions: [ActivitySession] = []
    @Published private(set) var now = Date()
    private var timer: AnyCancellable?
    private let calendar = Calendar.autoupdatingCurrent

    struct DailyReportEntry: Identifiable {
        let day: Date
        let state: ActivityState
        let duration: TimeInterval

        var id: String { "\(day.timeIntervalSince1970)-\(state.rawValue)" }
        var hours: Double { duration / 3600 }
    }

    init() {
        load()
        if sessions.last(where: { $0.endedAt == nil }) == nil {
            sessions.append(ActivitySession(state: .work, startedAt: Date()))
            save()
        }

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.now = date }
    }

    var currentSession: ActivitySession {
        sessions.last(where: { $0.endedAt == nil })
            ?? ActivitySession(state: .work, startedAt: now)
    }

    var currentState: ActivityState { currentSession.state }

    var currentElapsed: TimeInterval {
        max(0, now.timeIntervalSince(currentSession.startedAt))
    }

    var menuBarTitle: String {
        "\(currentState.title) \(Self.shortDuration(currentElapsed))"
    }

    func switchTo(_ state: ActivityState) {
        guard state != currentState else { return }
        let date = Date()
        if let index = sessions.lastIndex(where: { $0.endedAt == nil }) {
            sessions[index].endedAt = date
        }
        sessions.append(ActivitySession(state: state, startedAt: date))
        now = date
        save()
    }

    func durationToday(for state: ActivityState) -> TimeInterval {
        duration(for: state, on: now)
    }

    func duration(for state: ActivityState, on day: Date) -> TimeInterval {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? day

        return sessions
            .filter { $0.state == state }
            .reduce(0) { total, session in
                let start = max(session.startedAt, startOfDay)
                let end = min(session.endedAt ?? now, endOfDay)
                return total + max(0, end.timeIntervalSince(start))
            }
    }

    func reportEntries(numberOfDays: Int = 7) -> [DailyReportEntry] {
        let today = calendar.startOfDay(for: now)
        let days = (0..<numberOfDays).compactMap {
            calendar.date(byAdding: .day, value: $0 - numberOfDays + 1, to: today)
        }

        return days.flatMap { day in
            ActivityState.allCases.map { state in
                DailyReportEntry(day: day, state: state, duration: duration(for: state, on: day))
            }
        }
    }

    func clearHistory() {
        sessions = [ActivitySession(state: currentState, startedAt: Date())]
        save()
    }

    static func clockDuration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    static func shortDuration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    static func readableDuration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval) / 60)
        if minutes < 60 { return "\(minutes) 分鐘" }
        return "\(minutes / 60) 小時 \(minutes % 60) 分鐘"
    }

    private var storageURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".StatusFlow", isDirectory: true)
            .appendingPathComponent("sessions.json")
    }

    private var legacyStorageURLs: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let projectURL = home
            .appendingPathComponent("SideProject", isDirectory: true)
            .appendingPathComponent("StatusFlow", isDirectory: true)
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("sessions.json")
        let applicationSupportURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StatusFlow", isDirectory: true)
            .appendingPathComponent("sessions.json")
        return [projectURL, applicationSupportURL]
    }

    private func load() {
        do {
            let sourceURL = ([storageURL] + legacyStorageURLs)
                .first { FileManager.default.fileExists(atPath: $0.path) }
                ?? storageURL
            let data = try Data(contentsOf: sourceURL)
            sessions = try JSONDecoder().decode([ActivitySession].self, from: data)

            // 找到舊版紀錄時，讀取後自動寫入新的隱藏資料夾。
            if sourceURL != storageURL {
                save()
            }
        } catch {
            sessions = []
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            assertionFailure("無法儲存狀態紀錄：\(error)")
        }
    }
}
