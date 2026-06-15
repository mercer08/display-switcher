import Foundation

struct AppLogger {
    private let logURL: URL

    init() {
        let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("DisplaySwitcher", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        logURL = logsDirectory.appendingPathComponent("app.log")
    }

    func info(_ message: String) {
        append(level: "INFO", message: message)
    }

    func warning(_ message: String) {
        append(level: "WARN", message: message)
    }

    private func append(level: String, message: String) {
        let line = "\(Self.timestamp()) [\(level)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logURL, options: .atomic)
        }
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
