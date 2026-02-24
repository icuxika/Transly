import Foundation
import SwiftUI

@MainActor
@Observable
final class TranslationViewModel {
    var inputText: String = ""
    var translatedText: String = ""
    var sourceLanguage: Language = .auto
    var targetLanguage: Language = .chinese
    var isTranslating: Bool = false
    var errorMessage: String?
    
    private let translationService = TranslationService.shared
    private let storageService = StorageService.shared
    private let clipboardService = ClipboardService.shared
    
    var canTranslate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
    }
    
    func translate() async {
        guard canTranslate else { return }
        
        isTranslating = true
        errorMessage = nil
        translatedText = ""
        
        do {
            let result = try await translationService.translate(
                text: inputText,
                from: sourceLanguage,
                to: targetLanguage
            )
            translatedText = result
            
            let history = TranslationHistory(
                sourceText: inputText,
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
    
    func swapLanguages() {
        if sourceLanguage != .auto {
            swap(&sourceLanguage, &targetLanguage)
        }
    }
    
    func copyResult() async {
        guard !translatedText.isEmpty else { return }
        await clipboardService.copy(translatedText)
    }
    
    func pasteFromClipboard() async {
        if let text = await clipboardService.paste() {
            inputText = text
        }
    }
    
    func clearInput() {
        inputText = ""
        translatedText = ""
        errorMessage = nil
    }
}
