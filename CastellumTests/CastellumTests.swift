import XCTest
@testable import Castellum

final class CastellumTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: CastellumApp.self), "CastellumApp")
    }
}
