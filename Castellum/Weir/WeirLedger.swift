import Foundation

/// Role: Weir. In-memory source of truth. The cistern file is only a projection.
struct WeirLedger: Equatable, Sendable {
    var mark: DayMark?
    var dayKey: DayKey
    var pours: [Pour]
    var crestRuns: [CrestRun]
    var onboardingComplete: Bool

    static let empty = WeirLedger(
        mark: nil,
        dayKey: DayKey(rawValue: 0),
        pours: [],
        crestRuns: [],
        onboardingComplete: false
    )
}

/// Role: Weir. Codable envelope. Domain types do not decode this JSON themselves.
struct WeirDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var weightKg: Double?
    var band: String?
    var dayKey: Int
    var pours: [PourRecord]
    var crestRuns: [CrestRunRecord]
    var onboardingComplete: Bool
}

struct PourRecord: Codable, Equatable, Sendable {
    var id: UUID
    var dayKey: Int
    var millilitres: Int
}

struct CrestRunRecord: Codable, Equatable, Sendable {
    var dayKey: Int
    var bowlMillilitres: Int
    var didHit: Bool
}

enum WeirCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: WeirLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: ledger))
    }

    static func decode(_ data: Data) throws -> WeirLedger {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return ledger(from: try decoder.decode(WeirDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func document(from ledger: WeirLedger) -> WeirDocument {
        WeirDocument(
            schemaVersion: currentSchema,
            weightKg: ledger.mark?.weightKg,
            band: ledger.mark?.band.rawValue,
            dayKey: ledger.dayKey.rawValue,
            pours: ledger.pours.map { pour in
                PourRecord(id: pour.id, dayKey: pour.dayKey.rawValue, millilitres: pour.millilitres)
            },
            crestRuns: ledger.crestRuns.map { run in
                CrestRunRecord(
                    dayKey: run.dayKey.rawValue,
                    bowlMillilitres: run.bowlMillilitres,
                    didHit: run.didHit
                )
            },
            onboardingComplete: ledger.onboardingComplete
        )
    }

    static func ledger(from document: WeirDocument) -> WeirLedger {
        let mark: DayMark?
        if let weightKg = document.weightKg {
            mark = DayMark(weightKg: weightKg, band: ActivityBand(rawValue: document.band ?? "") ?? .none)
        } else {
            mark = nil
        }
        return WeirLedger(
            mark: mark,
            dayKey: DayKey(rawValue: document.dayKey),
            pours: document.pours.map { record in
                Pour(
                    id: record.id,
                    dayKey: DayKey(rawValue: record.dayKey),
                    millilitres: record.millilitres
                )
            },
            crestRuns: document.crestRuns.map { record in
                CrestRun(
                    dayKey: DayKey(rawValue: record.dayKey),
                    bowlMillilitres: record.bowlMillilitres,
                    didHit: record.didHit
                )
            },
            onboardingComplete: document.onboardingComplete
        )
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
