import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class SelectionManager: SelectionMonitorDelegate {
    var selectedText: String = ""
    var selectionPosition: CGPoint = .zero
    
    private let selectionMonitor = SelectionMonitor()
    
    init() {
        selectionMonitor.delegate = self
    }
    
    func getSelectedTextNow() -> SelectionResult {
        selectionMonitor.getSelectedTextNow()
    }
    
    var hasAccessibilityPermission: Bool {
        selectionMonitor.checkAccessibilityPermission()
    }
    
    func requestPermission() {
        selectionMonitor.requestAccessibilityPermission()
    }
    
    nonisolated func selectionMonitor(_ monitor: SelectionMonitor, didDetectSelection text: String, at position: CGPoint) {
        Task { @MainActor in
            selectedText = text
            selectionPosition = position
        }
    }
}
