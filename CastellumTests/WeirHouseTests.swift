import XCTest
@testable import Castellum

@MainActor
final class WeirHouseTests: XCTestCase {
    func test_screensConstructWithoutArguments() {
        _ = WellDialView()
        _ = CrestHistoryView()
        _ = CisternSettingsView()
        _ = SweatSumpView()
        _ = CisternOnboardingView()
        _ = WeirHouseView()
        _ = ContentView()
    }

    func test_weirPagesAreDialHistorySettings() {
        XCTAssertEqual(WeirPage.allCases.map(\.rawValue), ["dial", "history", "settings"])
        XCTAssertFalse(WeirPage.allCases.map(\.rawValue).contains("game"))
    }

    func test_voiceCoversEveryWeirCase() {
        XCTAssertEqual(WeirVoice.weir(.openSump), "Sump open")
        XCTAssertEqual(WeirVoice.weir(.cresting), "Cresting")
        XCTAssertEqual(WeirVoice.weir(.full), "Weir full")
        XCTAssertEqual(WeirVoice.hatch(.openSump), "Hatch ajar")
        XCTAssertEqual(WeirVoice.hatch(.cresting), "Hatch shut")
        XCTAssertEqual(WeirVoice.hatch(.full), "Hatch shut")
    }

    func test_dialReadsFoldNotAGlassList() {
        let calendar = CisternCalendar.make()
        let now = CisternCalendar.day(2026, 8, 29, calendar: calendar)
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        try? store.plant(DayMark(weightKg: 70, band: .active), now: now)
        let view = WellDialView(store: store)
        XCTAssertEqual(view.store.vessels.weir, .openSump)
        XCTAssertEqual(view.store.vessels.sump.remainingMillilitres, 350)
        XCTAssertEqual(view.store.mark?.goalMillilitres, 2_650)
        XCTAssertEqual(PourVolume.crestMillilitres, 250)
        try? store.crestPour(now: now)
        XCTAssertEqual(view.store.vessels.weir, .openSump)
        XCTAssertEqual(view.store.vessels.bowl.millilitres, 0)
        XCTAssertEqual(view.store.pours.count, 1)
    }

    func test_formattersUseLocaleNotInterpolation() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(CisternFormat.millilitres(2_650, locale: locale), "2,650 ml")
        XCTAssertEqual(CisternFormat.kilograms(70, locale: locale), "70 kg")
        XCTAssertEqual(CisternFormat.parseKilograms("70.5", locale: locale), 70.5)
        XCTAssertNil(CisternFormat.parseKilograms("-3", locale: locale))
        XCTAssertNil(CisternFormat.parseKilograms("x", locale: locale))
    }

    func test_familyGoalInvariantOnHouseMark() {
        let mark = DayMark(weightKg: 70, band: .active)
        XCTAssertEqual(DayMark.goal(weightKg: 70, activityBonus: 350), 2_650)
        XCTAssertEqual(mark.goalMillilitres, 2_650)
        XCTAssertEqual(mark.activityBonus, 350)
        XCTAssertEqual(ActivityBand.none.activityBonus, 0)
        XCTAssertEqual(ActivityBand.active.activityBonus, 350)
        XCTAssertEqual(ActivityBand.intense.activityBonus, 700)
        XCTAssertEqual(PourVolume.crestMillilitres, 250)
    }

    func test_designSystemHasSixStepsAndCisternTokens() {
        XCTAssertEqual(CisternInk.Step.allCases.count, 6)
        XCTAssertEqual(CisternInk.unit, 8)
        XCTAssertEqual(CisternInk.tap, 44)
    }
}
