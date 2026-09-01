import XCTest
@testable import Castellum

final class WeirHopTests: XCTestCase {
    func test_contactURLIsTheHouseContact() {
        XCTAssertEqual(WeirHop.contactURL.absoluteString, "https://castellum-weir.pro/contact-us")
    }
}
