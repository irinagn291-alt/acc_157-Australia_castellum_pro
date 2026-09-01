import Foundation

extension WeirStore {
    static func previewPopulated(now: Date = Date(), calendar: Calendar = .current) -> WeirStore {
        let store = WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
        store.install(WeirSeed.ledger(now: now, calendar: calendar))
        return store
    }

    static func previewVacant(calendar: Calendar = .current) -> WeirStore {
        WeirStore(cistern: WeirMemoryCistern(), calendar: calendar)
    }
}
