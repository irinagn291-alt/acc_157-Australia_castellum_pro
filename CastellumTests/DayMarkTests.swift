import XCTest
@testable import Castellum

final class DayMarkTests: XCTestCase {
    func test_familyGoalClampAndRound() {
        XCTAssertEqual(DayMark.goal(weightKg: 70, activityBonus: 0), 2_300)
        XCTAssertEqual(DayMark.goal(weightKg: 70, activityBonus: 350), 2_650)
        XCTAssertEqual(DayMark.goal(weightKg: 70, activityBonus: 700), 3_000)
        XCTAssertEqual(DayMark.goal(weightKg: 20, activityBonus: 0), 1_200)
        XCTAssertEqual(DayMark.goal(weightKg: 200, activityBonus: 700), 5_000)
        XCTAssertEqual(ActivityBand.none.activityBonus, 0)
        XCTAssertEqual(ActivityBand.active.activityBonus, 350)
        XCTAssertEqual(ActivityBand.intense.activityBonus, 700)
        XCTAssertEqual(PourVolume.crestMillilitres, 250)

        let mark = DayMark(weightKg: 70, band: .active)
        XCTAssertEqual(mark.weightKg, 70)
        XCTAssertEqual(mark.activityBonus, 350)
        XCTAssertEqual(mark.goalMillilitres, 2_650)
        XCTAssertEqual(mark.bowlTarget, 2_300)
        XCTAssertEqual(mark.sumpTarget, 350)
    }

    func test_dayKeyIsYYYYMMDDFromStartOfDay() {
        let calendar = CisternCalendar.make()
        let noon = CisternCalendar.day(2026, 8, 29, calendar: calendar)
            .addingTimeInterval(12 * 3_600)
        let key = DayKey.from(noon, calendar: calendar)
        XCTAssertEqual(key.rawValue, 20260829)
        let late = CisternCalendar.day(2026, 8, 29, calendar: calendar)
            .addingTimeInterval(23 * 3_600 + 50 * 60)
        XCTAssertEqual(DayKey.from(late, calendar: calendar).rawValue, 20260829)
        XCTAssertEqual(key.start(calendar: calendar), calendar.startOfDay(for: noon))
    }
}
