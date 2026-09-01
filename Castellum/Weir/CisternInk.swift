import SwiftUI
import UIKit

/// Role: Presentation. Cistern-house tokens. Hex lives in the catalog; SF Pro via .system only.
enum CisternInk {
    static let background = Color("ctm_background")
    static let surface = Color("ctm_surface")
    static let ink = Color("ctm_ink")
    static let accent = Color("ctm_accent")
    static let muted = Color("ctm_muted")

    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let motion = Animation.easeInOut(duration: 0.28)

    static var backgroundUI: UIColor { named("ctm_background") }
    static var surfaceUI: UIColor { named("ctm_surface") }
    static var inkUI: UIColor { named("ctm_ink") }
    static var accentUI: UIColor { named("ctm_accent") }
    static var mutedUI: UIColor { named("ctm_muted") }

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    enum Step: CaseIterable {
        case house
        case mark
        case figure
        case body
        case caption
        case stamp

        var style: Font.TextStyle {
            switch self {
            case .house: .largeTitle
            case .mark: .title
            case .figure: .title2
            case .body: .body
            case .caption: .subheadline
            case .stamp: .caption
            }
        }

        var weight: Font.Weight {
            switch self {
            case .house, .mark, .figure: .semibold
            case .body, .caption, .stamp: .regular
            }
        }
    }

    static func font(_ step: Step) -> Font {
        .system(step.style, design: .default, weight: step.weight)
    }

    private static func named(_ name: String) -> UIColor {
        UIColor(named: name) ?? .black
    }
}

extension View {
    func cisternText(_ step: CisternInk.Step) -> some View {
        font(CisternInk.font(step))
            .foregroundStyle(CisternInk.ink)
    }

    func cisternHit() -> some View {
        frame(minWidth: CisternInk.tap, minHeight: CisternInk.tap)
            .contentShape(Rectangle())
    }
}
