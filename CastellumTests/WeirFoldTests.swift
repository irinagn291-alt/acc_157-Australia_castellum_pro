import XCTest
@testable import Castellum

final class WeirFoldTests: XCTestCase {
    private let mark = DayMark(weightKg: 70, band: .active)
    private let day = DayKey(rawValue: 20260829)

    func test_foldIsADTNotAGlassList() {
        let empty = WeirFold.foldPours([], mark: mark)
        XCTAssertEqual(empty.weir, .openSump)
        XCTAssertEqual(empty.sump.remainingMillilitres, 350)
        XCTAssertEqual(empty.bowl.millilitres, 0)

        let first = [Pour(dayKey: day, millilitres: 250)]
        let open = WeirFold.foldPours(first, mark: mark)
        XCTAssertEqual(open.weir, .openSump)
        XCTAssertEqual(open.sump.remainingMillilitres, 100)
        XCTAssertEqual(open.bowl.millilitres, 0)

        let second = first + [Pour(dayKey: day, millilitres: 250)]
        let cresting = WeirFold.foldPours(second, mark: mark)
        XCTAssertEqual(cresting.weir, .cresting)
        XCTAssertEqual(cresting.sump.remainingMillilitres, 0)
        XCTAssertEqual(cresting.bowl.millilitres, 150)
        XCTAssertFalse(cresting.didHit)

        XCTAssertEqual(WeirFold.foldPours(first, mark: mark).weir, .openSump)
        XCTAssertEqual(first.count, 1)
    }

    func test_refuseSkipLeavesSumpOpen() throws {
        XCTAssertThrowsError(
            try WeirFold.append(millilitres: 250, path: .jump, onto: [], dayKey: day, mark: mark)
        ) { error in
            XCTAssertEqual(error as? WeirRefusal, .skipsOpenSump)
        }

        let filled = try WeirFold.append(
            millilitres: 250,
            path: .well,
            onto: [],
            dayKey: day,
            mark: mark
        )
        XCTAssertEqual(filled.count, 1)
        XCTAssertEqual(WeirFold.foldPours(filled, mark: mark).weir, .openSump)
        XCTAssertEqual(WeirFold.foldPours(filled, mark: mark).bowl.millilitres, 0)
    }

    func test_completePredicateNeedsDrySumpAndBowlTarget() {
        let sumpOnly = [Pour(dayKey: day, millilitres: 350)]
        let dry = WeirFold.foldPours(sumpOnly, mark: mark)
        XCTAssertEqual(dry.weir, .cresting)
        XCTAssertFalse(WeirFold.dayIsComplete(dry, mark: mark))

        let short = sumpOnly + [Pour(dayKey: day, millilitres: 2_299)]
        let almost = WeirFold.foldPours(short, mark: mark)
        XCTAssertEqual(almost.bowl.millilitres, 2_299)
        XCTAssertEqual(almost.weir, .cresting)
        XCTAssertFalse(WeirFold.dayIsComplete(almost, mark: mark))

        let hit = short + [Pour(dayKey: day, millilitres: 1)]
        let full = WeirFold.foldPours(hit, mark: mark)
        XCTAssertEqual(full.weir, .full)
        XCTAssertTrue(WeirFold.dayIsComplete(full, mark: mark))
        XCTAssertTrue(full.didHit)
    }

    func test_noneBandStartsCrestingAndDefaultPourIs250() throws {
        let quiet = DayMark(weightKg: 70, band: .none)
        let idle = WeirFold.foldPours([], mark: quiet)
        XCTAssertEqual(idle.weir, .cresting)
        XCTAssertEqual(idle.sump.remainingMillilitres, 0)
        XCTAssertEqual(quiet.activityBonus, 0)

        let poured = try WeirFold.append(
            millilitres: PourVolume.crestMillilitres,
            path: .well,
            onto: [],
            dayKey: day,
            mark: quiet
        )
        let vessels = WeirFold.foldPours(poured, mark: quiet)
        XCTAssertEqual(vessels.bowl.millilitres, 250)
        XCTAssertEqual(vessels.weir, .cresting)
    }

    func test_invalidVolumeIsRefused() {
        XCTAssertThrowsError(
            try WeirFold.append(millilitres: 0, path: .well, onto: [], dayKey: day, mark: mark)
        ) { error in
            XCTAssertEqual(error as? WeirRefusal, .invalidVolume)
        }
        XCTAssertThrowsError(
            try WeirFold.append(millilitres: -10, path: .well, onto: [], dayKey: day, mark: mark)
        ) { error in
            XCTAssertEqual(error as? WeirRefusal, .invalidVolume)
        }
    }
}
