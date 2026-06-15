import SwiftUI

enum HelpDocumentTab: String, CaseIterable, Identifiable {
    case app
    case cli

    var id: String { rawValue }
}

struct MarkdownHelpCenterView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: HelpDocumentTab = .app

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AppIconView()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.t(.usageGuide))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(appState.t(.usageOverview))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(appState.t(.cancel)) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(22)

            Picker("", selection: $selectedTab) {
                Text(appState.t(.appGuideTab)).tag(HelpDocumentTab.app)
                Text(appState.t(.cliGuideTab)).tag(HelpDocumentTab.cli)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 22)
            .padding(.bottom, 14)

            Divider()

            MarkdownDocumentView(markdown: markdown)
        }
    }

    private var markdown: String {
        switch selectedTab {
        case .app:
            return HelpDocuments.appGuide(language: appState.language)
        case .cli:
            return HelpDocuments.cliGuide(language: appState.language)
        }
    }
}

struct MarkdownDocumentView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parse(markdown)) { block in
                    blockView(block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(AppColors.windowBackground)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading1:
            Text(block.text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 6)
        case .heading2:
            Text(block.text)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.top, 8)
        case .heading3:
            Text(block.text)
                .font(.system(size: 15, weight: .bold))
                .padding(.top, 4)
        case .paragraph:
            Text(.init(block.text))
                .font(.system(size: 13))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet:
            HStack(alignment: .top, spacing: 9) {
                Text("•")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.teal)
                Text(.init(block.text))
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .numbered:
            HStack(alignment: .top, spacing: 9) {
                Text(block.marker ?? "1.")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.teal)
                    .frame(width: 26, alignment: .leading)
                Text(.init(block.text))
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .code:
            Text(block.text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
        }
    }

    private func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var code: [String] = []
        var isCode = false

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(MarkdownBlock(kind: .paragraph, text: paragraph.joined(separator: " ")))
            paragraph.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if isCode {
                    blocks.append(MarkdownBlock(kind: .code, text: code.joined(separator: "\n")))
                    code.removeAll()
                    isCode = false
                } else {
                    flushParagraph()
                    isCode = true
                }
                continue
            }

            if isCode {
                code.append(rawLine)
                continue
            }

            guard !line.isEmpty else {
                flushParagraph()
                continue
            }

            if line.hasPrefix("### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .heading3, text: String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .heading2, text: String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .heading1, text: String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .bullet, text: String(line.dropFirst(2))))
            } else if let range = line.range(of: #"^\d+\. "#, options: .regularExpression) {
                flushParagraph()
                let marker = String(line[range]).trimmingCharacters(in: .whitespaces)
                let text = String(line[range.upperBound...])
                blocks.append(MarkdownBlock(kind: .numbered, text: text, marker: marker))
            } else {
                paragraph.append(line)
            }
        }

        flushParagraph()
        if isCode, !code.isEmpty {
            blocks.append(MarkdownBlock(kind: .code, text: code.joined(separator: "\n")))
        }

        return blocks
    }
}

private struct MarkdownBlock: Identifiable {
    var id = UUID()
    var kind: MarkdownBlockKind
    var text: String
    var marker: String?
}

private enum MarkdownBlockKind {
    case heading1
    case heading2
    case heading3
    case paragraph
    case bullet
    case numbered
    case code
}

