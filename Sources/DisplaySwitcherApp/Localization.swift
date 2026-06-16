import Foundation

enum CopyKey: String {
    case appName
    case cliName
    case groups
    case add
    case resetPresetGroups
    case resetPresetGroupsHelp
    case deleteSelectedGroup
    case inputSourceConsole
    case consoleSubtitle
    case refresh
    case refreshing
    case applyGroup
    case applying
    case displays
    case noDisplaysTitle
    case noDisplaysSubtitle
    case sources
    case product
    case vendorModel
    case made
    case unknown
    case strategy
    case graphPreview
    case graphPreviewDescription
    case inputsAndCables
    case sourceDevices
    case lineAndSlots
    case outputDisplays
    case activeRoute
    case inactiveRoute
    case groupName
    case subtitle
    case presetStrategy
    case noGroupTitle
    case noGroupSubtitle
    case disconnectedDisplay
    case manualID
    case manual
    case applyThisSource
    case quickSwitch
    case switchSingleDisplay
    case display
    case source
    case sourceFilters
    case sourceFiltersHint
    case showingSources
    case noVisibleSourcesTitle
    case noVisibleSourcesSubtitle
    case language
    case english
    case chinese
    case settings
    case appearance
    case theme
    case lightTheme
    case darkTheme
    case localMacRole
    case localMacRoleDescription
    case workMacRole
    case personalMacRole
    case displayConnectionManagement
    case managedDisconnectedDisplays
    case reconnectDisplay
    case disconnectDisplay
    case reconnectingDisplays
    case disconnectingDisplays
    case reconnectedDisplays
    case disconnectedDisplays
    case managedReconnectReason
    case notAssignedToThisMacReason
    case noManagedDisconnectedDisplays
    case applyConfirmationTitle
    case applyConfirmationSubtitle
    case confirmApply
    case cancel
    case enabledRules
    case disabledRules
    case willSwitch
    case disconnected
    case usageGuide
    case appGuideTab
    case cliGuideTab
    case usageOverview
    case usageStepRefresh
    case usageStepQuickSwitch
    case usageStepGroups
    case usageStepFilters
    case usageStepSettings
    case usageShortcut
    case globalHotkeys
    case globalHotkeysDescription
    case hotkeyConflict
    case hotkeyHyperTip
    case setupCheck
    case runSetupCheck
    case checkingSetup
    case setupCheckCLI
    case setupCheckCLIReady
    case setupCheckCLIMissing
    case setupCheckCLIInstallGuide
    case setupCheckDisplays
    case setupCheckDisplaysMissing
    case setupCheckBetterDisplayGuide
    case setupCheckInputSources
    case setupCheckInputSourcesReady
    case setupCheckNoInputSources
    case setupCheckInputSourceGuide
    case setupCheckAllReady
    case setupCheckNeedsAttention
    case setupCheckFailed
    case setupCheckDescription
    case ready
    case refreshingDisplays
    case noBetterDisplayDisplays
    case foundDisplays
    case refreshFailed
    case newGroup
    case customStrategy
    case presetWorkBothName
    case presetWorkBothSubtitle
    case presetPersonalBothName
    case presetPersonalBothSubtitle
    case presetWorkLeftPersonalRightName
    case presetWorkLeftPersonalRightSubtitle
    case presetPersonalLeftWorkRightName
    case presetPersonalLeftWorkRightSubtitle
    case applyingGroup
    case appliedGroup
    case appliedDisplays
    case skippedDisplays
    case appliedWithIssues
    case switchingDisplay
    case switchedDisplay
    case switchFailed
}

