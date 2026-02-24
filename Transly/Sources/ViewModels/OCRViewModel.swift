import AppKit
import SwiftUI

@MainActor
@Observable
final class OCRViewModel {
    var capturedImage: NSImage?
    var recognizedText: String = ""
    var translatedText: String = ""
    var isProcessing: Bool = false
    var isTranslating: Bool = false
    var errorMessage: String?
    var showSelectionOverlay: Bool = false
    
    var sourceLanguage: Language = .auto
    var targetLanguage: Language = .chinese
    
    private let screenshotCapture = ScreenshotCapture.shared
    private let ocrService = OCRService.shared
    private let translationService = TranslationService.shared
    private let storageService = StorageService.shared
    private let clipboardService = ClipboardService.shared
    
    var hasScreenRecordingPermission: Bool {
        get async {
            await screenshotCapture.checkScreenRecordingPermission()
        }
    }
    
    func requestScreenRecordingPermission() async {
        await screenshotCapture.requestScreenRecordingPermission()
    }
    
    func captureAndRecognize() async {
        isProcessing = true
        errorMessage = nil
        capturedImage = nil
        recognizedText = ""
        translatedText = ""
        
        do {
            let image = try await screenshotCapture.captureScreen()
            capturedImage = image
            
            let result = try await ocrService.recognizeText(in: image)
            recognizedText = result.text
            
            if !recognizedText.isEmpty {
                await translateRecognizedText()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    func translateRecognizedText() async {
        guard !recognizedText.isEmpty else { return }
        
        isTranslating = true
        
        do {
            let result = try await translationService.translate(
                text: recognizedText,
                from: sourceLanguage,
                to: targetLanguage
            )
            translatedText = result
            
            let history = TranslationHistory(
                sourceText: recognizedText,
                translatedText: result,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            await storageService.addToHistory(history)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isTranslating = false
    }
    
    func copyRecognizedText() async {
        guard !recognizedText.isEmpty else { return }
        await clipboardService.copy(recognizedText)
    }
    
    func copyTranslatedText() async {
        guard !translatedText.isEmpty else { return }
        await clipboardService.copy(translatedText)
    }
    
    func clear() {
        capturedImage = nil
        recognizedText = ""
        translatedText = ""
        errorMessage = nil
    }
}
