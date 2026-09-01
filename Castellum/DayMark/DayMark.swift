import Foundation

/// Role: DayMark. HydrationGoal as a computed weir mark from weight and band. Views never type a goal.
struct DayMark: Equatable, Sendable {
    var weightKg: Double
    var band: ActivityBand

    var activityBonus: Int { band.activityBonus }
    var sumpTarget: Int { band.activityBonus }

    var goalMillilitres: Int {
        Self.goal(weightKg: weightKg, activityBonus: activityBonus)
    }

    var bowlTarget: Int {
        goalMillilitres - sumpTarget
    }

    static let outset = DayMark(weightKg: 70, band: .none)

    static func goal(weightKg: Double, activityBonus: Int) -> Int {
        let raw = weightKg * 33 + Double(activityBonus)
        let clamped = min(5_000, max(1_200, raw))
        return Int((clamped / 50).rounded()) * 50
    }
}