enum Localization {
    static func text(_ key: CopyKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            english[key] ?? key.rawValue
        case .chinese:
            chinese[key] ?? english[key] ?? key.rawValue
        }
    }

    private static let english: [CopyKey: String] = [
        .appName: "Display Switcher",
        .cliName: "BetterDisplay CLI",
        .groups: "Groups",
        .add: "Add",
        .resetPresetGroups: "Reset Presets",
        .resetPresetGroupsHelp: "Restore the four default strategy groups and keep custom groups.",
        .deleteSelectedGroup: "Delete selected group",
        .inputSourceConsole: "Input Source Console",
        .consoleSubtitle: "Connected displays, source maps, and one-click Mac switching",
        .refresh: "Refresh",
        .refreshing: "Refreshing",
        .applyGroup: "Apply Group",
        .applying: "Applying",
        .displays: "Displays",
        .noDisplaysTitle: "No switchable external displays yet",
        .noDisplaysSubtitle: "Connect an external monitor, then refresh after BetterDisplay and CLI integration are enabled.",
        .sources: "sources",
        .product: "Product",
        .vendorModel: "Vendor / Model",
        .made: "Made",
        .unknown: "Unknown",
        .strategy: "Strategy",
        .graphPreview: "Graph Preview",
        .graphPreviewDescription: "Live map of input cables to displays for the selected strategy.",
        .inputsAndCables: "Inputs / Cables",
        .sourceDevices: "Source",
        .lineAndSlots: "Line / Slots",
        .outputDisplays: "Displays",
        .activeRoute: "Active route",
        .inactiveRoute: "Inactive route",
        .groupName: "Group name",
        .subtitle: "Subtitle",
        .presetStrategy: "Preset",
        .noGroupTitle: "No group selected",
        .noGroupSubtitle: "Create a strategy group to start mapping displays.",
        .disconnectedDisplay: "Disconnected display",
        .manualID: "Manual ID",
        .manual: "Manual",
        .applyThisSource: "Apply this source",
        .quickSwitch: "Quick Switch",
        .switchSingleDisplay: "Switch a single display immediately",
        .display: "Display",
        .source: "Source",
        .sourceFilters: "Source Filters",
        .sourceFiltersHint: "Choose which input types appear in Quick Switch.",
        .showingSources: "Showing",
        .noVisibleSourcesTitle: "No input sources are visible",
        .noVisibleSourcesSubtitle: "Enable at least one input type above.",
        .language: "Language",
        .english: "英语",
        .chinese: "中文",
        .settings: "Settings",
        .appearance: "Appearance",
        .theme: "Theme",
        .lightTheme: "White",
        .darkTheme: "Black",
        .localMacRole: "This Mac",
        .localMacRoleDescription: "Used by split presets to decide which physical display this Mac keeps connected.",
        .workMacRole: "Work MacBook Pro",
        .personalMacRole: "Personal Mac mini",
        .displayConnectionManagement: "Display Connection Management",
        .managedDisconnectedDisplays: "Managed disconnected displays",
        .reconnectDisplay: "Reconnect",
        .disconnectDisplay: "Disconnect",
        .reconnectingDisplays: "Reconnecting displays",
        .disconnectingDisplays: "Disconnecting displays",
        .reconnectedDisplays: "reconnected",
        .disconnectedDisplays: "disconnected",
        .managedReconnectReason: "Restore display previously disconnected by this app",
        .notAssignedToThisMacReason: "Not assigned to",
        .noManagedDisconnectedDisplays: "No displays are currently managed as disconnected by this app.",
        .applyConfirmationTitle: "Review Strategy",
        .applyConfirmationSubtitle: "Confirm the display input changes before BetterDisplay switches sources.",
        .confirmApply: "Confirm and Switch",
        .cancel: "Cancel",
        .enabledRules: "Enabled",
        .disabledRules: "Disabled",
        .willSwitch: "Will switch",
        .disconnected: "Disconnected",
        .usageGuide: "Usage Guide",
        .appGuideTab: "App Guide",
        .cliGuideTab: "BetterDisplay CLI",
        .usageOverview: "Use Display Switcher to switch monitor input sources between Macs through BetterDisplay CLI.",
        .usageStepRefresh: "Refresh Displays: load connected displays and their available input sources.",
        .usageStepQuickSwitch: "Quick Switch: select one display and switch only that monitor immediately.",
        .usageStepGroups: "Strategy Groups: map every display to an input source, then apply the group after confirmation.",
        .usageStepFilters: "Source Filters: hide noisy input types from Quick Switch without deleting them.",
        .usageStepSettings: "Settings: choose interface language and white or black theme.",
        .usageShortcut: "Global shortcuts: Control-Option-Command-1 through 4 open confirmation for the first four strategy groups.",
        .globalHotkeys: "Global Hotkeys",
        .globalHotkeysDescription: "Available anywhere. Strategy shortcuts always ask for confirmation first.",
        .hotkeyConflict: "Some hotkeys could not be registered. They may already be used by macOS or another app.",
        .hotkeyHyperTip: "Hyper tip: map Caps Lock to ⌃⌥⌘⇧, then press Caps Lock + 1-4.",
        .setupCheck: "Initialization Check",
        .runSetupCheck: "Run Check",
        .checkingSetup: "Checking...",
        .setupCheckCLI: "BetterDisplay CLI",
        .setupCheckCLIReady: "Ready",
        .setupCheckCLIMissing: "betterdisplaycli was not found.",
        .setupCheckCLIInstallGuide: "Install BetterDisplay, enable integration in BetterDisplay settings, then install the CLI with: brew install waydabber/betterdisplay/betterdisplaycli",
        .setupCheckDisplays: "External Displays",
        .setupCheckDisplaysMissing: "No switchable external displays were returned by BetterDisplay CLI.",
        .setupCheckBetterDisplayGuide: "Open BetterDisplay and make sure integration features are enabled. Confirm the displays are connected and visible in BetterDisplay, then run Refresh Displays.",
        .setupCheckInputSources: "Input Sources",
        .setupCheckInputSourcesReady: "Input sources found",
        .setupCheckNoInputSources: "no input sources returned",
        .setupCheckInputSourceGuide: "If input sources are missing, check that the display supports input switching through DDC/CI and that BetterDisplay has DDC/input-source control enabled for that display. Some monitors or adapters may expose no switchable sources.",
        .setupCheckAllReady: "Everything looks ready.",
        .setupCheckNeedsAttention: "Setup needs attention.",
        .setupCheckFailed: "Setup check failed.",
        .setupCheckDescription: "Check CLI availability, connected displays, and whether each display exposes input sources.",
        .ready: "Ready",
        .refreshingDisplays: "Refreshing displays...",
        .noBetterDisplayDisplays: "No switchable external displays found",
        .foundDisplays: "Found",
        .refreshFailed: "Refresh failed",
        .newGroup: "New Group",
        .customStrategy: "Custom input source strategy",
        .presetWorkBothName: "Work MacBook Pro",
        .presetWorkBothSubtitle: "Both displays to work Mac",
        .presetPersonalBothName: "Personal Mac",
        .presetPersonalBothSubtitle: "Both displays to personal Mac",
        .presetWorkLeftPersonalRightName: "Work Left, Personal Right",
        .presetWorkLeftPersonalRightSubtitle: "U3225QE to work Mac, P2723QE to personal Mac",
        .presetPersonalLeftWorkRightName: "Personal Left, Work Right",
        .presetPersonalLeftWorkRightSubtitle: "U3225QE to personal Mac, P2723QE to work Mac",
        .applyingGroup: "Applying",
        .appliedGroup: "Applied",
        .appliedDisplays: "switched",
        .skippedDisplays: "skipped",
        .appliedWithIssues: "Applied with issues",
        .switchingDisplay: "Switching",
        .switchedDisplay: "Switched",
        .switchFailed: "Switch failed"
    ]

    private static let chinese: [CopyKey: String] = [
        .appName: "显示器切换器",
        .cliName: "BetterDisplay CLI",
        .groups: "策略组",
        .add: "新增",
        .resetPresetGroups: "重置预设",
        .resetPresetGroupsHelp: "恢复四个默认策略组，并保留自定义策略组。",
        .deleteSelectedGroup: "删除当前策略组",
        .inputSourceConsole: "输入源控制台",
        .consoleSubtitle: "查看显示器、编辑输入源策略，并一键切换两台 Mac",
        .refresh: "刷新",
        .refreshing: "刷新中",
        .applyGroup: "应用策略",
        .applying: "应用中",
        .displays: "显示器",
        .noDisplaysTitle: "还没有可切换的外接显示器",
        .noDisplaysSubtitle: "连接外接显示器，并启用 BetterDisplay 集成功能后刷新。",
        .sources: "个输入源",
        .product: "产品",
        .vendorModel: "厂商 / 型号",
        .made: "制造时间",
        .unknown: "未知",
        .strategy: "策略",
        .graphPreview: "图形预览",
        .graphPreviewDescription: "实时展示当前策略中输入线材到显示器的映射关系。",
        .inputsAndCables: "输入 / 线材",
        .sourceDevices: "源设备",
        .lineAndSlots: "线材 / 槽位",
        .outputDisplays: "显示器",
        .activeRoute: "启用线路",
        .inactiveRoute: "停用线路",
        .groupName: "策略组名称",
        .subtitle: "说明",
        .presetStrategy: "内置预设",
        .noGroupTitle: "未选择策略组",
        .noGroupSubtitle: "创建一个策略组后即可配置显示器输入源。",
        .disconnectedDisplay: "显示器未连接",
        .manualID: "手动编号",
        .manual: "手动",
        .applyThisSource: "应用这个输入源",
        .quickSwitch: "快速切换",
        .switchSingleDisplay: "立即切换单个显示器",
        .display: "显示器",
        .source: "输入源",
        .sourceFilters: "输入源筛选",
        .sourceFiltersHint: "选择哪些输入类型显示在快速切换里。",
        .showingSources: "正在显示",
        .noVisibleSourcesTitle: "没有可显示的输入源",
        .noVisibleSourcesSubtitle: "请在上方至少启用一种输入类型。",
        .language: "语言",
        .english: "English",
        .chinese: "中文",
        .settings: "设置",
        .appearance: "外观",
        .theme: "主题",
        .lightTheme: "白色",
        .darkTheme: "黑色",
        .localMacRole: "这台 Mac",
        .localMacRoleDescription: "分屏预设会根据这个身份判断本机应该保留哪台真实显示器。",
        .workMacRole: "工作 MacBook Pro",
        .personalMacRole: "个人 Mac mini",
        .displayConnectionManagement: "显示器连接管理",
        .managedDisconnectedDisplays: "由本应用托管断开的显示器",
        .reconnectDisplay: "恢复连接",
        .disconnectDisplay: "断开",
        .reconnectingDisplays: "正在恢复显示器",
        .disconnectingDisplays: "正在断开显示器",
        .reconnectedDisplays: "已恢复",
        .disconnectedDisplays: "已断开",
        .managedReconnectReason: "恢复之前由本应用断开的显示器",
        .notAssignedToThisMacReason: "不分配给",
        .noManagedDisconnectedDisplays: "当前没有由本应用托管断开的显示器。",
        .applyConfirmationTitle: "确认策略",
        .applyConfirmationSubtitle: "BetterDisplay 切换输入源前，请先确认下面的显示器变更。",
        .confirmApply: "确认并切换",
        .cancel: "取消",
        .enabledRules: "已启用",
        .disabledRules: "已停用",
        .willSwitch: "将切换",
        .disconnected: "未连接",
        .usageGuide: "使用说明",
        .appGuideTab: "应用使用说明",
        .cliGuideTab: "BetterDisplay CLI",
        .usageOverview: "显示器切换器通过 BetterDisplay CLI 在多台 Mac 之间切换显示器输入源。",
        .usageStepRefresh: "刷新显示器：读取已连接显示器和可用输入源。",
        .usageStepQuickSwitch: "快速切换：选择一个显示器，只切换这一台。",
        .usageStepGroups: "策略组：为每台显示器配置输入源，确认后一次应用整组策略。",
        .usageStepFilters: "输入源筛选：隐藏快速切换里的噪音输入类型，不会删除输入源。",
        .usageStepSettings: "设置：选择界面语言，以及白色或黑色主题。",
        .usageShortcut: "全局快捷键：Control-Option-Command-1 到 4 会打开前四个策略组的确认窗口。",
        .globalHotkeys: "全局快捷键",
        .globalHotkeysDescription: "随时可用。策略快捷键会先弹出确认窗口。",
        .hotkeyConflict: "部分快捷键注册失败，可能已经被 macOS 或其他应用占用。",
        .hotkeyHyperTip: "Hyper Key：用 Karabiner-Elements 把 Caps Lock 映射为 ⌃⌥⌘⇧，再按 Caps Lock + 1-4。",
        .setupCheck: "初始化检查",
        .runSetupCheck: "开始检查",
        .checkingSetup: "检查中...",
        .setupCheckCLI: "BetterDisplay CLI",
        .setupCheckCLIReady: "已就绪",
        .setupCheckCLIMissing: "未找到 betterdisplaycli。",
        .setupCheckCLIInstallGuide: "请先安装 BetterDisplay，并在 BetterDisplay 设置里启用集成功能，然后安装 CLI：brew install waydabber/betterdisplay/betterdisplaycli",
        .setupCheckDisplays: "外接显示器",
        .setupCheckDisplaysMissing: "BetterDisplay CLI 没有返回可切换的外接显示器。",
        .setupCheckBetterDisplayGuide: "请打开 BetterDisplay，确认集成功能已启用，显示器已经连接并能在 BetterDisplay 里看到，然后回到本应用刷新显示器。",
        .setupCheckInputSources: "输入源",
        .setupCheckInputSourcesReady: "已找到输入源",
        .setupCheckNoInputSources: "没有返回输入源",
        .setupCheckInputSourceGuide: "如果输入源缺失，请确认显示器支持通过 DDC/CI 切换输入源，并在 BetterDisplay 中为该显示器启用 DDC/输入源控制。部分显示器或转接器可能不会暴露可切换输入源。",
        .setupCheckAllReady: "初始化看起来已经就绪。",
        .setupCheckNeedsAttention: "初始化需要处理。",
        .setupCheckFailed: "初始化检查失败。",
        .setupCheckDescription: "检查 CLI 是否可用、显示器是否能读取、以及每台显示器是否暴露输入源。",
        .ready: "就绪",
        .refreshingDisplays: "正在刷新显示器...",
        .noBetterDisplayDisplays: "未找到可切换的外接显示器",
        .foundDisplays: "已找到",
        .refreshFailed: "刷新失败",
        .newGroup: "新策略组",
        .customStrategy: "自定义输入源策略",
        .presetWorkBothName: "工作 MacBook Pro",
        .presetWorkBothSubtitle: "两台显示器都切到工作 Mac",
        .presetPersonalBothName: "个人 Mac",
        .presetPersonalBothSubtitle: "两台显示器都切到个人 Mac",
        .presetWorkLeftPersonalRightName: "左工作，右个人",
        .presetWorkLeftPersonalRightSubtitle: "U3225QE 给工作 Mac，P2723QE 给个人 Mac",
        .presetPersonalLeftWorkRightName: "左个人，右工作",
        .presetPersonalLeftWorkRightSubtitle: "U3225QE 给个人 Mac，P2723QE 给工作 Mac",
        .applyingGroup: "正在应用",
        .appliedGroup: "已应用",
        .appliedDisplays: "已切换",
        .skippedDisplays: "已跳过",
        .appliedWithIssues: "应用完成但有问题",
        .switchingDisplay: "正在切换",
        .switchedDisplay: "已切换",
        .switchFailed: "切换失败"
    ]
}

