import SwiftUI
@testable import Castellum

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("dial", AnyView(WellDialView())),
            ("history", AnyView(CrestHistoryView())),
            ("settings", AnyView(CisternSettingsView()))
        ]
    }
}
