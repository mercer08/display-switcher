import AppKit
import Foundation
import SwiftUI

private struct InputSourceSkipCheck {
    var shouldSkip: Bool
    var reason: String
    var currentRawOutput: String?
    var currentRawValue: Int?
    var currentNormalizedValue: Int?
    var targetValue: Int?
    var targetName: String
    var error: String?

    func logMessage(display: DisplayDevice, rule: SwitchRule) -> String {
        [
            "Input source precheck",
            "display=\(display.name)",
            "targetSourceValue=\(rule.sourceValue)",
            "targetSourceName=\(targetName)",
            "targetVCP=\(targetValue.map(String.init) ?? "nil")",
            "currentRawOutput=\(currentRawOutput ?? "nil")",
            "currentRawValue=\(currentRawValue.map(String.init) ?? "nil")",
            "currentVCP=\(currentNormalizedValue.map(String.init) ?? "nil")",
            "skip=\(shouldSkip)",
            "reason=\(reason)",
            "error=\(error ?? "nil")"
        ].joined(separator: ", ")
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var displays: [DisplayDevice] = []
    @Published var inputSourcesByDisplayID: [String: [InputSource]] = [:]
    @Published var groups: [SwitchGroup] = []
    @Published var selectedGroupID: SwitchGroup.ID?
    @Published var selectedDisplayID: DisplayDevice.ID?
    @Published var isRefreshing = false
    @Published var isApplying = false
    @Published var statusMessage = Localization.text(.ready, language: .english)
    @Published var lastError: String?
    @Published var language: AppLanguage = .english
    @Published var theme: AppTheme = .light
    @Published var visibleSourceCategories: Set<SourceCategory> = SourceCategory.defaultVisible
    @Published var localMacRole: LocalMacRole = .work
    @Published var managedDisconnectedDisplays: [DisplayDevice] = []
    @Published var pendingApplyGroup: SwitchGroup?
    @Published var isShowingUsageGuide = false
    @Published var isRunningSetupCheck = false
    @Published var setupCheckResult: SetupCheckResult?
    @Published var hotkeyRegistrationIssues: [HotkeyRegistrationIssue] = []

    private let cli = BetterDisplayCLI()
    private let hotkeyManager = GlobalHotkeyManager()
    private let logger = AppLogger()
    private let configurationURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DisplaySwitcher", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        configurationURL = support.appendingPathComponent("configuration.json")
        localMacRole = Self.detectedLocalMacRole()
        loadConfiguration()
    }

    var selectedGroup: SwitchGroup? {
        get {
            guard let selectedGroupID else { return groups.first }
            return groups.first { $0.id == selectedGroupID } ?? groups.first
        }
        set {
            guard let newValue, let index = groups.firstIndex(where: { $0.id == newValue.id }) else { return }
            groups[index] = newValue
            selectedGroupID = newValue.id
            saveConfiguration()
        }
    }

    var selectedDisplay: DisplayDevice? {
        guard let selectedDisplayID else { return displays.first }
        return displays.first { $0.id == selectedDisplayID } ?? displays.first
    }

    func bootstrap() async {
        configureGlobalHotkeys()
        await refreshDisplays()
    }

    func refreshDisplays() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastError = nil
        statusMessage = t(.refreshingDisplays)
        defer { isRefreshing = false }

