import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section(appState.t(.language)) {
                Picker(appState.t(.language), selection: Binding(
                    get: { appState.language },
                    set: { appState.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label(language: appState.language)).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(appState.t(.appearance)) {
                Picker(appState.t(.theme), selection: Binding(
                    get: { appState.theme },
                    set: { appState.setTheme($0) }
                )) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label(language: appState.language)).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(appState.t(.globalHotkeys)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.teal)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.t(.globalHotkeys))
                                .font(.headline)
                            Text(appState.t(.globalHotkeysDescription))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }

                    VStack(spacing: 6) {
                        ForEach(Array(appState.hotkeyRows().enumerated()), id: \.offset) { _, row in
                            HotkeyRow(shortcut: row.shortcut, action: row.action)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "capslock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.teal)
                            .frame(width: 20)
                        Text(appState.t(.hotkeyHyperTip))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))

                    if !appState.hotkeyRegistrationIssues.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(appState.t(.hotkeyConflict))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)

                            ForEach(appState.hotkeyRegistrationIssues) { issue in
                                Text("\(issue.shortcut) · OSStatus \(issue.osStatus)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
                    }
                }
                .padding(.vertical, 4)
            }

            Section(appState.t(.setupCheck)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checklist.checked")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.teal)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.t(.setupCheck))
                                .font(.headline)
                            Text(appState.t(.setupCheckDescription))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            Task { await appState.runSetupCheck() }
                        } label: {
                            Label(
                                appState.isRunningSetupCheck ? appState.t(.checkingSetup) : appState.t(.runSetupCheck),
                                systemImage: "play.circle"
                            )
                        }
                        .disabled(appState.isRunningSetupCheck)
                    }

                    if appState.isRunningSetupCheck {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let result = appState.setupCheckResult {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(result.summary)
                                .font(.system(size: 13, weight: .semibold))

                            ForEach(result.items) { item in
                                SetupCheckRow(item: item)
                            }

                            if let guidance = result.guidance {
                                Text(guidance)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding(22)
        .frame(width: 560)
    }
}

private struct HotkeyRow: View {
    let shortcut: String
    let action: String

    var body: some View {
        HStack(spacing: 12) {
            Text(action)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 12)

            KeycapCluster(shortcut: shortcut)
        }
        .frame(minHeight: 30)
    }
}

private struct KeycapCluster: View {
    let shortcut: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(shortcut.map(String.init).enumerated()), id: \.offset) { _, key in
                Keycap(text: key)
            }
        }
        .accessibilityLabel(shortcut)
    }
}

private struct Keycap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(minWidth: 24, minHeight: 24)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: 1)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColors.border, lineWidth: 1))
    }
}

private struct SetupCheckRow: View {
    let item: SetupCheckItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
    }

    private var symbolName: String {
        switch item.status {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failure: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var color: Color {
        switch item.status {
        case .success: return .green
        case .warning: return .orange
        case .failure: return .red
        case .info: return .blue
        }
    }
}

struct ApplyConfirmationView: View {
    @EnvironmentObject private var appState: AppState
    let group: SwitchGroup

    private var enabledRules: [SwitchRule] {
        group.rules.filter { $0.enabled && !$0.sourceValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var disabledRules: [SwitchRule] {
        group.rules.filter { !$0.enabled || $0.sourceValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.teal))

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.t(.applyConfirmationTitle))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(appState.t(.applyConfirmationSubtitle))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.groupDisplayName(group))
                    .font(.headline)
                Text(appState.groupDisplaySubtitle(group))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ConfirmationSection(title: appState.t(.enabledRules), rules: enabledRules, isEnabledSection: true)
                    if !disabledRules.isEmpty {
                        ConfirmationSection(title: appState.t(.disabledRules), rules: disabledRules, isEnabledSection: false)
                    }
                }
            }

            HStack {
                Button(appState.t(.cancel)) {
                    appState.cancelPendingApply()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(appState.t(.confirmApply)) {
                    Task { await appState.confirmPendingApply() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .keyboardShortcut(.defaultAction)
                .disabled(enabledRules.isEmpty || appState.isApplying)
            }
        }
        .padding(22)
    }
}

private struct ConfirmationSection: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let rules: [SwitchRule]
    let isEnabledSection: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(rules) { rule in
                HStack(spacing: 10) {
                    Image(systemName: isEnabledSection ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundStyle(isEnabledSection ? .teal : .secondary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(rule.displayName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(detailText(for: rule))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
            }
        }
    }

    private func detailText(for rule: SwitchRule) -> String {
        guard isEnabledSection else { return appState.t(.disabledRules) }
        let displayStatus = appState.displays.contains { $0.id == rule.displayID } ? "" : " \(appState.t(.disconnected))"
        let sourceName = appState.sourceName(displayID: rule.displayID, value: rule.sourceValue, fallback: rule.sourceName)
        return "\(appState.t(.willSwitch)): \(sourceName) (\(appState.t(.source)) \(rule.sourceValue))\(displayStatus)"
    }
}

struct AppIconView: View {
    var body: some View {
        if let image = AppIconProvider.image {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: "display.2")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(.teal.gradient))
        }
    }
}

private enum AppIconProvider {
    static var image: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
}

extension AppTheme {
    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}
