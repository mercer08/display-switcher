import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppColors.windowBackground
            .ignoresSafeArea()

            HSplitView {
                SidebarView()
                    .frame(minWidth: 240, idealWidth: 292, maxWidth: 420)

                MainWorkspaceView()
                    .frame(minWidth: 720)
            }
        }
        .foregroundStyle(Color.primary)
        .preferredColorScheme(appState.theme.colorScheme)
        .sheet(isPresented: $appState.isShowingUsageGuide) {
            MarkdownHelpCenterView()
                .environmentObject(appState)
                .frame(width: 760, height: 680)
                .preferredColorScheme(appState.theme.colorScheme)
        }
        .sheet(item: Binding(
            get: { appState.pendingApplyGroup },
            set: { newValue in
                if newValue == nil { appState.cancelPendingApply() }
            }
        )) { group in
            ApplyConfirmationView(group: group)
                .environmentObject(appState)
                .frame(width: 560, height: 520)
        }
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    AppIconView()
                        .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.t(.appName))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text(appState.t(.cliName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: appState.t(.groups), systemImage: "rectangle.stack")

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(appState.groups.enumerated()), id: \.element.id) { index, group in
                            GroupRow(group: group, isSelected: group.id == appState.selectedGroup?.id)
                                .onTapGesture {
                                    appState.selectedGroupID = group.id
                                }
                                .onTapGesture(count: 2) {
                                    appState.requestApplyGroup(at: index)
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack(spacing: 8) {
                Button {
                    appState.addGroup()
                } label: {
                    Label(appState.t(.add), systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    appState.resetPresetGroups()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 28)
                }
                .buttonStyle(.bordered)
                .help(appState.t(.resetPresetGroupsHelp))

                Button {
                    appState.deleteSelectedGroup()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 28)
                }
                .buttonStyle(.bordered)
                .disabled(appState.groups.count <= 1 || appState.selectedGroup?.isPreset != false)
                .help(appState.t(.deleteSelectedGroup))
            }

            StatusPanel()
        }
        .padding(18)
        .background(AppColors.sidebarBackground)
    }
}

private struct GroupRow: View {
    @EnvironmentObject private var appState: AppState
    let group: SwitchGroup
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: group.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(group.tintColor)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(group.tintColor.opacity(0.14)))

            VStack(alignment: .leading, spacing: 3) {
                Text(appState.groupDisplayName(group))
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(appState.groupDisplaySubtitle(group))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.teal)
            }
        }
        .padding(10)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : AppColors.border, lineWidth: 1)
        }
    }
}

private struct MainWorkspaceView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 18) {
                    DisplayOverview()
                    StrategyEditor()
                    QuickSwitchPanel()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct TopBar: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.t(.inputSourceConsole))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(appState.t(.consoleSubtitle))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.showUsageGuide()
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.bordered)
            .help(appState.t(.usageGuide))

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.bordered)
            .help(appState.t(.settings))

            Button {
                Task { await appState.refreshDisplays() }
            } label: {
                Label(appState.isRefreshing ? appState.t(.refreshing) : appState.t(.refresh), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(appState.isRefreshing || appState.isApplying)

            Button {
                appState.requestApplySelectedGroup()
            } label: {
                Label(appState.isApplying ? appState.t(.applying) : appState.t(.applyGroup), systemImage: "bolt.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .disabled(appState.selectedGroup == nil || appState.isRefreshing || appState.isApplying)
        }
    }
}

private struct DisplayOverview: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: appState.t(.displays), systemImage: "display")

            if appState.displays.isEmpty {
                EmptyState(
                    icon: "display.trianglebadge.exclamationmark",
                    title: appState.t(.noDisplaysTitle),
                    subtitle: appState.t(.noDisplaysSubtitle)
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 12)], spacing: 12) {
                    ForEach(appState.displays) { display in
                        DisplayCard(display: display)
                    }
                }
            }
        }
    }
}

private struct DisplayCard: View {
    @EnvironmentObject private var appState: AppState
    let display: DisplayDevice

