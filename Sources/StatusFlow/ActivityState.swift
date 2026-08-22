import SwiftUI

enum ActivityState: String, Codable, CaseIterable, Identifiable {
    case work
    case rest
    case study

    var id: Self { self }

    var title: String {
        switch self {
        case .work: "工作"
        case .rest: "休息"
        case .study: "學習"
        }
    }

    var symbol: String {
        switch self {
        case .work: "briefcase.fill"
        case .rest: "cup.and.saucer.fill"
        case .study: "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: Color(red: 97 / 255, green: 129 / 255, blue: 155 / 255)
        case .rest: Color(red: 235 / 255, green: 116 / 255, blue: 93 / 255)
        case .study: Color(red: 210 / 255, green: 147 / 255, blue: 54 / 255)
        }
    }
}

struct ActivitySession: Codable, Identifiable, Equatable {
    var id = UUID()
    var state: ActivityState
    var startedAt: Date
    var endedAt: Date?
    var pauses: [ActivityPause]?
}

struct ActivityPause: Codable, Equatable {
    var startedAt: Date
    var endedAt: Date?
}
