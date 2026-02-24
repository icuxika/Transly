import AppKit
import Carbon
import Foundation

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManagerDidActivate(_ manager: HotkeyManager)
}

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    weak var delegate: HotkeyManagerDelegate?
    
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?
    
    private let defaultHotkey: UInt32 = UInt32(kVK_ANSI_T)
    private let defaultModifiers: UInt32 = UInt32(cmdKey | shiftKey)
    
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
            manager.handleHotkey()
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
        
        var hotkeyID = EventHotKeyID(
            signature: OSType(0x54524E53),
            id: 1
        )
        
        let registerStatus = RegisterEventHotKey(
            defaultHotkey,
            defaultModifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotkeyRef
        )
        
        return registerStatus == noErr
    }
    
    func unregisterHotkey() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func handleHotkey() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.hotkeyManagerDidActivate(self)
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}