    var body: some View {
        Button {
            appState.selectedDisplayID = display.id
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: "display")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.teal)
                        .frame(width: 42, height: 42)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.12)))

                    Spacer()

                    Text("\(appState.inputSources(for: display).count) \(appState.t(.sources))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(display.name)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)
                    Text(display.shortIdentity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    InfoLine(title: appState.t(.product), value: display.productName ?? display.originalName ?? display.name)
                    InfoLine(title: appState.t(.vendorModel), value: compactPair(display.vendor, display.model))
                    InfoLine(title: appState.t(.made), value: display.manufactureSummary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(appState.selectedDisplay?.id == display.id ? Color.accentColor.opacity(0.75) : AppColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func compactPair(_ first: String?, _ second: String?) -> String {
        [first, second].compactMap { item in
            guard let item, !item.isEmpty else { return nil }
            return item
        }.joined(separator: " / ").nonEmpty ?? appState.t(.unknown)
    }
}

private struct StrategyEditor: View {
    @EnvironmentObject private var appState: AppState
    @State private var groupName = ""
    @State private var groupSubtitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: appState.t(.strategy), systemImage: "slider.horizontal.3")

            if let group = appState.selectedGroup {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: group.symbolName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(group.tintColor)
                            .frame(width: 42, height: 42)
                            .background(RoundedRectangle(cornerRadius: 8).fill(group.tintColor.opacity(0.14)))

                        if group.isPreset {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(appState.groupDisplayName(group))
                                        .font(.system(size: 17, weight: .bold))
                                    Text(appState.t(.presetStrategy))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.teal)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.teal.opacity(0.12)))
                                }

                                Text(appState.groupDisplaySubtitle(group))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            TextField(appState.t(.groupName), text: Binding(
                                get: { appState.groupDisplayName(group) },
                                set: { value in
                                    appState.updateGroupName(groupID: group.id, name: value)
                                }
                            ))
                            .textFieldStyle(.roundedBorder)

                            TextField(appState.t(.subtitle), text: Binding(
                                get: { appState.groupDisplaySubtitle(group) },
                                set: { value in
                                    appState.updateGroupSubtitle(groupID: group.id, subtitle: value)
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }

                        Spacer(minLength: 0)
                    }

                    StrategyGraphView(group: group)

                    VStack(spacing: 8) {
                        ForEach(group.rules) { rule in
                            if group.isPreset {
                                RuleSummaryRow(rule: rule)
                            } else {
                                RuleEditorRow(groupID: group.id, rule: rule)
                            }
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
            } else {
                EmptyState(icon: "rectangle.stack.badge.plus", title: appState.t(.noGroupTitle), subtitle: appState.t(.noGroupSubtitle))
            }
        }
    }
}

private struct RuleSummaryRow: View {
    @EnvironmentObject private var appState: AppState
    let rule: SwitchRule

