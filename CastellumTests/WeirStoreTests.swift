import XCTest
@testable import Castellum

@MainActor
final class WeirStoreTests: XCTestCase {
    private let calendar = CisternCalendar.make()
    private let now = CisternCalendar.day(2026, 8, 29, calendar: CisternCalendar.make())

    func test_emptyPopulatedInvalidCrestPour() async {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        XCTAssertThrowsError(try store.crestPour(now: now)) { error in
            XCTAssertEqual(error as? WeirRefusal, .noMark)
        }

        XCTAssertNoThrow(try store.plant(DayMark(weightKg: 70, band: .active), now: now))
        XCTAssertEqual(store.vessels.weir, .openSump)
        XCTAssertNoThrow(try store.crestPour(now: now))
        XCTAssertEqual(store.pours.count, 1)
        XCTAssertEqual(store.pours[0].millilitres, 250)
        XCTAssertEqual(store.vessels.sump.remainingMillilitres, 100)

        XCTAssertThrowsError(try store.crestPour(0, now: now)) { error in
            XCTAssertEqual(error as? WeirRefusal, .invalidVolume)
        }
        XCTAssertEqual(store.pours.count, 1)
    }

    func test_jumpWeirIsRefusedWhileSumpOpen() async {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        try? store.plant(DayMark(weightKg: 70, band: .active), now: now)
        XCTAssertThrowsError(try store.jumpWeir(250, now: now)) { error in
            XCTAssertEqual(error as? WeirRefusal, .skipsOpenSump)
        }
        XCTAssertTrue(store.pours.isEmpty)
        XCTAssertEqual(store.vessels.weir, .openSump)

        try? store.crestPour(350, now: now)
        XCTAssertEqual(store.vessels.weir, .cresting)
        XCTAssertNoThrow(try store.jumpWeir(250, now: now))
        XCTAssertEqual(store.vessels.bowl.millilitres, 250)
        XCTAssertEqual(store.crestRuns.count, 1)
        XCTAssertEqual(store.crestRuns[0].bowlMillilitres, 250)
    }

    func test_retuneRefoldsPoursWithoutStoringTotals() async {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        try? store.plant(DayMark(weightKg: 70, band: .intense), now: now)
        try? store.crestPour(now: now)
        XCTAssertEqual(store.vessels.weir, .openSump)
        XCTAssertEqual(store.mark?.activityBonus, 700)

        XCTAssertNoThrow(try store.retune(DayMark(weightKg: 70, band: .none), now: now))
        XCTAssertEqual(store.vessels.weir, .cresting)
        XCTAssertEqual(store.vessels.bowl.millilitres, 250)
        XCTAssertEqual(store.vessels.sump.remainingMillilitres, 0)
        XCTAssertEqual(store.pours.count, 1)
    }

    func test_settleRollsDayAndKeepsPriorCrestRun() async {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        try? store.plant(DayMark(weightKg: 70, band: .active), now: now)
        try? store.crestPour(250, now: now)
        try? store.crestPour(250, now: now)
        XCTAssertEqual(store.crestRuns.count, 1)

        let next = CisternCalendar.day(2026, 8, 30, calendar: calendar)
        store.settle(now: next)
        XCTAssertEqual(store.dayKey.rawValue, 20260830)
        XCTAssertTrue(store.pours.isEmpty)
        XCTAssertEqual(store.vessels.weir, .openSump)
        XCTAssertEqual(store.crestRuns.count, 1)
        XCTAssertEqual(store.crestRuns[0].dayKey.rawValue, 20260829)
    }

    func test_invalidWeightIsRefused() async {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        XCTAssertThrowsError(try store.plant(DayMark(weightKg: 0, band: .none), now: now)) { error in
            XCTAssertEqual(error as? WeirRefusal, .invalidWeight)
        }
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async {
        let cistern = WeirMemoryCistern()
        let store = WeirStore(cistern: cistern, calendar: calendar)
        await store.seedDemoIfNeeded(now: now)
        await store.seedDemoIfNeeded(now: now)
        XCTAssertEqual(store.mark?.weightKg, 70)
        XCTAssertEqual(store.mark?.activityBonus, 350)
        XCTAssertTrue(store.onboardingComplete)
        XCTAssertEqual(store.pours.count, 3)
        XCTAssertEqual(store.vessels.bowl.millilitres, 400)
        XCTAssertEqual(store.crestRuns.count, 14)
        XCTAssertEqual(Set(store.crestRuns.map(\.dayKey)).count, 14)
        let seeded = await cistern.hasDemoSeed()
        XCTAssertTrue(seeded)
    }
    #endif
}
