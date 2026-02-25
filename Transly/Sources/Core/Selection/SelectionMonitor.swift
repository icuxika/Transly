import AppKit
import Foundation

enum SelectionResult {
    case success(String)
    case noSelection
}

@objc protocol SelectionMonitorDelegate: AnyObject {
    @objc optional func selectionMonitor(_ monitor: SelectionMonitor, didDetectSelection text: String, at position: CGPoint)
}

final class SelectionMonitor: NSObject {
    weak var delegate: SelectionMonitorDelegate?
    
    private(set) var lastSelectedText = ""
    
    func getSelectedTextNow() -> SelectionResult {
        let result = getSelectedText()
        
        if let text = result.text, !text.isEmpty {
            lastSelectedText = text
            return .success(text)
        }
        
        return .noSelection
    }
    
    private func getSelectedText() -> (text: String?, position: CGPoint) {
        let pasteboard = NSPasteboard.general
        
        let oldContents = pasteboard.string(forType: .string)
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        keyDownEvent?.flags = .maskCommand
        keyDownEvent?.post(tap: .cghidEventTap)
        
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        keyUpEvent?.post(tap: .cghidEventTap)
        
        usleep(100000)
        
        let selectedText = pasteboard.string(forType: .string)
        
        if let old = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(old, forType: .string)
        }
        
        let mouseLocation = NSEvent.mouseLocation
        let position = CGPoint(
            x: mouseLocation.x,
            y: mouseLocation.y
        )
        
        return (selectedText, position)
    }
    
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
