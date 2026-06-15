# Features Coming

## Display Connection Management

### Goal

When two Macs are physically connected to two monitors, each Mac may still see both displays even when only one display is actively showing that Mac's input. The goal is to optionally disconnect the inactive displays on the current Mac after applying a strategy, so windows do not remain on a monitor that is showing the other Mac.

Example for **Work Left, Personal Right**:

- Work Mac keeps `U3225QE` connected and disconnects `P2723QE`.
- Personal Mac keeps `P2723QE` connected and disconnects `U3225QE`.

### Feasibility

BetterDisplay supports disconnecting and reconnecting displays. The CLI documentation includes global commands such as `disconnectAllButMain` and `connectAllDisplays`, and display groups expose `enabled`, `active`, and activation policy controls.

The open question is whether the CLI can safely disconnect or reconnect a specific physical display by identifier. If BetterDisplay only exposes broad global commands for this use case, the app should not automate it yet because it could disconnect the wrong screen.

### Recommended Design

Add an experimental setting:

```text
Disconnect inactive displays after switching
```

Default: off.

When enabled, applying a strategy should:

1. Record the current display state, including active displays, main display, resolution, refresh rate, HDR state, and scaling.
2. Apply the input-source strategy.
3. Wait for BetterDisplay/macOS display re-enumeration.
4. Determine which displays should remain active on the current Mac.
5. Disconnect only the current Mac's inactive displays.
6. Log every disconnect decision and BetterDisplay CLI call.
7. Later, restore saved display mode state after reconnecting.

### Phase 1: Local Safe Mode

Only manage displays on the current Mac.

- Add the experimental setting in Settings.
- Default it to off.
- Only disconnect displays that are inactive for the selected strategy on this Mac.
- Do not automatically reconnect displays yet.
- Add detailed logs for detection, skip, disconnect, and failure cases.
- Require manual confirmation before enabling the feature.

This phase is useful even before peer-to-peer sync exists, but it cannot fully coordinate both Macs.

### Phase 2: Peer-to-Peer Coordination

After peer-to-peer Mac communication exists:

- Applying a strategy on either Mac notifies the other Mac.
- Each Mac applies its own active/inactive display plan.
- Both Macs can disconnect inactive displays and reconnect active displays consistently.
- Strategy edits and route metadata sync between devices.

This is the correct path for a complete four-display-state workflow.

### Risks

- Windows can move to or remain on a disconnected display if state handling is wrong.
- The main display must never be disconnected accidentally.
- Display disconnection can reset resolution, refresh rate, HDR, scaling, or arrangement.
- The other Mac's state is unknown without peer-to-peer coordination.
- BetterDisplay disconnect/reconnect may require Pro features.
- Some displays may reconnect immediately if managed by BetterDisplay virtual-screen association or another automation.

### Related Roadmap Items

- Peer-to-peer Mac sync.
- Cross-Mac control.
- Display mode memory.
- Logging.
