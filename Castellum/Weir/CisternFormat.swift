import Foundation

/// Role: Presentation. Locale figures only. Stored millilitres stay exact until here.
enum CisternFormat {
    static func millilitres(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: value)) ?? "—"
        return number + " ml"
    }

    static func kilograms(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let number = formatter.string(from: NSNumber(value: value)) ?? "—"
        return number + " kg"
    }

    static func day(_ key: DayKey, calendar: Calendar = .current, locale: Locale = .current) -> String {
        guard let date = key.start(calendar: calendar) else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func parseKilograms(_ text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: trimmed)?.doubleValue else { return nil }
        guard number.isFinite, number > 0 else { return nil }
        return number
    }
}

/// Role: Presentation. Weir voice for chrome. Views never invent a fourth ADT case.
enum WeirVoice {
    static func weir(_ weir: WeirCase) -> String {
        switch weir {
        case .openSump: "Sump open"
        case .cresting: "Cresting"
        case .full: "Weir full"
        }
    }

    static func hatch(_ weir: WeirCase) -> String {
        switch weir {
        case .openSump: "Hatch ajar"
        case .cresting, .full: "Hatch shut"
        }
    }

    static func band(_ band: ActivityBand) -> String {
        switch band {
        case .none: "Still"
        case .active: "Active"
        case .intense: "Intense"
        }
    }

    static func refusal(_ error: WeirRefusal) -> String {
        switch error {
        case .skipsOpenSump: "The sump is still open. A jump cannot crest."
        case .invalidVolume: "A pour needs a positive measure."
        case .noMark: "Plant a day mark before the first pour."
        case .invalidWeight: "Weight must be a positive number."
        }
    }

    static func warning(_ warning: WeirWarning) -> String {
        switch warning {
        case .recoveredFromBackup: "The cistern reopened from a backup ledger."
        case .startedEmpty: "The ledger was corrupt. The well started empty."
        }
    }
}
