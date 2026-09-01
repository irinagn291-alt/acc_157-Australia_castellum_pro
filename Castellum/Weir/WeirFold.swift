import Foundation

/// Role: Weir. OpenSump | Cresting | Full. Views never assign this; the fold replaces the case.
enum WeirCase: Equatable, Sendable {
    case openSump
    case cresting
    case full
}

/// Role: Weir. Communicating vessels after folding the day's pours.
struct WeirVessels: Equatable, Sendable {
    var sump: SumpChamber
    var bowl: BodyBowl
    var weir: WeirCase

    var didHit: Bool {
        weir == .full
    }

    static func idle(sumpTarget: Int) -> WeirVessels {
        let remaining = max(0, sumpTarget)
        let weir: WeirCase = remaining > 0 ? .openSump : .cresting
        return WeirVessels(
            sump: SumpChamber(depthMillilitres: remaining, remainingMillilitres: remaining),
            bowl: BodyBowl(millilitres: 0),
            weir: weir
        )
    }
}

/// Role: Weir. Pure fold of Pour → remaining sump + bowl. The store reruns this after every legal pour.
enum WeirFold {
    static func foldPours(_ pours: [Pour], mark: DayMark) -> WeirVessels {
        var remaining = mark.sumpTarget
        var bowl = 0
        for pour in pours {
            guard pour.millilitres > 0 else { continue }
            if remaining > 0 {
                let intoSump = min(pour.millilitres, remaining)
                remaining -= intoSump
                bowl += pour.millilitres - intoSump
            } else {
                bowl += pour.millilitres
            }
        }
        let weir: WeirCase
        if remaining > 0 {
            weir = .openSump
        } else if bowl >= mark.bowlTarget {
            weir = .full
        } else {
            weir = .cresting
        }
        return WeirVessels(
            sump: SumpChamber(depthMillilitres: mark.sumpTarget, remainingMillilitres: remaining),
            bowl: BodyBowl(millilitres: bowl),
            weir: weir
        )
    }

    static func dayIsComplete(_ vessels: WeirVessels, mark: DayMark) -> Bool {
        vessels.sump.remainingMillilitres == 0
            && vessels.bowl.millilitres >= mark.goalMillilitres - mark.sumpTarget
    }

    static func append(
        millilitres: Int,
        path: PourPath,
        onto pours: [Pour],
        dayKey: DayKey,
        mark: DayMark
    ) throws -> [Pour] {
        guard millilitres > 0 else { throw WeirRefusal.invalidVolume }
        let current = foldPours(pours, mark: mark)
        if path == .jump, current.weir == .openSump {
            throw WeirRefusal.skipsOpenSump
        }
        var next = pours
        next.append(Pour(dayKey: dayKey, millilitres: millilitres))
        return next
    }
}
