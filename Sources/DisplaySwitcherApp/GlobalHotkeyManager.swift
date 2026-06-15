@preconcurrency import Carbon
import Foundation

enum GlobalHotkeyAction: UInt32, CaseIterable {
    case group1 = 1
    case group2 = 2
    case group3 = 3
    case group4 = 4
    case refresh = 10
    case settings = 11

    var groupIndex: Int? {
        switch self {
        case .group1: return 0
        case .group2: return 1
        case .group3: return 2
        case .group4: return 3
        case .refresh, .settings: return nil
        }
    }

    var shortcut: String {
        switch self {
        case .group1: return "⌃⌥⌘1"
        case .group2: return "⌃⌥⌘2"
        case .group3: return "⌃⌥⌘3"
        case .group4: return "⌃⌥⌘4"
        case .refresh: return "⌃⌥⌘R"
        case .settings: return "⌃⌥⌘S"
        }
    }

    fileprivate var keyCode: UInt32 {
        switch self {
        case .group1: return 18
        case .group2: return 19
        case .group3: return 20
        case .group4: return 21
        case .refresh: return 15
        case .settings: return 1
        }
    }
}

struct HotkeyRegistrationIssue: Identifiable {
    var id = UUID()
    var action: GlobalHotkeyAction
    var shortcut: String
    var osStatus: OSStatus
}

final class GlobalHotkeyManager {
    private let signature = fourCharCode("DSHK")
    private let modifiers = UInt32(controlKey | optionKey | cmdKey)
    private var hotkeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (@MainActor (GlobalHotkeyAction) -> Void)?

    deinit {
        unregisterAll()
    }

    func registerAll(onTrigger: @escaping @MainActor (GlobalHotkeyAction) -> Void) -> [HotkeyRegistrationIssue] {
        unregisterAll()
        self.onTrigger = onTrigger
        installHandlerIfNeeded()

        var issues: [HotkeyRegistrationIssue] = []
        for action in GlobalHotkeyAction.allCases {
            var hotkeyRef: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: signature, id: action.rawValue)
            let status = RegisterEventHotKey(
                action.keyCode,
                modifiers,
                hotkeyID,
                GetApplicationEventTarget(),
                0,
                &hotkeyRef
            )

            if status == noErr, let hotkeyRef {
                hotkeyRefs.append(hotkeyRef)
            } else {
                issues.append(HotkeyRegistrationIssue(action: action, shortcut: action.shortcut, osStatus: status))
            }
        }
        return issues
    }

    private func unregisterAll() {
        for hotkeyRef in hotkeyRefs {
            UnregisterEventHotKey(hotkeyRef)
        }
        hotkeyRefs.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotkeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )

                guard status == noErr else { return status }
                manager.handleHotkey(id: hotkeyID.id)
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
    }

    private func handleHotkey(id: UInt32) {
        guard let action = GlobalHotkeyAction(rawValue: id) else { return }
        let handler = onTrigger
        Task { @MainActor in
            handler?(action)
        }
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { result, character in
        (result << 8) + OSType(character)
    }
}
