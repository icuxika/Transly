import Foundation
import NaturalLanguage

enum TranslationError: Error, LocalizedError {
    case emptyText
    case sameLanguage
    case apiError(String)
    case networkError(Error)
    case serviceUnavailable
    case languageNotSupported
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "请输入要翻译的文本"
        case .sameLanguage:
            return "源语言和目标语言不能相同"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .serviceUnavailable:
            return "翻译服务不可用"
        case .languageNotSupported:
            return "该语言不受支持"
        }
    }
}

protocol TranslationProvider {
    var serviceType: TranslationServiceType { get }
    func translate(request: TranslationRequest) async throws -> TranslationResponse
}

struct MultiTranslationResult {
    let sourceText: String
    let results: [TranslationServiceResult]
}

struct TranslationServiceResult {
    let serviceType: TranslationServiceType
    let translatedText: String
    let error: Error?
}

actor TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        guard !request.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.emptyText
        }
        
        guard request.sourceLanguage != request.targetLanguage else {
            throw TranslationError.sameLanguage
        }
        
        switch request.serviceType {
        case .google:
            return try await GoogleTranslateProvider().translate(request: request)
        case .apple:
            if #available(macOS 15.0, *) {
                return try await AppleTranslationProvider().translate(request: request)
            } else {
                throw TranslationError.serviceUnavailable
            }
        case .deepseek:
            return try await DeepSeekProvider().translate(request: request)
        case .openai:
            return try await OpenAIProvider().translate(request: request)
        case .ollama:
            return try await OllamaProvider().translate(request: request)
        }
    }
    
    func translate(text: String, from source: Language, to target: Language, service: TranslationServiceType = .google) async throws -> String {
        let request = TranslationRequest(text: text, sourceLanguage: source, targetLanguage: target, serviceType: service)
        let response = try await translate(request: request)
        return response.translatedText
    }
    
    func translateWithMultipleServices(text: String, from source: Language, to target: Language, services: [TranslationServiceType]) async -> MultiTranslationResult {
        var results: [TranslationServiceResult] = []
        
        await withTaskGroup(of: TranslationServiceResult.self) { group in
            for service in services {
                group.addTask {
                    do {
                        let request = TranslationRequest(text: text, sourceLanguage: source, targetLanguage: target, serviceType: service)
                        let response = try await self.translate(request: request)
                        return TranslationServiceResult(serviceType: service, translatedText: response.translatedText, error: nil)
                    } catch {
                        return TranslationServiceResult(serviceType: service, translatedText: "", error: error)
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        let sortedResults = services.compactMap { service in
            results.first { $0.serviceType == service }
        }
        
        return MultiTranslationResult(sourceText: text, results: sortedResults.isEmpty ? results : sortedResults)
    }
    
    func translateWithProgress(text: String, from source: Language, to target: Language, services: [TranslationServiceType], onResult: @escaping (TranslationServiceResult) -> Void) async -> MultiTranslationResult {
        var results: [TranslationServiceResult] = []
        
        await withTaskGroup(of: TranslationServiceResult.self) { group in
            for service in services {
                group.addTask {
                    do {
                        let request = TranslationRequest(text: text, sourceLanguage: source, targetLanguage: target, serviceType: service)
                        let response = try await self.translate(request: request)
                        let result = TranslationServiceResult(serviceType: service, translatedText: response.translatedText, error: nil)
                        onResult(result)
                        return result
                    } catch {
                        let result = TranslationServiceResult(serviceType: service, translatedText: "", error: error)
                        onResult(result)
                        return result
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        let sortedResults = services.compactMap { service in
            results.first { $0.serviceType == service }
        }
        
        return MultiTranslationResult(sourceText: text, results: sortedResults.isEmpty ? results : sortedResults)
    }
}
