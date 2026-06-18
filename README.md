# Display Switcher

A native macOS SwiftUI app for switching connected monitor input sources through BetterDisplay CLI.

## What it does

- Lists displays reported by `betterdisplaycli get --identifiers`
- Shows monitor identity details such as name, serial, vendor, model, and manufacture date
- Loads input source options from `betterdisplaycli get --name=<display> --inputSourceList`
- Switches a single display with one click
- Filters Quick Switch input sources by type, including USB-C / Thunderbolt, DisplayPort, HDMI, DVI / VGA, legacy inputs, and other inputs
- Switches the app interface between English and Chinese from Settings
- Supports white and black themes from Settings
- Reviews strategy details in a confirmation modal before applying a group
- Shows a live strategy graph mapping input cables/sources to displays
- Includes an in-app Markdown help center with app usage and BetterDisplay CLI notes
- Includes a Settings initialization check for CLI readiness, displays, and input sources
- Registers low-conflict global hotkeys for the first four strategy groups
- Uses a resizable sidebar for group navigation
- Can reset the four default preset strategy groups while preserving custom groups
- Saves editable switch groups for multi-display workflows:
  - Work MacBook Pro on both displays
  - Personal Mac on both displays
  - Work left / personal right
  - Personal left / work right

## Requirements

Install BetterDisplay and enable its integration features. Then install the CLI:

```sh
brew install waydabber/betterdisplay/betterdisplaycli
```

The app looks for `betterdisplaycli` in `/opt/homebrew/bin`, `/usr/local/bin`, or `PATH`.

## Build

Run as a Swift package:

```sh
swift run DisplaySwitcher
```

Build a macOS app bundle:

```sh
chmod +x Scripts/build-app.sh
Scripts/build-app.sh
open "/Applications/Display Switcher.app"
```

The build script installs the finished bundle into `/Applications` by default. Use
`INSTALL_APP=0 Scripts/build-app.sh` when you only want the bundle under `build/`.

Configuration is saved at:

```text
~/Library/Application Support/DisplaySwitcher/configuration.json
```

## Global hotkeys

Default global hotkeys:

```text
Control + Option + Command + 1  Work MacBook Pro / group 1
Control + Option + Command + 2  Personal Mac / group 2
Control + Option + Command + 3  Split strategy / group 3
Control + Option + Command + 4  Split strategy / group 4
Control + Option + Command + R  Refresh displays
Control + Option + Command + S  Open Settings
```

Group hotkeys open the confirmation modal first; they do not switch displays silently.

For a more comfortable workflow, map Caps Lock to a Hyper key with Karabiner-Elements:

```text
Caps Lock = Control + Option + Command + Shift
```

Then use `Caps Lock + 1` through `Caps Lock + 4` as muscle-memory shortcuts for the four display strategies.

## Use on another Mac

Recommended flow:

1. Build the app on this Mac:

   ```sh
   Scripts/build-app.sh
   ```

2. Copy this bundle to the other Mac:

   ```text
   build/Display Switcher.app
   ```

3. On the other Mac, install BetterDisplay and the CLI:

   ```sh
   brew install waydabber/betterdisplay/betterdisplaycli
   ```

4. Open BetterDisplay on that Mac and enable integration features.
5. Open Display Switcher, go to Settings, and run Initialization Check.
6. Refresh displays and edit the strategy groups for that Mac.

Avoid blindly copying `configuration.json` between Macs unless you know the display identifiers match. BetterDisplay display UUIDs and tag IDs can differ per Mac, so strategy groups may point to stale display IDs after migration.

## Roadmap

- Peer-to-peer Mac sync: let the app instances on two Macs communicate directly, so editing strategies or route metadata on either Mac can update the other side.
- Cross-Mac control: support setting input sources for the other Mac from the current Mac, so either machine can switch the whole desk.
- Mobile app: build an iPhone app for direct display input switching and strategy control.
- Display connection management: optionally disconnect inactive displays after strategy switching; see `features-coming.md`.
- Display mode memory: remember each display's resolution, refresh rate, HDR state, and scaling per strategy, then restore the preferred mode after input switching so monitors do not fall back to default resolution.
- Logging: add an in-app log view for CLI calls, hotkey triggers, strategy confirmations, input-source switching results, setup checks, and errors.
- New interface from design tooling: rebuild the interface from the design prototype while keeping feature logic and UI rendering separated.
- Route editor: expose source device, source slot, cable type, and target slot as first-class editable fields instead of only inferring them from presets.
