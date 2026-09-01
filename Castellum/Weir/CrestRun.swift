import Foundation

/// Role: Weir. One History row — a day that crested, not a glass list.
struct CrestRun: Equatable, Sendable, Identifiable {
    var dayKey: DayKey
    var bowlMillilitres: Int
    var didHit: Bool

    var id: Int { dayKey.rawValue }

    var didCrest: Bool {
        bowlMillilitres > 0
    }
}
