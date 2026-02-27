import AppKit
import Foundation

enum AccessibilitySelectionResult {
    case success(String)
    case noSelection
    case permissionDenied
}

final class AccessibilitySelectionService {
    static let shared = AccessibilitySelectionService()
    
    private init() {}
    
    func checkPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    func getSelectedText() -> AccessibilitySelectionResult {
        guard checkPermission() else {
            return .permissionDenied
        }
        
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedApp: AnyObject?
        let focusedAppResult = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        guard focusedAppResult == .success, let focusedAppElement = focusedApp as? AXUIElement else {
            return .noSelection
        }
        
        var focusedWindow: AnyObject?
        _ = AXUIElementCopyAttributeValue(focusedAppElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if let focusedWindowElement = focusedWindow as? AXUIElement {
            if let text = getSelectedTextFromElement(focusedWindowElement) {
                return .success(text)
            }
        }
        
        var focusedUIElement: AnyObject?
        _ = AXUIElementCopyAttributeValue(focusedAppElement, kAXFocusedUIElementAttribute as CFString, &focusedUIElement)
        
        if let focusedElement = focusedUIElement as? AXUIElement {
            if let text = getSelectedTextFromElement(focusedElement) {
                return .success(text)
            }
        }
        
        return .noSelection
    }
    
    private func getSelectedTextFromElement(_ element: AXUIElement) -> String? {
        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            return text
        }
        
        var selectedRange: AnyObject?
        let rangeResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRange)
        
        if rangeResult == .success, let rangeValue = selectedRange as? AXValue {
            var range = CFRange()
            if AXValueGetValue(rangeValue, .cfRange, &range), range.length > 0 {
                var value: AnyObject?
                let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
                
                if valueResult == .success, let fullText = value as? String {
                    let startIndex = fullText.index(fullText.startIndex, offsetBy: range.location)
                    let endIndex = fullText.index(startIndex, offsetBy: range.length)
                    return String(fullText[startIndex..<endIndex])
                }
            }
        }
        
        return nil
    }
    
    func getSelectedTextWithFallback() async -> AccessibilitySelectionResult {
        let result = getSelectedText()
        
        if case .success = result {
            return result
        }
        
        return await getSelectedTextViaClipboard()
    }
    
    private func getSelectedTextViaClipboard() async -> AccessibilitySelectionResult {
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        keyDownEvent?.flags = .maskCommand
        keyDownEvent?.post(tap: .cghidEventTap)
        
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        keyUpEvent?.post(tap: .cghidEventTap)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let selectedText = pasteboard.string(forType: .string)
        
        if let old = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(old, forType: .string)
        }
        
        if let text = selectedText, !text.isEmpty {
            return .success(text)
        }
        
        return .noSelection
    }
}
