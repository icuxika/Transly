import Foundation
import NaturalLanguage
import Translation
import SwiftUI

@available(macOS 15.0, *)
@MainActor
class AppleTranslationManager: ObservableObject {
    static let shared = AppleTranslationManager()
    
    @Published var languageStatuses: [String: LanguageAvailability.Status] = [:]
    @Published var isCheckingLanguages = false
    
    private init() {}
    
    func translate(text: String, from sourceLanguage: Locale.Language?, to targetLanguage: Locale.Language) async throws -> String {
        let windowRef = UncheckedSendable<NSWindow?>(nil)
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    let config = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
                    
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                        styleMask: .borderless,
                        backing: .buffered,
                        defer: true
                    )
                    window.isReleasedWhenClosed = false
                    windowRef.value = window
                    
                    if Task.isCancelled {
                        window.contentView = nil
                        window.close()
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    let bridge = TranslationBridgeView(text: text, configuration: config) { result in
                        continuation.resume(with: result)
                        Task { @MainActor in
                            window.contentView = nil
                            window.close()
                        }
                    }
                    
                    let hostingView = NSHostingView(rootView: bridge)
                    window.contentView = hostingView
                    window.orderBack(nil)
                }
            }
        } onCancel: {
            Task { @MainActor in
                windowRef.value?.contentView = nil
                windowRef.value?.close()
                windowRef.value = nil
            }
        }
    }
    
    func checkLanguageAvailability(from sourceCode: String, to targetCode: String) async -> LanguageAvailability.Status {
        let availability = LanguageAvailability()
        let sourceLanguage = Locale.Language(identifier: sourceCode)
        let targetLanguage = Locale.Language(identifier: targetCode)
        
        do {
            let status = try await availability.status(from: sourceLanguage, to: targetLanguage)
            let key = "\(sourceCode)-\(targetCode)"
            languageStatuses[key] = status
            return status
        } catch {
            NSLog("Language availability check error: \(error)")
            return .unsupported
        }
    }
    
    func checkAllLanguagePairs() async {
        isCheckingLanguages = true
        defer { isCheckingLanguages = false }
        
        let commonPairs = [
            ("en", "zh"),
            ("zh", "en"),
            ("ja", "zh"),
            ("zh", "ja"),
            ("ko", "zh"),
            ("zh", "ko"),
            ("en", "ja"),
            ("ja", "en")
        ]
        
        for (source, target) in commonPairs {
            _ = await checkLanguageAvailability(from: source, to: target)
        }
    }
    
    func getSupportedLanguages() async -> [Locale.Language] {
        let availability = LanguageAvailability()
        do {
            let languages = try await availability.supportedLanguages
            return languages
        } catch {
            NSLog("Get supported languages error: \(error)")
            return []
        }
    }
}

private final class UncheckedSendable<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

@available(macOS 15.0, *)
private struct TranslationBridgeView: View {
    let text: String
    let configuration: TranslationSession.Configuration
    let onComplete: (Result<String, Error>) -> Void
    
    @State private var completed = false
    
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .translationTask(configuration) { session in
                guard !completed else { return }
                completed = true
                do {
                    NSLog("Apple Translation: translating '\(text.prefix(30))...'")
                    let response = try await session.translate(text)
                    NSLog("Apple Translation: result '\(response.targetText.prefix(30))...'")
                    onComplete(.success(response.targetText))
                } catch {
                    NSLog("Apple Translation error: \(error.localizedDescription)")
                    onComplete(.failure(error))
                }
            }
            .onDisappear {
                guard !completed else { return }
                completed = true
                onComplete(.failure(TranslationError.apiError("翻译会话已取消")))
            }
    }
}

@available(macOS 15.0, *)
struct AppleTranslationProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .apple
    
    nonisolated func translate(request: TranslationRequest) async throws -> TranslationResponse {
        let targetLangCode = request.targetLanguage.rawValue
        
        var sourceLanguage: Locale.Language?
        
        if request.sourceLanguage == .auto {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(request.text)
            if let language = recognizer.dominantLanguage {
                sourceLanguage = Locale.Language(identifier: language.rawValue)
                NSLog("Apple Translation: detected language \(language.rawValue)")
            } else {
                sourceLanguage = Locale.Language(identifier: "en")
                NSLog("Apple Translation: using default language en")
            }
        } else {
            sourceLanguage = Locale.Language(identifier: request.sourceLanguage.rawValue)
        }
        
        let targetLanguage = Locale.Language(identifier: targetLangCode)
        
        NSLog("Apple Translation: starting translation for text: \(request.text.prefix(50))...")
        
        do {
            let translatedText = try await AppleTranslationManager.shared.translate(
                text: request.text,
                from: sourceLanguage,
                to: targetLanguage
            )
            
            NSLog("Apple Translation: success, result: \(translatedText.prefix(50))...")
            
            let responseStatus = TranslationResponse.ResponseStatus(code: 200, message: nil)
            let responseData = TranslationResponse.ResponseData(translatedText: translatedText, match: nil)
            
            return TranslationResponse(
                responseStatus: responseStatus,
                responseData: responseData,
                matches: nil
            )
        } catch {
            NSLog("Apple Translation error: \(error.localizedDescription)")
            throw TranslationError.apiError("Apple翻译失败: \(error.localizedDescription)")
        }
    }
}
