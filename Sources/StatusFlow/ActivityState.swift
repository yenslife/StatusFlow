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
        case .work: .blue
        case .rest: .green
        case .study: .orange
        }
    }
}

struct ActivitySession: Codable, Identifiable, Equatable {
    var id = UUID()
    var state: ActivityState
    var startedAt: Date
    var endedAt: Date?
}
