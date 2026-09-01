import XCTest
@testable import Castellum

final class WeirCisternTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = CisternCalendar.make()

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "ctm.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesFoldAndCrestRuns() async throws {
        let cistern = makeCistern()
        let now = CisternCalendar.day(2026, 8, 29, calendar: calendar)
        var ledger = WeirSeed.ledger(now: now, calendar: calendar)
        ledger.pours.append(Pour(dayKey: DayKey(rawValue: 20260829), millilitres: 250))
        try await cistern.save(ledger)

        let relaunched = makeCistern()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.ledger.mark?.weightKg, 70)
        XCTAssertEqual(loaded.ledger.mark?.band, .active)
        XCTAssertEqual(loaded.ledger.pours.count, 4)
        XCTAssertEqual(loaded.ledger.crestRuns.count, 14)
        XCTAssertEqual(Set(loaded.ledger.crestRuns.map(\.dayKey)).count, 14)
        XCTAssertTrue(loaded.ledger.onboardingComplete)
        XCTAssertNotNil(defaults.data(forKey: WeirKey.document))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("weir.json").path)
        )

        let folded = WeirFold.foldPours(loaded.ledger.pours, mark: try XCTUnwrap(loaded.ledger.mark))
        XCTAssertEqual(folded.sump.remainingMillilitres, 0)
        XCTAssertEqual(folded.bowl.millilitres, 650)
        XCTAssertEqual(folded.weir, .cresting)
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let cistern = makeCistern()
        let ledger = WeirSeed.ledger(
            now: CisternCalendar.day(2026, 8, 29, calendar: calendar),
            calendar: calendar
        )
        try await cistern.save(ledger)
        if let good = defaults.data(forKey: WeirKey.document) {
            defaults.set(good, forKey: WeirKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: WeirKey.document)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("weir.json"))

        let loaded = await makeCistern().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.ledger.mark?.weightKg, ledger.mark?.weightKg)
    }

    func test_corruptWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: WeirKey.document)
        let loaded = await makeCistern().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertNil(loaded.ledger.mark)
    }

    func test_resetAllDataClearsDocument() async throws {
        let cistern = makeCistern()
        try await cistern.save(
            WeirSeed.ledger(
                now: CisternCalendar.day(2026, 8, 29, calendar: calendar),
                calendar: calendar
            )
        )
        try await cistern.resetAllData()
        let loaded = await cistern.load()
        XCTAssertNil(loaded.ledger.mark)
        XCTAssertNil(defaults.data(forKey: WeirKey.document))
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("weir.json").path)
        )
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try WeirCodec.encode(.empty)
        let decoded = try WeirCodec.decode(data)
        XCTAssertEqual(decoded.dayKey.rawValue, 0)

        XCTAssertThrowsError(try WeirCodec.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? WeirCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try WeirCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? WeirCodec.Failure, .corrupt)
        }
    }

    @MainActor
    func test_storeCrestAndReloadThroughCistern() async throws {
        let cistern = makeCistern()
        let store = WeirStore(cistern: cistern, calendar: calendar)
        let now = CisternCalendar.day(2026, 8, 29, calendar: calendar)
        try store.plant(DayMark(weightKg: 70, band: .active), now: now)
        try store.crestPour(now: now)
        try store.crestPour(now: now)
        await store.flush()

        let relaunched = WeirStore(cistern: makeCistern(), calendar: calendar)
        await relaunched.load()
        XCTAssertEqual(relaunched.pours.count, 2)
        XCTAssertEqual(relaunched.vessels.weir, .cresting)
        XCTAssertEqual(relaunched.vessels.bowl.millilitres, 150)
        XCTAssertEqual(relaunched.crestRuns.count, 1)
        XCTAssertEqual(relaunched.mark?.activityBonus, 350)
    }

    private func makeCistern() -> WeirCistern {
        WeirCistern(directory: directory, defaultsSuiteName: suiteName, writeDelayNanoseconds: 0)
    }
}