        do {
            guard cli.isAvailable() else { throw BetterDisplayError.executableNotFound }
            let fetchedDisplays = try await cli.listDisplays()
            displays = fetchedDisplays
            selectedDisplayID = selectedDisplayID ?? fetchedDisplays.first?.id
            try await refreshInputSources(for: fetchedDisplays)

            if groups.isEmpty {
                groups = makeDefaultGroups(displays: fetchedDisplays)
                selectedGroupID = groups.first?.id
                saveConfiguration()
            } else {
                syncRulesWithCurrentDisplays()
            }

            statusMessage = fetchedDisplays.isEmpty ? t(.noBetterDisplayDisplays) : "\(t(.foundDisplays)) \(localizedDisplayCount(fetchedDisplays.count))"
        } catch {
            lastError = error.localizedDescription
            statusMessage = t(.refreshFailed)
        }
    }

    func refreshInputSources(for displays: [DisplayDevice]) async throws {
        var mapping: [String: [InputSource]] = [:]
        for display in displays {
            let sources = try await cli.listInputSources(for: display)
            mapping[display.id] = sources
        }
        inputSourcesByDisplayID = mapping
    }

    func addGroup() {
        let group = SwitchGroup(
            name: t(.newGroup),
            subtitle: t(.customStrategy),
            symbolName: "rectangle.2.swap",
            tintName: "blue",
            rules: displays.map { display in
                let source = preferredSource(for: display, matching: "USB-C") ?? inputSources(for: display).first
                return SwitchRule(
                    displayID: display.id,
                    displayName: display.name,
                    sourceValue: source?.value ?? "",
                    sourceName: source?.name ?? t(.manual),
                    enabled: true
                )
            }
        )
        groups.append(group)
        selectedGroupID = group.id
        saveConfiguration()
    }

    func resetPresetGroups() {
        let customGroups = groups.filter { $0.presetKind == nil }
        let presetGroups = makeDefaultGroups(displays: displays)
        groups = presetGroups + customGroups
        selectedGroupID = groups.first?.id
        saveConfiguration()
    }

    func deleteSelectedGroup() {
        guard let selectedGroupID,
              groups.count > 1,
              groups.first(where: { $0.id == selectedGroupID })?.isPreset == false else { return }
        groups.removeAll { $0.id == selectedGroupID }
        self.selectedGroupID = groups.first?.id
        saveConfiguration()
    }

    func updateGroup(_ group: SwitchGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }),
              groups[index].isPreset == false else { return }
        var updated = group
        updated.updatedAt = Date()
        groups[index] = updated
        saveConfiguration()
    }

    func groupDisplayName(_ group: SwitchGroup) -> String {
        if let presetKind = group.presetKind {
            return localizedPresetName(presetKind) ?? group.name
        }
        return group.name
    }

    func groupDisplaySubtitle(_ group: SwitchGroup) -> String {
        if let presetKind = group.presetKind {
            return localizedPresetSubtitle(presetKind) ?? group.subtitle
        }
        return group.subtitle
    }

    func updateGroupName(groupID: SwitchGroup.ID, name: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }),
              groups[index].isPreset == false else { return }
        groups[index].name = name
        groups[index].nameEdited = true
        groups[index].updatedAt = Date()
        saveConfiguration()
    }

    func updateGroupSubtitle(groupID: SwitchGroup.ID, subtitle: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }),
              groups[index].isPreset == false else { return }
        groups[index].subtitle = subtitle
        groups[index].subtitleEdited = true
        groups[index].updatedAt = Date()
        saveConfiguration()
    }

    func updateRule(groupID: SwitchGroup.ID, rule: SwitchRule) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }),
              groups[groupIndex].isPreset == false,
              let ruleIndex = groups[groupIndex].rules.firstIndex(where: { $0.id == rule.id }) else { return }
        groups[groupIndex].rules[ruleIndex] = enrichRouteMetadata(rule, in: groups[groupIndex])
        groups[groupIndex].updatedAt = Date()
        saveConfiguration()
    }

    func requestApplySelectedGroup() {
        guard let group = selectedGroup else { return }
        pendingApplyGroup = group
    }

    func requestApplyGroup(at index: Int) {
        guard groups.indices.contains(index) else { return }
        selectedGroupID = groups[index].id
        pendingApplyGroup = groups[index]
    }

    func cancelPendingApply() {
        pendingApplyGroup = nil
    }

    func showUsageGuide() {
        isShowingUsageGuide = true
    }

    func openSettingsWindow() {
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    func confirmPendingApply() async {
        guard let group = pendingApplyGroup else { return }
        pendingApplyGroup = nil
        await applyGroup(group)
    }

    func applySelectedGroup() async {
        guard let group = selectedGroup else { return }
        await applyGroup(group)
    }

    func applyGroup(_ group: SwitchGroup) async {
        guard !isApplying else { return }
        isApplying = true
        lastError = nil
        let displayName = groupDisplayName(group)
        statusMessage = "\(t(.applyingGroup)) \(displayName)..."
        logger.info("Apply group started: \(displayName)")
        defer { isApplying = false }

        var reconnected = 0
        var disconnected = 0
        var applied = 0
        var skipped = 0
        var failures: [String] = []

        let reconnectActions = managedDisconnectedDisplays.map {
            DisplayConnectionAction(display: $0, operation: .reconnect, reason: t(.managedReconnectReason))
        }

        if !reconnectActions.isEmpty {
            statusMessage = "\(t(.reconnectingDisplays)) \(reconnectActions.count)..."
            let resetResult = await applyConnectionActions(reconnectActions)
            reconnected = resetResult.succeeded
            failures.append(contentsOf: resetResult.failures)
            if reconnected > 0 {
                await reloadDisplaysAfterConnectionChange()
            }
        }

        for rule in group.rules where rule.enabled && !rule.sourceValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let display = displays.first(where: { $0.id == rule.displayID }) else { continue }
            do {
                let check = await inputSourceSkipCheck(display: display, rule: rule)
                logger.info(check.logMessage(display: display, rule: rule))
                if check.shouldSkip {
                    skipped += 1
                    continue
                }
                _ = try await cli.changeInputSource(display: display, sourceValue: rule.sourceValue)
                logger.info("Set input source: display=\(display.name), targetSourceValue=\(rule.sourceValue), targetSourceName=\(rule.sourceName)")
                applied += 1
            } catch {
                logger.warning("Set input source failed: display=\(display.name), targetSourceValue=\(rule.sourceValue), error=\(error.localizedDescription)")
                failures.append("\(display.name): \(error.localizedDescription)")
            }
        }

        let shouldDisconnect = failures.isEmpty
        if shouldDisconnect {
            let disconnectActions = disconnectActions(for: group)
            if !disconnectActions.isEmpty {
                statusMessage = "\(t(.disconnectingDisplays)) \(disconnectActions.count)..."
                let disconnectResult = await applyConnectionActions(disconnectActions)
                disconnected = disconnectResult.succeeded
                failures.append(contentsOf: disconnectResult.failures)
                if disconnected > 0 {
                    await reloadDisplaysAfterConnectionChange()
                }
            }
        } else {
            logger.warning("Skipping display disconnect because input switching or reconnect reported failures.")
        }

        if failures.isEmpty {
            statusMessage = "\(t(.appliedGroup)) \(displayName): \(t(.appliedDisplays)) \(applied), \(t(.skippedDisplays)) \(skipped), \(t(.reconnectedDisplays)) \(reconnected), \(t(.disconnectedDisplays)) \(disconnected)"
        } else {
            lastError = failures.joined(separator: "\n")
            statusMessage = "\(t(.appliedWithIssues)): \(failures.count)"
        }
    }

    func applySingle(display: DisplayDevice, source: InputSource) async {
        guard !isApplying else { return }
        isApplying = true
        lastError = nil
        statusMessage = "\(t(.switchingDisplay)) \(display.name) -> \(source.name)..."
        defer { isApplying = false }
        do {
            _ = try await cli.changeInputSource(display: display, sourceValue: source.value)
            statusMessage = "\(t(.switchedDisplay)) \(display.name) -> \(source.name)"
        } catch {
            lastError = error.localizedDescription
            statusMessage = t(.switchFailed)
        }
    }

    func inputSources(for display: DisplayDevice) -> [InputSource] {
        inputSourcesByDisplayID[display.id] ?? []
    }

    func visibleInputSources(for display: DisplayDevice) -> [InputSource] {
        inputSources(for: display).filter { visibleSourceCategories.contains($0.category) }
    }

    func sourceName(displayID: String, value: String, fallback: String) -> String {
        inputSourcesByDisplayID[displayID]?.first(where: { $0.value == value })?.name ?? fallback
    }

    private func localizedDisplayCount(_ count: Int) -> String {
        switch language {
        case .english:
            return "\(count) \(count == 1 ? "display" : "displays")"
        case .chinese:
            return "\(count) 台显示器"
        }
    }

    private func inputSourceSkipCheck(display: DisplayDevice, rule: SwitchRule) async -> InputSourceSkipCheck {
        let currentResult: CurrentInputSourceVCPValue
        do {
            currentResult = try await cli.currentInputSourceVCPValue(display: display)
        } catch {
            return InputSourceSkipCheck(
                shouldSkip: false,
                reason: "current-read-failed",
                currentRawOutput: nil,
                currentRawValue: nil,
                currentNormalizedValue: nil,
                targetValue: nil,
                targetName: rule.sourceName,
                error: error.localizedDescription
            )
        }

        let targetName = sourceName(displayID: rule.displayID, value: rule.sourceValue, fallback: rule.sourceName)
        guard let targetValue = inputSourceVCPValue(sourceValue: rule.sourceValue, sourceName: targetName) else {
            return InputSourceSkipCheck(
                shouldSkip: false,
                reason: "target-map-failed",
                currentRawOutput: currentResult.rawOutput,
                currentRawValue: currentResult.rawValue,
                currentNormalizedValue: currentResult.normalizedValue,
                targetValue: nil,
                targetName: targetName,
                error: nil
            )
        }

        return InputSourceSkipCheck(
            shouldSkip: currentResult.normalizedValue == targetValue,
            reason: currentResult.normalizedValue == targetValue ? "already-matched" : "needs-change",
            currentRawOutput: currentResult.rawOutput,
            currentRawValue: currentResult.rawValue,
            currentNormalizedValue: currentResult.normalizedValue,
            targetValue: targetValue,
            targetName: targetName,
            error: nil
        )
    }

    private func inputSourceVCPValue(sourceValue: String, sourceName: String) -> Int? {
        if let namedValue = inputSourceVCPValue(fromName: sourceName) {
            return namedValue
        }

        switch Int(sourceValue) {
        case 1:
            return 0x0f
        case 2:
            return 0x10
        case 3:
            return 0x11
        case 4:
            return 0x12
        case 5:
            return 0x13
        case 6:
            return 0x1b
        case 7:
            return 0x1c
        case 8:
            return 0x1d
        case 9:
            return 0x1e
        case 10:
            return 0x03
        case 11:
            return 0x04
        case 12:
            return 0x01
        case 13:
            return 0x02
        case 14:
            return 0x0f
        case 16:
            return 0x1b
        case 17:
            return 0x11
        case 18:
            return 0x12
        default:
            return nil
        }
    }

    private func inputSourceVCPValue(fromName name: String) -> Int? {
        let lower = name.lowercased()
        let index = inputSourceOrdinal(from: lower)
        if lower.contains("displayport") || lower.hasPrefix("dp ") || lower.contains(" dp ") {
            return 0x0f + index - 1
        }
        if lower.contains("hdmi") {
            return 0x11 + index - 1
        }
        if lower.contains("usb-c") || lower.contains("usb c") || lower.contains("thunderbolt") || lower.contains("tb") {
            return 0x1b + index - 1
        }
        if lower.contains("dvi") {
            return 0x03 + index - 1
        }
        if lower.contains("vga") {
            return 0x01 + index - 1
        }
        return nil
    }

    private func inputSourceOrdinal(from text: String) -> Int {
        guard let match = text.firstMatch(of: /\d+/),
              let value = Int(String(match.output)) else {
            return 1
        }
        return max(value, 1)
    }

    func t(_ key: CopyKey) -> String {
        Localization.text(key, language: language)
    }

    func setLanguage(_ newLanguage: AppLanguage) {
        language = newLanguage
        if statusMessage == Localization.text(.ready, language: .english) || statusMessage == Localization.text(.ready, language: .chinese) {
            statusMessage = t(.ready)
        }
        saveConfiguration()
    }

    func setTheme(_ newTheme: AppTheme) {
        theme = newTheme
        saveConfiguration()
    }

    func setSourceCategory(_ category: SourceCategory, isVisible: Bool) {
        if isVisible {
            visibleSourceCategories.insert(category)
        } else {
            visibleSourceCategories.remove(category)
        }
        saveConfiguration()
    }

    func setLocalMacRole(_ role: LocalMacRole) {
        localMacRole = role
        saveConfiguration()
    }

    func connectionActionsPreview(for group: SwitchGroup) -> [DisplayConnectionAction] {
        let reconnectActions = managedDisconnectedDisplays.map {
            DisplayConnectionAction(display: $0, operation: .reconnect, reason: t(.managedReconnectReason))
        }
        return reconnectActions + disconnectActions(for: group)
    }

    func hotkeyRows() -> [(shortcut: String, action: String)] {
        GlobalHotkeyAction.allCases.map { action in
            switch action {
            case .group1, .group2, .group3, .group4:
                let name = action.groupIndex.flatMap { index in
                    groups.indices.contains(index) ? groupDisplayName(groups[index]) : nil
                } ?? "\(t(.groups)) \((action.groupIndex ?? 0) + 1)"
                return (action.shortcut, name)
            case .refresh:
                return (action.shortcut, t(.refresh))
            case .settings:
                return (action.shortcut, t(.settings))
            }
        }
    }

    func runSetupCheck() async {
        guard !isRunningSetupCheck else { return }
        isRunningSetupCheck = true
        defer { isRunningSetupCheck = false }

        var items: [SetupCheckItem] = []

        guard cli.isAvailable() else {
            setupCheckResult = SetupCheckResult(
                items: [
                    SetupCheckItem(
                        status: .failure,
                        title: t(.setupCheckCLI),
                        detail: t(.setupCheckCLIMissing)
                    )
                ],
                summary: t(.setupCheckFailed),
                guidance: t(.setupCheckCLIInstallGuide)
            )
            return
        }

        items.append(SetupCheckItem(
            status: .success,
            title: t(.setupCheckCLI),
            detail: "\(t(.setupCheckCLIReady)): \(cli.executablePath)"
        ))

        do {
            let checkedDisplays = try await cli.listDisplays()
            guard !checkedDisplays.isEmpty else {
                items.append(SetupCheckItem(
                    status: .failure,
                    title: t(.setupCheckDisplays),
                    detail: t(.setupCheckDisplaysMissing)
                ))
                setupCheckResult = SetupCheckResult(
                    items: items,
                    summary: t(.setupCheckFailed),
                    guidance: t(.setupCheckBetterDisplayGuide)
                )
                return
            }

            items.append(SetupCheckItem(
                status: .success,
                title: t(.setupCheckDisplays),
                detail: "\(t(.foundDisplays)) \(localizedDisplayCount(checkedDisplays.count))"
            ))

            var totalSources = 0
            var sourceIssues: [String] = []
            for display in checkedDisplays {
                do {
                    let sources = try await cli.listInputSources(for: display)
                    totalSources += sources.count
                    if sources.isEmpty {
                        sourceIssues.append("\(display.name): \(t(.setupCheckNoInputSources))")
                    }
                } catch {
                    sourceIssues.append("\(display.name): \(error.localizedDescription)")
                }
            }

            if sourceIssues.isEmpty {
                items.append(SetupCheckItem(
                    status: .success,
                    title: t(.setupCheckInputSources),
                    detail: "\(t(.setupCheckInputSourcesReady)): \(totalSources)"
                ))
                setupCheckResult = SetupCheckResult(
                    items: items,
                    summary: t(.setupCheckAllReady),
                    guidance: nil
                )
            } else {
                items.append(SetupCheckItem(
                    status: .warning,
                    title: t(.setupCheckInputSources),
                    detail: sourceIssues.joined(separator: "\n")
                ))
                setupCheckResult = SetupCheckResult(
                    items: items,
                    summary: t(.setupCheckNeedsAttention),
                    guidance: t(.setupCheckInputSourceGuide)
                )
            }
        } catch {
            items.append(SetupCheckItem(
                status: .failure,
                title: t(.setupCheckDisplays),
                detail: error.localizedDescription
            ))
            setupCheckResult = SetupCheckResult(
                items: items,
                summary: t(.setupCheckFailed),
                guidance: t(.setupCheckBetterDisplayGuide)
            )
        }
    }

    private func disconnectActions(for group: SwitchGroup) -> [DisplayConnectionAction] {
        guard group.presetKind?.isSplitPreset == true else { return [] }
        guard let kind = group.presetKind else { return [] }
        let localOwner = localMacRole.macOwner
        let targets = displays.filter { display in
            routeOwner(for: kind, display: display, displayIndex: displayIndex(for: display)) != localOwner
        }

        guard !targets.isEmpty else { return [] }

        let remainingDisplayCount = displays.count - targets.count
        if remainingDisplayCount < 1 {
            logger.warning("Skipping display disconnect because it would leave no external displays connected for this Mac.")
            return []
        }

        return targets.map { display in
            DisplayConnectionAction(
                display: display,
                operation: .disconnect,
                reason: "\(t(.notAssignedToThisMacReason)) \(localMacRole.label(language: language))"
            )
        }
    }

    private func applyConnectionActions(_ actions: [DisplayConnectionAction]) async -> (succeeded: Int, failures: [String]) {
        var succeeded = 0
        var failures: [String] = []

        for action in actions {
            do {
                _ = try await cli.setDisplayConnection(display: action.display, connected: action.operation == .reconnect)
                updateManagedDisconnectedDisplays(for: action)
                logger.info("Display connection \(action.operation.rawValue): display=\(action.display.name), reason=\(action.reason)")
                succeeded += 1
            } catch {
                let actionName = action.operation == .reconnect ? t(.reconnectDisplay) : t(.disconnectDisplay)
                logger.warning("Display connection failed: action=\(action.operation.rawValue), display=\(action.display.name), error=\(error.localizedDescription)")
                failures.append("\(actionName) \(action.display.name): \(error.localizedDescription)")
            }
        }

        if succeeded > 0 {
            saveConfiguration()
        }

        return (succeeded, failures)
    }

    private func updateManagedDisconnectedDisplays(for action: DisplayConnectionAction) {
        switch action.operation {
        case .reconnect:
            managedDisconnectedDisplays.removeAll { $0.stableID == action.display.stableID }
        case .disconnect:
            guard !managedDisconnectedDisplays.contains(where: { $0.stableID == action.display.stableID }) else { return }
            managedDisconnectedDisplays.append(action.display)
        }
    }

    private func reloadDisplaysAfterConnectionChange() async {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        do {
            let fetchedDisplays = try await cli.listDisplays()
            displays = fetchedDisplays
            selectedDisplayID = fetchedDisplays.first { $0.id == selectedDisplayID }?.id ?? fetchedDisplays.first?.id
            try await refreshInputSources(for: fetchedDisplays)
            syncRulesWithCurrentDisplays()
        } catch {
            logger.warning("Display reload after connection change failed: \(error.localizedDescription)")
        }
    }

    private func loadConfiguration() {
        guard let data = try? Data(contentsOf: configurationURL),
              let configuration = try? JSONDecoder().decode(PersistedConfiguration.self, from: data) else {
            return
        }
        language = configuration.language
        theme = configuration.theme
        visibleSourceCategories = configuration.visibleSourceCategories
        localMacRole = configuration.localMacRole
        managedDisconnectedDisplays = configuration.managedDisconnectedDisplays
        groups = normalizePresetGroups(migratePresetGroups(configuration.groups))
        statusMessage = t(.ready)
        selectedGroupID = groups.first?.id
        saveConfiguration()
    }

    private static func detectedLocalMacRole() -> LocalMacRole {
        let hostName = (Host.current().localizedName ?? Host.current().name ?? "").lowercased()
        if hostName.contains("mini") || hostName.contains("personal") || hostName.contains("个人") {
            return .personal
        }
        return .work
    }

    private func saveConfiguration() {
        let configuration = PersistedConfiguration(
            groups: groups,
            language: language,
            theme: theme,
            visibleSourceCategories: visibleSourceCategories,
            localMacRole: localMacRole,
            managedDisconnectedDisplays: managedDisconnectedDisplays
        )
        guard let data = try? JSONEncoder.pretty.encode(configuration) else { return }
        try? data.write(to: configurationURL, options: .atomic)
    }

    private func configureGlobalHotkeys() {
        hotkeyRegistrationIssues = hotkeyManager.registerAll { [weak self] action in
            guard let self else { return }
            switch action {
            case .group1, .group2, .group3, .group4:
                guard let index = action.groupIndex else { return }
                self.requestApplyGroup(at: index)
            case .refresh:
                Task { await self.refreshDisplays() }
            case .settings:
                self.openSettingsWindow()
            }
        }
    }

    private func localizedPresetName(_ kind: GroupPresetKind?) -> String? {
        guard let kind else { return nil }
        switch kind {
        case .workBoth:
            return t(.presetWorkBothName)
        case .personalBoth:
            return t(.presetPersonalBothName)
        case .workLeftPersonalRight:
            return t(.presetWorkLeftPersonalRightName)
        case .personalLeftWorkRight:
            return t(.presetPersonalLeftWorkRightName)
        }
    }

    private func localizedPresetSubtitle(_ kind: GroupPresetKind?) -> String? {
        guard let kind else { return nil }
        switch kind {
        case .workBoth:
            return t(.presetWorkBothSubtitle)
        case .personalBoth:
            return t(.presetPersonalBothSubtitle)
        case .workLeftPersonalRight:
            return t(.presetWorkLeftPersonalRightSubtitle)
        case .personalLeftWorkRight:
            return t(.presetPersonalLeftWorkRightSubtitle)
        }
    }

    private func migratePresetGroups(_ groups: [SwitchGroup]) -> [SwitchGroup] {
        groups.enumerated().map { index, group in
            var migrated = group
            if let routeKind = presetKindFromRoutePattern(group) {
                migrated.presetKind = routeKind
                if !migrated.nameEdited {
                    migrated.name = localizedPresetName(routeKind) ?? migrated.name
                }
                if !migrated.subtitleEdited {
                    migrated.subtitle = localizedPresetSubtitle(routeKind) ?? migrated.subtitle
                }
                return migrated
            }

            guard migrated.presetKind == nil else { return migrated }

            switch (group.name, group.subtitle) {
            case ("Work MacBook Pro", "Both displays to work Mac"):
                migrated.presetKind = .workBoth
            case ("Personal Mac", "Both displays to personal Mac"):
                migrated.presetKind = .personalBoth
            case ("Work Left, Personal Right", "Display A work, Display B personal"):
                migrated.presetKind = .workLeftPersonalRight
            case ("Personal Left, Work Right", "Display A personal, Display B work"):
                migrated.presetKind = .personalLeftWorkRight
            default:
                switch index {
                case 0 where group.symbolName == "briefcase":
                    migrated.presetKind = .workBoth
                case 1 where group.symbolName == "person.crop.circle":
                    migrated.presetKind = .personalBoth
                case 2 where group.symbolName == "rectangle.split.2x1":
                    migrated.presetKind = .workLeftPersonalRight
                case 3 where group.symbolName == "arrow.left.arrow.right":
                    migrated.presetKind = .personalLeftWorkRight
                default:
                    break
                }
                break
            }

            return migrated
        }
    }

    private func presetKindFromRoutePattern(_ group: SwitchGroup) -> GroupPresetKind? {
        guard let u3225 = group.rules.first(where: { isU3225QE($0.displayName) }),
              let p2723 = group.rules.first(where: { isP2723QE($0.displayName) }) else {
            return nil
        }

        switch (u3225.sourceValue, p2723.sourceValue) {
        case ("6", "1"):
            return .workBoth
        case ("1", "6"):
            return .personalBoth
        default:
            return nil
        }
    }

    private func normalizePresetGroups(_ groups: [SwitchGroup]) -> [SwitchGroup] {
        groups.enumerated().map { _, group in
            guard let kind = group.presetKind else { return group }
            var normalized = group
            normalized.name = localizedPresetName(kind) ?? normalized.name
            normalized.subtitle = localizedPresetSubtitle(kind) ?? normalized.subtitle
            normalized.nameEdited = false
            normalized.subtitleEdited = false
            normalized.rules = group.rules.enumerated().map { index, rule in
                guard let owner = routeOwner(for: kind, displayName: rule.displayName, displayIndex: index) else {
                    return enrichOfflineRouteMetadata(rule, owner: nil)
                }
                return presetRule(
                    displayID: rule.displayID,
                    displayName: rule.displayName,
                    owner: owner,
                    enabled: rule.enabled,
                    existingID: rule.id
                )
            }
            return normalized
        }
    }

    private func syncRulesWithCurrentDisplays() {
        for groupIndex in groups.indices {
            var rules = groups[groupIndex].rules
            for display in displays where !rules.contains(where: { $0.displayID == display.id }) {
                let source = inputSources(for: display).first
                rules.append(SwitchRule(
                    displayID: display.id,
                    displayName: display.name,
                    sourceValue: source?.value ?? "",
                    sourceName: source?.name ?? t(.manual),
                    enabled: false
                ))
            }
            groups[groupIndex].rules = rules.map { rule in
                guard let display = displays.first(where: { $0.id == rule.displayID }) else { return rule }
                var updated = rule
                updated.displayName = display.name
                updated.sourceName = sourceName(displayID: display.id, value: rule.sourceValue, fallback: rule.sourceName)
                if let kind = groups[groupIndex].presetKind,
                   let owner = routeOwner(for: kind, display: display, displayIndex: displayIndex(for: display)) {
                    updated = presetRule(for: display, owner: owner, enabled: updated.enabled, existingID: updated.id)
                }
                return enrichRouteMetadata(updated, in: groups[groupIndex])
            }
        }
        saveConfiguration()
    }

    private func makeDefaultGroups(displays: [DisplayDevice]) -> [SwitchGroup] {
        [
            makeGroup(kind: .workBoth, symbol: "briefcase", tint: "cyan", displays: displays),
            makeGroup(kind: .personalBoth, symbol: "person.crop.circle", tint: "green", displays: displays),
            makeGroup(kind: .workLeftPersonalRight, symbol: "rectangle.split.2x1", tint: "orange", displays: displays),
            makeGroup(kind: .personalLeftWorkRight, symbol: "arrow.left.arrow.right", tint: "purple", displays: displays)
        ]
    }

    private func makeGroup(kind: GroupPresetKind, symbol: String, tint: String, displays: [DisplayDevice]) -> SwitchGroup {
        SwitchGroup(
            name: localizedPresetName(kind) ?? "",
            subtitle: localizedPresetSubtitle(kind) ?? "",
            symbolName: symbol,
            tintName: tint,
            rules: displays.enumerated().map { index, display in
                let owner = routeOwner(for: kind, display: display, displayIndex: index) ?? .work
                return presetRule(for: display, owner: owner)
            },
            presetKind: kind
        )
    }

    private func presetRule(for display: DisplayDevice, owner: MacOwner, enabled: Bool = true, existingID: UUID = UUID()) -> SwitchRule {
        let hint = preferredSourceHint(for: display, owner: owner)
        let source = preferredSource(for: display, matching: hint) ?? inputSources(for: display).first
        let sourceName = source?.name ?? hint
        return SwitchRule(
            id: existingID,
            displayID: display.id,
            displayName: display.name,
            sourceValue: source?.value ?? "",
            sourceName: sourceName,
            enabled: enabled,
            sourceDeviceName: owner.displayName(language: language),
            sourceSlot: "USB-C",
            cableType: cableType(for: sourceName),
            targetSlot: sourceName
        )
    }

    private func presetRule(displayID: String, displayName: String, owner: MacOwner, enabled: Bool = true, existingID: UUID = UUID()) -> SwitchRule {
        let hint = preferredSourceHint(forDisplayName: displayName, owner: owner)
        let sourceName = canonicalSourceName(for: hint)
        return SwitchRule(
            id: existingID,
            displayID: displayID,
            displayName: displayName,
            sourceValue: canonicalSourceValue(for: hint),
            sourceName: sourceName,
            enabled: enabled,
            sourceDeviceName: owner.displayName(language: language),
            sourceSlot: "USB-C",
            cableType: cableType(for: sourceName),
            targetSlot: sourceName
        )
    }

    private func enrichRouteMetadata(_ rule: SwitchRule, in group: SwitchGroup) -> SwitchRule {
        var updated = rule
        let display = displays.first { $0.id == rule.displayID }
        let sourceName = sourceName(displayID: rule.displayID, value: rule.sourceValue, fallback: rule.sourceName)
        updated.sourceName = sourceName
        updated.targetSlot = sourceName
        updated.cableType = cableType(for: sourceName)
        if updated.sourceSlot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.sourceSlot = "USB-C"
        }
        if let display,
           let kind = group.presetKind,
           let owner = routeOwner(for: kind, display: display, displayIndex: displayIndex(for: display)) {
            updated.sourceDeviceName = owner.displayName(language: language)
        } else if updated.sourceDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.sourceDeviceName = t(.manual)
        }
        return updated
    }

    private func enrichOfflineRouteMetadata(_ rule: SwitchRule, owner: MacOwner?) -> SwitchRule {
        var updated = rule
        let sourceName = rule.sourceName.isEmpty ? canonicalSourceName(for: rule.sourceValue == "1" ? "DisplayPort 1" : "USB-C") : rule.sourceName
        updated.sourceName = sourceName
        updated.targetSlot = rule.targetSlot.isEmpty ? sourceName : rule.targetSlot
        updated.cableType = rule.cableType.isEmpty ? cableType(for: sourceName) : rule.cableType
        updated.sourceSlot = rule.sourceSlot.isEmpty ? "USB-C" : rule.sourceSlot
        if let owner {
            updated.sourceDeviceName = owner.displayName(language: language)
        } else if updated.sourceDeviceName.isEmpty {
            updated.sourceDeviceName = t(.manual)
        }
        return updated
    }

    private func routeOwner(for kind: GroupPresetKind, display: DisplayDevice, displayIndex: Int) -> MacOwner? {
        routeOwner(for: kind, displayName: display.name, displayIndex: displayIndex)
    }

    private func routeOwner(for kind: GroupPresetKind, displayName: String, displayIndex: Int) -> MacOwner? {
        switch kind {
        case .workBoth:
            return .work
        case .personalBoth:
            return .personal
        case .workLeftPersonalRight:
            if isU3225QE(displayName) { return .work }
            if isP2723QE(displayName) { return .personal }
            return displayIndex == 0 ? .work : .personal
        case .personalLeftWorkRight:
            if isU3225QE(displayName) { return .personal }
            if isP2723QE(displayName) { return .work }
            return displayIndex == 0 ? .personal : .work
        }
    }

    private func preferredSourceHint(for display: DisplayDevice, owner: MacOwner) -> String {
        preferredSourceHint(forDisplayName: display.name, owner: owner)
    }

    private func preferredSourceHint(forDisplayName displayName: String, owner: MacOwner) -> String {
        if isU3225QE(displayName) {
            return owner == .work ? "USB-C" : "DisplayPort 1"
        }
        if isP2723QE(displayName) {
            return owner == .work ? "DisplayPort 1" : "USB-C"
        }
        return owner == .work ? "USB-C" : "DisplayPort 1"
    }

    private func canonicalSourceName(for hint: String) -> String {
        hint.localizedCaseInsensitiveContains("displayport") ? "DisplayPort 1" : "USB-C / TB 1"
    }

    private func canonicalSourceValue(for hint: String) -> String {
        hint.localizedCaseInsensitiveContains("displayport") ? "1" : "6"
    }

    private func cableType(for sourceName: String) -> String {
        let lower = sourceName.lowercased()
        if lower.contains("usb-c") || lower.contains("usb c") || lower.contains("tb") {
            return "Type-C ↔ Type-C"
        }
        if lower.contains("displayport") || lower.hasPrefix("dp ") || lower.contains(" dp ") {
            return "Type-C → DisplayPort"
        }
        if lower.contains("hdmi") {
            return "Type-C → HDMI"
        }
        return "Input cable"
    }

    private func displayIndex(for display: DisplayDevice) -> Int {
        displays.firstIndex { $0.id == display.id } ?? 0
    }

    private func isU3225QE(_ display: DisplayDevice) -> Bool {
        isU3225QE(display.name) || (display.productName ?? "").localizedCaseInsensitiveContains("U3225QE")
    }

    private func isP2723QE(_ display: DisplayDevice) -> Bool {
        isP2723QE(display.name) || (display.productName ?? "").localizedCaseInsensitiveContains("P2723QE")
    }

    private func isU3225QE(_ displayName: String) -> Bool {
        displayName.localizedCaseInsensitiveContains("U3225QE")
    }

    private func isP2723QE(_ displayName: String) -> Bool {
        displayName.localizedCaseInsensitiveContains("P2723QE")
    }

    private func rule(for display: DisplayDevice, hint: String) -> SwitchRule {
        let source = preferredSource(for: display, matching: hint) ?? inputSources(for: display).first
        return SwitchRule(
            displayID: display.id,
            displayName: display.name,
            sourceValue: source?.value ?? "",
            sourceName: source?.name ?? hint,
            enabled: true
        )
    }

    private func preferredSource(for display: DisplayDevice, matching hint: String) -> InputSource? {
        let lower = hint.lowercased()
        return inputSources(for: display).first { source in
            source.name.lowercased().contains(lower)
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension GroupPresetKind {
    var isSplitPreset: Bool {
        switch self {
        case .workLeftPersonalRight, .personalLeftWorkRight:
            return true
        case .workBoth, .personalBoth:
            return false
        }
    }
}

private extension LocalMacRole {
    var macOwner: MacOwner {
        switch self {
        case .work:
            return .work
        case .personal:
            return .personal
        }
    }
}

private enum MacOwner: Equatable {
    case work
    case personal

    func displayName(language: AppLanguage) -> String {
        switch self {
        case .work:
            return Localization.text(.presetWorkBothName, language: language)
        case .personal:
            return Localization.text(.presetPersonalBothName, language: language)
        }
    }
}
