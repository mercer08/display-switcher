import Foundation

enum BetterDisplayError: LocalizedError {
    case executableNotFound
    case builtInDisplayUnsupported(String)
    case commandFailed(String)
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "betterdisplaycli was not found. Install it with: brew install waydabber/betterdisplay/betterdisplaycli"
        case .builtInDisplayUnsupported(let name):
            return "Built-in display is excluded from display switching: \(name)"
        case .commandFailed(let message):
            return message
        case .invalidOutput(let message):
            return message
        }
    }
}

struct CurrentInputSourceVCPValue {
    var rawOutput: String
    var rawValue: Int
    var normalizedValue: Int
    var lowByteValue: Int?
    var highByteValue: Int?
}

struct BetterDisplayCLI {
    var executablePath: String {
        if FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/betterdisplaycli") {
            return "/opt/homebrew/bin/betterdisplaycli"
        }
        if FileManager.default.isExecutableFile(atPath: "/usr/local/bin/betterdisplaycli") {
            return "/usr/local/bin/betterdisplaycli"
        }
        if let path = which("betterdisplaycli") {
            return path
        }
        return "betterdisplaycli"
    }

    func isAvailable() -> Bool {
        FileManager.default.isExecutableFile(atPath: executablePath) || which("betterdisplaycli") != nil
    }

    func listDisplays() async throws -> [DisplayDevice] {
        let raw = try await run(["get", "--identifiers"])
        return try parseDisplays(raw)
    }

    func listInputSources(for display: DisplayDevice?) async throws -> [InputSource] {
        var arguments = ["get"]
        if let display {
            try validateSwitchable(display)
            arguments.append(identifierArgument(for: display))
        }
        arguments.append("--inputSourceList")
        let raw = try await run(arguments)
        return parseInputSources(raw)
    }

    func changeInputSource(display: DisplayDevice, sourceValue: String) async throws -> String {
        try validateSwitchable(display)
        return try await run([
            "perform",
            identifierArgument(for: display),
            "--changeInputSource=\(sourceValue)"
        ])
    }

    func setDisplayConnection(display: DisplayDevice, connected: Bool) async throws -> String {
        try validateSwitchable(display)
        return try await run([
            "set",
            identifierArgument(for: display),
            "--connected=\(connected ? "on" : "off")"
        ])
    }

    func displayConnectionStatus(display: DisplayDevice) async throws -> Bool {
        try validateSwitchable(display)
        let raw = try await run([
            "get",
            identifierArgument(for: display),
            "--connected"
        ])
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveContains("on")
    }

    func currentInputSourceVCPValue(display: DisplayDevice) async throws -> CurrentInputSourceVCPValue {
        try validateSwitchable(display)
        let raw = try await run([
            "get",
            identifierArgument(for: display),
            "--feature=ddc",
            "--vcp=0x60",
            "--value"
        ])

        guard let value = parseInteger(raw) else {
            throw BetterDisplayError.invalidOutput("Unable to read current input source from BetterDisplay CLI output: \(raw)")
        }
        return CurrentInputSourceVCPValue(
            rawOutput: raw,
            rawValue: value,
            normalizedValue: normalizeVCPValue(value),
            lowByteValue: lowByteValue(value),
            highByteValue: highByteValue(value)
        )
    }

    private func identifierArgument(for display: DisplayDevice) -> String {
        if let tagID = display.tagID, !tagID.isEmpty {
            return "--tagID=\(tagID)"
        }
        if let uuid = display.uuid, !uuid.isEmpty {
            return "--UUID=\(uuid)"
        }
        return "--name=\(display.name)"
    }

    private func validateSwitchable(_ display: DisplayDevice) throws {
        guard !display.isBuiltIn else {
            throw BetterDisplayError.builtInDisplayUnsupported(display.name)
        }
    }

    private func run(_ arguments: [String]) async throws -> String {
        let path = executablePath
        guard path != "betterdisplaycli" || which("betterdisplaycli") != nil else {
            throw BetterDisplayError.executableNotFound
        }

        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                throw BetterDisplayError.commandFailed(error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? output : error)
            }

            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }

    private func parseDisplays(_ raw: String) throws -> [DisplayDevice] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let json = "[\(trimmed)]"
        guard let data = json.data(using: .utf8) else {
            throw BetterDisplayError.invalidOutput("Unable to read BetterDisplay identifiers output.")
        }

        let decoder = JSONDecoder()
        let objects = try decoder.decode([[String: String]].self, from: data)
        return objects.compactMap { object in
            guard object["deviceType"] == "Display" else { return nil }
            guard !isBuiltInDisplay(object) else { return nil }
            let name = object["name"] ?? object["productName"] ?? object["originalName"] ?? "Display"
            let stableID = object["UUID"] ?? object["tagID"] ?? object["displayID"] ?? name
            return DisplayDevice(
                stableID: stableID,
                tagID: object["tagID"],
                uuid: object["UUID"],
                displayID: object["displayID"],
                name: name,
                originalName: object["originalName"],
                productName: object["productName"],
                vendor: object["vendor"],
                model: object["model"],
                serial: object["serial"],
                yearOfManufacture: object["yearOfManufacture"],
                weekOfManufacture: object["weekOfManufacture"],
                registryLocation: object["registryLocation"]
            )
        }
    }

    private func isBuiltInDisplay(_ object: [String: String]) -> Bool {
        let hasBuiltInBooleanFlag = object.contains { key, value in
            let normalizedKey = key.lowercased().filter(\.isLetter)
            let normalizedValue = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return ["isbuiltin", "builtin", "isinternal", "internal"].contains(normalizedKey)
                && ["true", "yes", "on", "1"].contains(normalizedValue)
        }
        guard !hasBuiltInBooleanFlag else { return true }

        let hasBuiltInType = object.contains { key, value in
            let normalizedKey = key.lowercased().filter(\.isLetter)
            let normalizedValue = value.lowercased().filter(\.isLetter)
            return (normalizedKey.contains("type") || normalizedKey.contains("class"))
                && ["builtin", "builtindisplay", "internal", "internaldisplay"].contains(normalizedValue)
        }
        guard !hasBuiltInType else { return true }

        // BetterDisplay versions have used different keys for display type. Search all
        // identifier values so explicit values such as "Built-in" are never missed.
        let searchableText = object.values
            .joined(separator: " ")
            .lowercased()
            .filter(\.isLetter)

        return DisplayDevice.builtInDisplayMarkers.contains { searchableText.contains($0) }
    }

    private func parseInputSources(_ raw: String) -> [InputSource] {
        let normalized = raw.replacingOccurrences(of: "],", with: "]\n")
        let sources = normalized
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> InputSource? in
                let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }

                let parts = text.split(separator: "-", maxSplits: 1).map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard parts.count == 2, !parts[0].isEmpty else { return nil }

                var name = parts[1]
                var controller: String?
                if let open = name.lastIndex(of: "["), let close = name.lastIndex(of: "]"), open < close {
                    controller = String(name[name.index(after: open)..<close])
                    name = String(name[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
                }

                return InputSource(value: parts[0], name: name, controller: controller)
            }

        return Array(Dictionary(grouping: sources, by: \.value).compactMap { $0.value.first })
            .sorted { (Int($0.value) ?? 9999) < (Int($1.value) ?? 9999) }
    }

    private func parseInteger(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            return Int(trimmed.dropFirst(2), radix: 16)
        }
        if let value = Int(trimmed) {
            return value
        }
        let match = trimmed.firstMatch(of: /0x[0-9a-fA-F]+|\d+/)
        guard let match else { return nil }
        let token = String(match.output)
        if token.lowercased().hasPrefix("0x") {
            return Int(token.dropFirst(2), radix: 16)
        }
        return Int(token)
    }

    private func normalizeVCPValue(_ value: Int) -> Int {
        guard value > 0xff else { return value }
        let lowByte = value & 0xff
        if lowByte != 0 {
            return lowByte
        }
        let highByte = (value >> 8) & 0xff
        return highByte != 0 ? highByte : value
    }

    private func lowByteValue(_ value: Int) -> Int? {
        guard value > 0xff else { return nil }
        let lowByte = value & 0xff
        return lowByte == 0 ? nil : lowByte
    }

    private func highByteValue(_ value: Int) -> Int? {
        guard value > 0xff else { return nil }
        let highByte = (value >> 8) & 0xff
        return highByte == 0 ? nil : highByte
    }

    private func which(_ executable: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [executable]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return output?.isEmpty == false ? output : nil
    }
}
