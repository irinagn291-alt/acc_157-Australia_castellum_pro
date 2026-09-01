import Foundation

/// Role: Weir. Simulator-only mark plus a shelf of prior crest-runs. Device never seeds.
enum WeirSeed {
    static func ledger(now: Date, calendar: Calendar) -> WeirLedger {
        let mark = DayMark(weightKg: 70, band: .active)
        let today = DayKey.from(now, calendar: calendar)
        let pours = [
            Pour(dayKey: today, millilitres: PourVolume.crestMillilitres),
            Pour(dayKey: today, millilitres: PourVolume.crestMillilitres),
            Pour(dayKey: today, millilitres: PourVolume.crestMillilitres),
        ]
        let todayFold = WeirFold.foldPours(pours, mark: mark)
        var crestRuns = [
            CrestRun(
                dayKey: today,
                bowlMillilitres: todayFold.bowl.millilitres,
                didHit: todayFold.didHit
            )
        ]
        for (offset, prior) in priorRuns.enumerated() {
            let daysBack = offset + 1
            let day = calendar.date(byAdding: .day, value: -daysBack, to: now).map {
                DayKey.from($0, calendar: calendar)
            } ?? DayKey(rawValue: today.rawValue - daysBack)
            crestRuns.append(
                CrestRun(dayKey: day, bowlMillilitres: prior.bowl, didHit: prior.hit)
            )
        }
        return WeirLedger(
            mark: mark,
            dayKey: today,
            pours: pours,
            crestRuns: crestRuns,
            onboardingComplete: true
        )
    }

    private static let priorRuns: [(bowl: Int, hit: Bool)] = [
        (2_000, false),
        (2_450, true),
        (800, false),
        (2_300, true),
        (1_150, false),
        (2_800, true),
        (550, false),
        (1_900, false),
        (2_650, true),
        (950, false),
        (1_700, false),
        (2_150, false),
        (3_100, true),
    ]
}
