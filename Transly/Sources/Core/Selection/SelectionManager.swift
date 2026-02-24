import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class SelectionManager: SelectionMonitorDelegate {
    var selectedText: String = ""
    var selectionPosition: CGPoint = .zero
    var isShowingFloatingPanel: Bool = false
    var translatedText: String = ""
    var isTranslating: Bool = false
    
    private let selectionMonitor = SelectionMonitor()
    private let translationService = TranslationService.shared
    private let storageService = StorageService.shared
    private let clipboardService = ClipboardService.shared
    
    var sourceLanguage: Language = .auto
    var targetLanguage: Language = .chinese
    
    var hasAccessibilityPermission: Bool {
        selectionMonitor.checkAccessibilityPermission()
    }
    
    init() {
        selectionMonitor.delegate = self
    }
    
    func startMonitoring() {
        guard hasAccessibilityPermission else {
            selectionMonitor.requestAccessibilityPermission()
            return
        }
        selectionMonitor.startMonitoring()
    }
    
    func stopMonitoring() {
        selectionMonitor.stopMonitoring()
    }
    
    nonisolated func selectionMonitor(_ monitor: SelectionMonitor, didDetectSelection text: String, at position: CGPoint) {
        Task { @MainActor in
            await handleSelection(text: text, at: position)
        }
    }
    
    private func handleSelection(text: String, at position: CGPoint) async {
        selectedText = text
        selectionPosition = position
        isShowingFloatingPanel = true
        translatedText = ""
        
        await translateSelection()
    }
    
    func translateSelection() async {
        guard !selectedText.isEmpty else { return }
        
        isTranslating = true
        
        do {
            let result = try await translationService.translate(
                text: selectedText,
                from: sourceLanguage,
                to: targetLanguage
            )
            translatedText = result
            
            let history = TranslationHistory(
                sourceText: selectedText,
                translatedText: result,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            await storageService.addToHistory(history)
        } catch {
            translatedText = "翻译失败: \(error.localizedDescription)"
        }
        
        isTranslating = false
    }
    
    func hideFloatingPanel() {
        isShowingFloatingPanel = false
        selectedText = ""
        translatedText = ""
    }
    
    func copyTranslatedText() async {
        guard !translatedText.isEmpty else { return }
        await clipboardService.copy(translatedText)
    }
    
    func requestPermission() {
        selectionMonitor.requestAccessibilityPermission()
    }
}