extension AppLanguage {
    func label(language: AppLanguage) -> String {
        switch self {
        case .english:
            Localization.text(.english, language: language)
        case .chinese:
            Localization.text(.chinese, language: language)
        }
    }
}

extension AppTheme {
    func label(language: AppLanguage) -> String {
        switch self {
        case .light:
            Localization.text(.lightTheme, language: language)
        case .dark:
            Localization.text(.darkTheme, language: language)
        }
    }
}

extension LocalMacRole {
    func label(language: AppLanguage) -> String {
        switch self {
        case .work:
            Localization.text(.workMacRole, language: language)
        case .personal:
            Localization.text(.personalMacRole, language: language)
        }
    }
}

extension SourceCategory {
    func label(language: AppLanguage) -> String {
        switch self {
        case .usbC: return "USB-C / TB"
        case .displayPort: return "DisplayPort"
        case .hdmi: return "HDMI"
        case .dviVga: return "DVI / VGA"
        case .legacy:
            return language == .chinese ? "旧接口" : "Legacy"
        case .other:
            return language == .chinese ? "其他" : "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .usbC: return "cable.connector"
        case .displayPort: return "display"
        case .hdmi: return "video"
        case .dviVga: return "rectangle.connected.to.line.below"
        case .legacy: return "clock"
        case .other: return "ellipsis.circle"
        }
    }
}