enum HelpDocuments {
    static func appGuide(language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishAppGuide
        case .chinese:
            return chineseAppGuide
        }
    }

    static func cliGuide(language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishCLIGuide
        case .chinese:
            return chineseCLIGuide
        }
    }

    private static let chineseAppGuide = """
# 显示器切换器使用说明

## 第一次使用

1. 安装 BetterDisplay，并在 BetterDisplay 设置里启用 Integration / CLI。
2. 安装 CLI：

```sh
brew install waydabber/betterdisplay/betterdisplaycli
```

3. 打开本应用，进入 **设置 → 初始化检查**。
4. 检查通过后，回到主界面点击 **刷新**。
5. 在策略组里确认每台显示器对应的输入源。

## 策略组

- 左侧是策略组列表，默认前四个组适合两台 Mac + 两台显示器。
- 前四个内置预设不可编辑，避免误删或误改。
- 新建自定义策略组后，可以编辑每台显示器要切到的输入源。
- 点击 **应用策略** 会先显示确认窗口，确认后才会切换。
- `Command-Return` 会打开当前策略的确认窗口。

## 快速切换

- 选择一台显示器后，可以在 **快速切换** 中只切换这一台。
- 输入源筛选可以隐藏不常用的旧接口、其他等输入源。
- 筛选只是隐藏显示，不会删除 BetterDisplay 返回的输入源。

## 全局快捷键

- `Ctrl + Option + Command + 1`：第 1 个策略组
- `Ctrl + Option + Command + 2`：第 2 个策略组
- `Ctrl + Option + Command + 3`：第 3 个策略组
- `Ctrl + Option + Command + 4`：第 4 个策略组
- `Ctrl + Option + Command + R`：刷新显示器
- `Ctrl + Option + Command + S`：打开设置

策略快捷键也会先打开确认窗口，不会静默切换。

## Hyper Key 建议

如果你使用 Karabiner-Elements，可以把 `Caps Lock` 映射为 `Ctrl + Option + Command + Shift`。这样可以形成更顺手的 `Caps Lock + 1-4` 工作流。

## 另一台 Mac 怎么用

1. 复制 `Display Switcher.app` 到另一台 Mac。
2. 在那台 Mac 安装 BetterDisplay 和 `betterdisplaycli`。
3. 打开设置并运行初始化检查。
4. 刷新显示器，确认内置预设，必要时新建自定义策略组。

不要盲目复制 `configuration.json`，因为 BetterDisplay 的显示器 UUID / tagID 可能在不同 Mac 上不同。
"""

    private static let englishAppGuide = """
# Display Switcher Guide

## First run

1. Install BetterDisplay and enable Integration / CLI in BetterDisplay settings.
2. Install the CLI:

```sh
brew install waydabber/betterdisplay/betterdisplaycli
```

3. Open this app and run **Settings → Initialization Check**.
4. When the check passes, return to the main window and click **Refresh**.
5. Review the input source mapping for each strategy group.

## Strategy groups

- The sidebar lists your strategy groups. The first four defaults are designed for two Macs and two displays.
- The first four presets are read-only to prevent accidental edits or deletion.
- Create a custom group when you want to edit which input source each display should use.
- **Apply Group** opens a confirmation window before switching.
- `Command-Return` opens confirmation for the selected strategy.

## Quick Switch

- Pick one display and switch only that monitor.
- Source filters hide noisy categories such as `Legacy` or `Other`.
- Filters only affect the UI; they do not delete sources returned by BetterDisplay.

## Global hotkeys

- `Ctrl + Option + Command + 1`: group 1
- `Ctrl + Option + Command + 2`: group 2
- `Ctrl + Option + Command + 3`: group 3
- `Ctrl + Option + Command + 4`: group 4
- `Ctrl + Option + Command + R`: refresh displays
- `Ctrl + Option + Command + S`: open Settings

Strategy hotkeys open confirmation first; they do not switch silently.

## Hyper Key tip

With Karabiner-Elements, map `Caps Lock` to `Ctrl + Option + Command + Shift` for a comfortable `Caps Lock + 1-4` workflow.

## Use on another Mac

1. Copy `Display Switcher.app` to the other Mac.
2. Install BetterDisplay and `betterdisplaycli` on that Mac.
3. Run Initialization Check in Settings.
4. Refresh displays, review the presets, and create custom groups if needed.

Avoid blindly copying `configuration.json` because BetterDisplay display UUIDs and tag IDs can differ per Mac.
"""

    private static let chineseCLIGuide = """
# BetterDisplay CLI 速查

## 前置条件

- 安装 BetterDisplay。
- 在 BetterDisplay 设置中启用 Integration / CLI。
- 通过 Homebrew 安装 CLI：

```sh
brew install waydabber/betterdisplay/betterdisplaycli
```

## 检查 CLI

```sh
which betterdisplaycli
betterdisplaycli help
```

如果找不到 CLI，本应用的设置 → 初始化检查会显示安装指引。

## 列出显示器

```sh
betterdisplaycli get --identifiers
```

常用字段：

- `name`：BetterDisplay 显示名称
- `tagID`：BetterDisplay 本机唯一 ID
- `UUID`：macOS 为这台机器生成的显示器 UUID
- `productName` / `serial`：显示器产品和序列号

## 列出输入源

```sh
betterdisplaycli get --name="DELL U3225QE" --inputSourceList
```

返回示例：

```text
1 - DisplayPort 1 [DDCController]
3 - HDMI 1 [DDCController]
6 - USB-C / TB 1 [DDCController]
```

本应用会把这些输入源解析成快速切换按钮和自定义策略组下拉选项。

## 切换输入源

```sh
betterdisplaycli perform --name="DELL U3225QE" --changeInputSource=6
```

更稳定的方式是使用 `tagID`：

```sh
betterdisplaycli perform --tagID=26 --changeInputSource=6
```

本应用优先使用 `tagID`，其次使用 `UUID`，最后才使用 `name`。

## 常见问题

### CLI 有了，但没有显示器

- 打开 BetterDisplay，确认显示器在 BetterDisplay 里可见。
- 确认 Integration / CLI 已启用。
- 重新运行本应用的初始化检查。

### 显示器有了，但没有输入源

- 显示器需要支持 DDC/CI 输入源切换。
- 在 BetterDisplay 中确认该显示器的 DDC / Input Source 控制可用。
- 部分转接器、扩展坞或显示器不会暴露可切换输入源。

### 输入源切换失败

- 确认输入源编号和显示器匹配。
- 先在 BetterDisplay 内手动测试该显示器是否能切换输入。
- 有些显示器切换后会短暂断连，等待几秒再刷新。
"""

    private static let englishCLIGuide = """
# BetterDisplay CLI Quick Reference

## Requirements

- Install BetterDisplay.
- Enable Integration / CLI in BetterDisplay settings.
- Install the CLI with Homebrew:

```sh
brew install waydabber/betterdisplay/betterdisplaycli
```

## Check the CLI

```sh
which betterdisplaycli
betterdisplaycli help
```

If the CLI is missing, this app's Settings → Initialization Check shows install guidance.

## List displays

```sh
betterdisplaycli get --identifiers
```

Useful fields:

- `name`: BetterDisplay display name
- `tagID`: BetterDisplay local unique ID
- `UUID`: macOS display UUID for this Mac
- `productName` / `serial`: product and serial identifiers

## List input sources

```sh
betterdisplaycli get --name="DELL U3225QE" --inputSourceList
```

Example output:

```text
1 - DisplayPort 1 [DDCController]
3 - HDMI 1 [DDCController]
6 - USB-C / TB 1 [DDCController]
```

The app parses these as Quick Switch buttons and strategy group picker options.

## Change input source

```sh
betterdisplaycli perform --name="DELL U3225QE" --changeInputSource=6
```

Using `tagID` is more stable:

```sh
betterdisplaycli perform --tagID=26 --changeInputSource=6
```

The app prefers `tagID`, then `UUID`, then `name`.

## Troubleshooting

### CLI works, but no displays appear

- Open BetterDisplay and confirm the displays are visible there.
- Confirm Integration / CLI is enabled.
- Run this app's Initialization Check again.

### Displays appear, but input sources are empty

- The display must support DDC/CI input switching.
- Confirm DDC / Input Source control is available for the display in BetterDisplay.
- Some adapters, docks, or displays do not expose switchable input sources.

### Switching fails

- Confirm the input source number belongs to that display.
- Test input switching inside BetterDisplay first.
- Some displays disconnect briefly after switching; wait a few seconds and refresh.
"""
}
