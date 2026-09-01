import Foundation

/// Role: Weir. Versioned UserDefaults key plus the atomic file projection. Views never touch this.
enum WeirKey {
    static let document = "ctm.document.v1"
    static let backup = "ctm.document.v1.backup"
    static let demo = "ctm.demo.v1"
}

enum WeirWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

protocol WeirPersisting: Sendable {
    func load() async -> (ledger: WeirLedger, warning: WeirWarning?)
    func note(_ ledger: WeirLedger) async
    func save(_ ledger: WeirLedger) async throws
    func flush() async throws
    func resetAllData() async throws
    func hasDemoSeed() async -> Bool
    func markDemoSeed() async
}

/// Role: Weir. One seam. Memory on WeirStore is source of truth; disk is a projection.
actor WeirCistern: WeirPersisting {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: WeirLedger?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func supportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Castellum", isDirectory: true)
    }

    func load() async -> (ledger: WeirLedger, warning: WeirWarning?) {
        prepareDirectory()
        if let ledger = decode(defaults().data(forKey: WeirKey.document)) {
            latest = ledger
            return (ledger, nil)
        }
        if let ledger = decodeFile(fileURL()) {
            latest = ledger
            return (ledger, nil)
        }
        if let ledger = decode(defaults().data(forKey: WeirKey.backup)) {
            latest = ledger
            return (ledger, .recoveredFromBackup)
        }
        if let ledger = decodeFile(backupURL()) {
            latest = ledger
            return (ledger, .recoveredFromBackup)
        }
        if hasAnyPayload() {
            latest = .empty
            return (.empty, .startedEmpty)
        }
        latest = .empty
        return (.empty, nil)
    }

    func note(_ ledger: WeirLedger) async {
        latest = ledger
        scheduleFlush()
    }

    func save(_ ledger: WeirLedger) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = ledger
        try persist(ledger)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: WeirKey.document)
        defaults.removeObject(forKey: WeirKey.backup)
        defaults.synchronize()
        if fileManager.fileExists(atPath: fileURL().path) {
            try fileManager.removeItem(at: fileURL())
        }
        if fileManager.fileExists(atPath: backupURL().path) {
            try fileManager.removeItem(at: backupURL())
        }
    }

    func hasDemoSeed() async -> Bool {
        defaults().object(forKey: WeirKey.demo) != nil
    }

    func markDemoSeed() async {
        defaults().set(true, forKey: WeirKey.demo)
        defaults().synchronize()
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ ledger: WeirLedger) throws {
        prepareDirectory()
        let data = try WeirCodec.encode(ledger)
        let defaults = defaults()
        if let previous = defaults.data(forKey: WeirKey.document) {
            defaults.set(previous, forKey: WeirKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL().path) {
            try? fileManager.removeItem(at: backupURL())
            try? fileManager.copyItem(at: fileURL(), to: backupURL())
        }
        try data.write(to: fileURL(), options: .atomic)
        defaults.set(data, forKey: WeirKey.document)
        defaults.synchronize()
        lastWriteError = nil
    }

    private func decode(_ data: Data?) -> WeirLedger? {
        guard let data else { return nil }
        return try? WeirCodec.decode(data)
    }

    private func decodeFile(_ url: URL) -> WeirLedger? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? WeirCodec.decode(data)
    }

    private func hasAnyPayload() -> Bool {
        defaults().data(forKey: WeirKey.document) != nil
            || defaults().data(forKey: WeirKey.backup) != nil
            || fileManager.fileExists(atPath: fileURL().path)
            || fileManager.fileExists(atPath: backupURL().path)
    }

    private func fileURL() -> URL {
        directory.appendingPathComponent("weir.json")
    }

    private func backupURL() -> URL {
        directory.appendingPathComponent("weir.json.backup")
    }

    private func defaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

/// Role: Weir. In-process cistern for tests. Same seam as the disk projection.
actor WeirMemoryCistern: WeirPersisting {
    private var ledger: WeirLedger = .empty
    private var demoSeeded = false

    func load() async -> (ledger: WeirLedger, warning: WeirWarning?) {
        (ledger, nil)
    }

    func note(_ ledger: WeirLedger) async {
        self.ledger = ledger
    }

    func save(_ ledger: WeirLedger) async throws {
        self.ledger = ledger
    }

    func flush() async throws {}

    func resetAllData() async throws {
        ledger = .empty
    }

    func hasDemoSeed() async -> Bool {
        demoSeeded
    }

    func markDemoSeed() async {
        demoSeeded = true
    }
}
