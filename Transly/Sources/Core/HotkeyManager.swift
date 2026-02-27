import AppKit
import Carbon
import Foundation

enum HotkeyAction {
    case inputTranslation
    case selectionTranslation
    case accessibilitySelectionTranslation
    case ocrTranslation
    case clipboardTranslation
}

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManager(_ manager: HotkeyManager, didActivate action: HotkeyAction)
}

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    weak var delegate: HotkeyManagerDelegate?
    
    private var eventHandler: EventHandlerRef?
    private var hotkeyRefs: [EventHotKeyRef?] = []
    
    private let hotkeyConfigs: [(action: HotkeyAction, keyCode: UInt32, modifiers: UInt32)] = [
        (.inputTranslation, UInt32(kVK_ANSI_A), UInt32(optionKey)),
        (.selectionTranslation, UInt32(kVK_ANSI_D), UInt32(optionKey)),
        (.accessibilitySelectionTranslation, UInt32(kVK_ANSI_F), UInt32(optionKey)),
        (.ocrTranslation, UInt32(kVK_ANSI_S), UInt32(optionKey)),
        (.clipboardTranslation, UInt32(kVK_ANSI_V), UInt32(optionKey))
    ]
    
    private init() {}
    
    func registerHotkey() -> Bool {
        unregisterHotkey()
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotkeyEvent(event)
            return noErr
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
        
        guard status == noErr else { return false }
        
        var allRegistered = true
        for (index, config) in hotkeyConfigs.enumerated() {
            var hotkeyID = EventHotKeyID(
                signature: OSType(0x54524E53),
                id: UInt32(index + 1)
            )
            
            var hotkeyRef: EventHotKeyRef?
            let registerStatus = RegisterEventHotKey(
                config.keyCode,
                config.modifiers,
                hotkeyID,
                GetEventDispatcherTarget(),
                0,
                &hotkeyRef
            )
            
            if registerStatus == noErr {
                hotkeyRefs.append(hotkeyRef)
            } else {
                allRegistered = false
            }
        }
        
        return allRegistered
    }
    
    func unregisterHotkey() {
        for hotkeyRef in hotkeyRefs {
            if let ref = hotkeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotkeyRefs.removeAll()
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func handleHotkeyEvent(_ event: EventRef?) {
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
        
        guard status == noErr else { return }
        
        let index = Int(hotkeyID.id) - 1
        guard index >= 0, index < hotkeyConfigs.count else { return }
        
        let action = hotkeyConfigs[index].action
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.hotkeyManager(self, didActivate: action)
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}
