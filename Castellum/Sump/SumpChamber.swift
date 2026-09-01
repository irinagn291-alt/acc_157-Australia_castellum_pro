/// Role: Sump. Lower sweat chamber. Depth is the activity band; remaining is a fold, never stored.
struct SumpChamber: Equatable, Sendable {
    var depthMillilitres: Int
    var remainingMillilitres: Int

    var filledMillilitres: Int {
        max(0, depthMillilitres - remainingMillilitres)
    }

    var isOpen: Bool {
        remainingMillilitres > 0
    }
}