    private var display: DisplayDevice? {
        appState.displays.first { $0.id == rule.displayID }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rule.enabled ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(rule.enabled ? .teal : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(display?.name ?? rule.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(display?.shortIdentity ?? appState.t(.disconnectedDisplay))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 210, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(sourceText)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(routeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
    }

    private var sourceText: String {
        let name = appState.sourceName(displayID: rule.displayID, value: rule.sourceValue, fallback: rule.sourceName)
        return "\(appState.t(.source)) \(rule.sourceValue): \(name)"
    }

    private var routeText: String {
        let source = rule.sourceDeviceName.isEmpty ? appState.t(.sourceDevices) : rule.sourceDeviceName
        let cable = rule.cableType.isEmpty ? appState.t(.lineAndSlots) : rule.cableType
        return "\(source) · \(cable)"
    }
}

private struct RuleEditorRow: View {
    @EnvironmentObject private var appState: AppState
    let groupID: SwitchGroup.ID
    let rule: SwitchRule

    private var display: DisplayDevice? {
        appState.displays.first { $0.id == rule.displayID }
    }

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { value in
                    var updated = rule
                    updated.enabled = value
                    appState.updateRule(groupID: groupID, rule: updated)
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(display?.name ?? rule.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(display?.shortIdentity ?? appState.t(.disconnectedDisplay))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 210, alignment: .leading)

            Picker("", selection: Binding(
                get: { rule.sourceValue },
                set: { value in
                    var updated = rule
                    updated.sourceValue = value
                    updated.sourceName = appState.sourceName(displayID: rule.displayID, value: value, fallback: rule.sourceName)
                    appState.updateRule(groupID: groupID, rule: updated)
                }
            )) {
                ForEach(appState.inputSourcesByDisplayID[rule.displayID] ?? []) { source in
                    Text(source.displayName).tag(source.value)
                }
                if !rule.sourceValue.isEmpty,
                   !(appState.inputSourcesByDisplayID[rule.displayID] ?? []).contains(where: { $0.value == rule.sourceValue }) {
                    Text("\(rule.sourceName) (\(rule.sourceValue))").tag(rule.sourceValue)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .disabled(display == nil)

            TextField(appState.t(.manualID), text: Binding(
                get: { rule.sourceValue },
                set: { value in
                    var updated = rule
                    updated.sourceValue = value
                    updated.sourceName = appState.sourceName(displayID: rule.displayID, value: value, fallback: appState.t(.manual))
                    appState.updateRule(groupID: groupID, rule: updated)
                }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 92)

            if let display,
               let source = appState.inputSources(for: display).first(where: { $0.value == rule.sourceValue }) {
                Button {
                    Task { await appState.applySingle(display: display, source: source) }
                } label: {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                }
                .buttonStyle(.bordered)
                .help("\(appState.t(.applyThisSource)) \(display.name)")
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
    }
}

private struct QuickSwitchPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: appState.t(.quickSwitch), systemImage: "bolt")

            if let display = appState.selectedDisplay {
                let allSources = appState.inputSources(for: display)
                let visibleSources = appState.visibleInputSources(for: display)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(display.name)
                                .font(.headline)
                            Text(appState.t(.switchSingleDisplay))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker(appState.t(.display), selection: Binding(
                            get: { display.id },
                            set: { appState.selectedDisplayID = $0 }
                        )) {
                            ForEach(appState.displays) { item in
                                Text(item.name).tag(item.id)
                            }
                        }
                        .frame(width: 220)
                    }

                    SourceFilterEditor(visibleCount: visibleSources.count, totalCount: allSources.count)

                    if visibleSources.isEmpty {
                        EmptyState(
                            icon: "line.3.horizontal.decrease.circle",
                            title: appState.t(.noVisibleSourcesTitle),
                            subtitle: appState.t(.noVisibleSourcesSubtitle)
                        )
                        .frame(minHeight: 120)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                            ForEach(visibleSources) { source in
                                Button {
                                    Task { await appState.applySingle(display: display, source: source) }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: source.category.symbolName)
                                            .foregroundStyle(.teal)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .lineLimit(1)
                                            Text("\(appState.t(.source)) \(source.value)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
                                .disabled(appState.isApplying)
                            }
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
            } else {
                EmptyState(icon: "bolt.badge.xmark", title: appState.t(.noDisplaysTitle), subtitle: appState.t(.noDisplaysSubtitle))
            }
        }
    }
}

private struct SourceFilterEditor: View {
    @EnvironmentObject private var appState: AppState
    let visibleCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.t(.sourceFilters))
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(appState.t(.showingSources)) \(visibleCount) / \(totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(appState.t(.sourceFiltersHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 8)], spacing: 8) {
                ForEach(SourceCategory.allCases) { category in
                    Toggle(isOn: Binding(
                        get: { appState.visibleSourceCategories.contains(category) },
                        set: { appState.setSourceCategory(category, isVisible: $0) }
                    )) {
                        Label(category.label(language: appState.language), systemImage: category.symbolName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
    }
}

private struct StatusPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .opacity(appState.isRefreshing || appState.isApplying ? 1 : 0)

                Text(appState.statusMessage)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)

                Spacer()
            }

            if let lastError = appState.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(5)
                    .textSelection(.enabled)
            }

            Divider()

            Text(AppVersionInfo.current.displayText)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .help(AppVersionInfo.current.detailText)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.teal)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
    }
}

private struct InfoLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
    }
}

private struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.teal)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
    }
}

enum AppColors {
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
    static let cardBackground = Color(nsColor: .textBackgroundColor)
    static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let border = Color.primary.opacity(0.12)
}

private extension SwitchGroup {
    var tintColor: Color {
        switch tintName {
        case "cyan": return .cyan
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "blue": return .blue
        default: return .teal
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
