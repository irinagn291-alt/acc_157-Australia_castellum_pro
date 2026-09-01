import Foundation
import Observation

/// Role: Weir. Owns DayMark, sump depth, and the fold. Views call methods; they never mutate the ADT.
@MainActor
@Observable
final class WeirStore {
    private(set) var mark: DayMark?
    private(set) var dayKey: DayKey
    private(set) var pours: [Pour]
    private(set) var vessels: WeirVessels
    private(set) var crestRuns: [CrestRun]
    private(set) var warning: WeirWarning?
    private(set) var onboardingComplete: Bool
    private(set) var lastWriteError: String?

    private let cistern: any WeirPersisting
    private let calendar: Calendar

    init(cistern: any WeirPersisting, calendar: Calendar = .current) {
        self.cistern = cistern
        self.calendar = calendar
        self.dayKey = DayKey(rawValue: 0)
        self.pours = []
        self.vessels = .idle(sumpTarget: 0)
        self.crestRuns = []
        self.onboardingComplete = false
    }

    func load() async {
        let loaded = await cistern.load()
        apply(loaded.ledger)
        warning = loaded.warning
        lastWriteError = nil
    }

    func settle(now: Date = Date()) {
        let today = DayKey.from(now, calendar: calendar)
        if dayKey.rawValue == 0 {
            dayKey = today
            refold()
            return
        }
        guard dayKey != today else { return }
        refreshCrest()
        pours = []
        dayKey = today
        refold()
        persistSoon()
    }

    func plant(_ mark: DayMark, now: Date = Date()) throws {
        guard mark.weightKg > 0 else { throw WeirRefusal.invalidWeight }
        self.mark = mark
        dayKey = DayKey.from(now, calendar: calendar)
        pours = []
        refold()
        persistSoon()
    }

    func retune(_ mark: DayMark, now: Date = Date()) throws {
        guard mark.weightKg > 0 else { throw WeirRefusal.invalidWeight }
        settle(now: now)
        self.mark = mark
        refold()
        refreshCrest()
        persistSoon()
    }

    func crestPour(
        _ millilitres: Int = PourVolume.crestMillilitres,
        now: Date = Date()
    ) throws {
        try commit(millilitres, path: .well, now: now)
    }

    func jumpWeir(_ millilitres: Int, now: Date = Date()) throws {
        try commit(millilitres, path: .jump, now: now)
    }

    func install(_ ledger: WeirLedger) {
        apply(ledger)
        warning = nil
        lastWriteError = nil
    }

    func markOnboardingComplete() {
        onboardingComplete = true
        persistSoon()
    }

    func reopenOnboarding() {
        onboardingComplete = false
        persistSoon()
    }

    func flush() async {
        do {
            try await cistern.save(snapshot)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        do {
            try await cistern.resetAllData()
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
        apply(.empty)
        warning = nil
    }

    func seedDemoIfNeeded(now: Date = Date()) async {
        #if targetEnvironment(simulator)
        if await cistern.hasDemoSeed() { return }
        apply(WeirSeed.ledger(now: now, calendar: calendar))
        do {
            try await cistern.save(snapshot)
            await cistern.markDemoSeed()
        } catch {
            lastWriteError = String(describing: error)
        }
        #endif
    }

    private var snapshot: WeirLedger {
        WeirLedger(
            mark: mark,
            dayKey: dayKey,
            pours: pours,
            crestRuns: crestRuns,
            onboardingComplete: onboardingComplete
        )
    }

    private func commit(_ millilitres: Int, path: PourPath, now: Date) throws {
        guard let mark else { throw WeirRefusal.noMark }
        settle(now: now)
        pours = try WeirFold.append(
            millilitres: millilitres,
            path: path,
            onto: pours,
            dayKey: dayKey,
            mark: mark
        )
        refold()
        refreshCrest()
        persistSoon()
    }

    private func apply(_ ledger: WeirLedger) {
        mark = ledger.mark
        dayKey = ledger.dayKey
        pours = ledger.pours
        crestRuns = ledger.crestRuns
        onboardingComplete = ledger.onboardingComplete
        refold()
    }

    private func refold() {
        if let mark {
            vessels = WeirFold.foldPours(pours, mark: mark)
        } else {
            vessels = .idle(sumpTarget: 0)
        }
    }

    private func refreshCrest() {
        guard mark != nil else { return }
        let folded = vessels
        if folded.bowl.millilitres > 0 || folded.didHit {
            let run = CrestRun(
                dayKey: dayKey,
                bowlMillilitres: folded.bowl.millilitres,
                didHit: folded.didHit
            )
            if let index = crestRuns.firstIndex(where: { $0.dayKey == dayKey }) {
                crestRuns[index] = run
            } else {
                crestRuns.append(run)
                crestRuns.sort { $0.dayKey > $1.dayKey }
            }
        } else {
            crestRuns.removeAll { $0.dayKey == dayKey }
        }
    }

    private func persistSoon() {
        let ledger = snapshot
        Task { await cistern.note(ledger) }
    }
}
