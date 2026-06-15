import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english
    case chinese

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case light
    case dark

    var id: String { rawValue }
}

enum SourceCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case usbC
    case displayPort
    case hdmi
    case dviVga
    case legacy
    case other

    var id: String { rawValue }
}

enum GroupPresetKind: String, Codable, Hashable {
    case workBoth
    case personalBoth
    case workLeftPersonalRight
    case personalLeftWorkRight
}

enum SetupCheckStatus {
    case success
    case warning
    case failure
    case info
}

struct SetupCheckItem: Identifiable {
    var id = UUID()
    var status: SetupCheckStatus
    var title: String
    var detail: String
}

struct SetupCheckResult {
    var items: [SetupCheckItem]
    var summary: String
    var guidance: String?
}

struct DisplayDevice: Identifiable, Codable, Hashable {
    var id: String { stableID }
    var stableID: String
    var tagID: String?
    var uuid: String?
    var displayID: String?
    var name: String
    var originalName: String?
    var productName: String?
    var vendor: String?
    var model: String?
    var serial: String?
    var yearOfManufacture: String?
    var weekOfManufacture: String?
    var registryLocation: String?

    var shortIdentity: String {
        if let serial, !serial.isEmpty { return "Serial \(serial)" }
        if let displayID, !displayID.isEmpty { return "Display ID \(displayID)" }
        return stableID
    }

    var manufactureSummary: String {
        guard let yearOfManufacture, !yearOfManufacture.isEmpty else { return "Unknown year" }
        if let weekOfManufacture, !weekOfManufacture.isEmpty {
            return "Week \(weekOfManufacture), \(yearOfManufacture)"
        }
        return yearOfManufacture
    }
}

struct InputSource: Identifiable, Codable, Hashable {
    var id: String { value }
    var value: String
    var name: String
    var controller: String?

    var displayName: String {
        if let controller, !controller.isEmpty {
            return "\(name) (\(value), \(controller))"
        }
        return "\(name) (\(value))"
    }

    var category: SourceCategory {
        let lower = name.lowercased()
        if lower.contains("usb-c") || lower.contains("usb c") || lower.contains("thunderbolt") || lower.contains("tb") {
            return .usbC
        }
        if lower.contains("displayport") || lower.hasPrefix("dp ") || lower.contains(" dp ") {
            return .displayPort
        }
        if lower.contains("hdmi") {
            return .hdmi
        }
        if lower.contains("dvi") || lower.contains("vga") {
            return .dviVga
        }
        if lower.contains("legacy") || lower.contains("composite") || lower.contains("s-video") || lower.contains("tuner") || lower.contains("component") {
            return .legacy
        }
        return .other
    }
}

struct SwitchRule: Identifiable, Codable, Hashable {
    var id = UUID()
    var displayID: String
    var displayName: String
    var sourceValue: String
    var sourceName: String
    var enabled: Bool = true
    var sourceDeviceName: String = ""
    var sourceSlot: String = ""
    var cableType: String = ""
    var targetSlot: String = ""

    init(
        id: UUID = UUID(),
        displayID: String,
        displayName: String,
        sourceValue: String,
        sourceName: String,
        enabled: Bool = true,
        sourceDeviceName: String = "",
        sourceSlot: String = "",
        cableType: String = "",
        targetSlot: String = ""
    ) {
        self.id = id
        self.displayID = displayID
        self.displayName = displayName
        self.sourceValue = sourceValue
        self.sourceName = sourceName
        self.enabled = enabled
        self.sourceDeviceName = sourceDeviceName
        self.sourceSlot = sourceSlot
        self.cableType = cableType
        self.targetSlot = targetSlot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        displayID = try container.decode(String.self, forKey: .displayID)
        displayName = try container.decode(String.self, forKey: .displayName)
        sourceValue = try container.decode(String.self, forKey: .sourceValue)
        sourceName = try container.decode(String.self, forKey: .sourceName)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        sourceDeviceName = try container.decodeIfPresent(String.self, forKey: .sourceDeviceName) ?? ""
        sourceSlot = try container.decodeIfPresent(String.self, forKey: .sourceSlot) ?? ""
        cableType = try container.decodeIfPresent(String.self, forKey: .cableType) ?? ""
        targetSlot = try container.decodeIfPresent(String.self, forKey: .targetSlot) ?? ""
    }
}

struct SwitchGroup: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var subtitle: String
    var symbolName: String
    var tintName: String
    var rules: [SwitchRule]
    var updatedAt = Date()
    var presetKind: GroupPresetKind?
    var nameEdited: Bool = false
    var subtitleEdited: Bool = false

    var isPreset: Bool {
        presetKind != nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        symbolName: String,
        tintName: String,
        rules: [SwitchRule],
        updatedAt: Date = Date(),
        presetKind: GroupPresetKind? = nil,
        nameEdited: Bool = false,
        subtitleEdited: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.tintName = tintName
        self.rules = rules
        self.updatedAt = updatedAt
        self.presetKind = presetKind
        self.nameEdited = nameEdited
        self.subtitleEdited = subtitleEdited
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        tintName = try container.decode(String.self, forKey: .tintName)
        rules = try container.decode([SwitchRule].self, forKey: .rules)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        presetKind = try container.decodeIfPresent(GroupPresetKind.self, forKey: .presetKind)
        nameEdited = try container.decodeIfPresent(Bool.self, forKey: .nameEdited) ?? false
        subtitleEdited = try container.decodeIfPresent(Bool.self, forKey: .subtitleEdited) ?? false
    }
}

struct PersistedConfiguration: Codable {
    var groups: [SwitchGroup]
    var language: AppLanguage
    var theme: AppTheme
    var visibleSourceCategories: Set<SourceCategory>

    init(
        groups: [SwitchGroup],
        language: AppLanguage = .english,
        theme: AppTheme = .light,
        visibleSourceCategories: Set<SourceCategory> = SourceCategory.defaultVisible
    ) {
        self.groups = groups
        self.language = language
        self.theme = theme
        self.visibleSourceCategories = visibleSourceCategories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groups = try container.decode([SwitchGroup].self, forKey: .groups)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .light
        visibleSourceCategories = try container.decodeIfPresent(Set<SourceCategory>.self, forKey: .visibleSourceCategories) ?? SourceCategory.defaultVisible
    }
}

extension SourceCategory {
    static let defaultVisible: Set<SourceCategory> = [.usbC, .displayPort, .hdmi]
}
