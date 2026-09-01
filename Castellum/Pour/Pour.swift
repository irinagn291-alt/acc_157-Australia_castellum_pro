import Foundation

/// Role: Pour. IntakeEntry as one well measure. Identity is the UUID, never a list index.
struct Pour: Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: DayKey
    var millilitres: Int

    init(id: UUID = UUID(), dayKey: DayKey, millilitres: Int) {
        self.id = id
        self.dayKey = dayKey
        self.millilitres = millilitres
    }
}

/// Role: Pour. Default crest into the well is 250 ml.
enum PourVolume {
    static let crestMillilitres = 250
}

/// Role: Pour. Well fills the sump then crests. Jump would skip an open sump.
enum PourPath: Equatable, Sendable {
    case well
    case jump
}

/// Role: Pour. Store refusals. A jump over an open sump never rewrites the fold.
enum WeirRefusal: Error, Equatable, Sendable {
    case skipsOpenSump
    case invalidVolume
    case noMark
    case invalidWeight
}
