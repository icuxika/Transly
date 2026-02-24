import AppKit
import Foundation

protocol SelectionMonitorDelegate: AnyObject {
    func selectionMonitor(_ monitor: SelectionMonitor, didDetectSelection text: String, at position: CGPoint)
}

final class SelectionMonitor: NSObject {
    weak var delegate: SelectionMonitorDelegate?
    
    private var isMonitoring = false
    private var lastSelectedText = ""
    private var monitorTimer: Timer?
    private let pollingInterval: TimeInterval = 0.2
    
    private let systemWideElement = AXUIElementCreateSystemWide()
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkForSelection()
        }
        
        RunLoop.current.add(monitorTimer!, forMode: .common)
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
    }
    
    private func checkForSelection() {
        let selectedText = getSelectedText()
        
        guard let text = selectedText.text,
              !text.isEmpty,
              text != lastSelectedText else {
            return
        }
        
        lastSelectedText = text
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.selectionMonitor(
                self!,
                didDetectSelection: text,
                at: selectedText.position
            )
        }
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
        
        usleep(50000)
        
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
