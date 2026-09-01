import Foundation

/// Role: DayMark. Activity writes the sweat-sump depth — 0, 350 or 700 ml — not a fatter single ring.
enum ActivityBand: String, Codable, Sendable, CaseIterable {
    case none
    case active
    case intense

    var activityBonus: Int {
        switch self {
        case .none: 0
        case .active: 350
        case .intense: 700
        }
    }
}
