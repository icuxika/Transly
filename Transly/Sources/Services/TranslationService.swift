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

struct DeepSeekProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .deepseek
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        guard let apiKey = getDeepSeekAPIKey() else {
            throw TranslationError.apiError("DeepSeek API Key 未配置")
        }
        
        let sourceLang = request.sourceLanguage == .auto ? "auto" : request.sourceLanguage.rawValue
        let targetLang = request.targetLanguage.rawValue
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a translation assistant. Translate the following text from \(sourceLang) to \(targetLang). Return only the translated text without any additional information."
                ],
                [
                    "role": "user",
                    "content": request.text
                ]
            ],
            "temperature": 0.1
        ]
        
        guard let url = URL(string: baseURL) else {
            throw TranslationError.apiError("无效的URL")
        }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TranslationError.apiError("DeepSeek API 请求失败")
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let translatedText = message["content"] as? String else {
                throw TranslationError.apiError("DeepSeek API 响应解析失败")
            }
            
            let responseStatus = TranslationResponse.ResponseStatus(code: 200, message: nil)
            let responseData = TranslationResponse.ResponseData(translatedText: translatedText, match: nil)
            
            return TranslationResponse(
                responseStatus: responseStatus,
                responseData: responseData,
                matches: nil
            )
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.apiError(error.localizedDescription)
        }
    }
    
    private func getDeepSeekAPIKey() -> String? {
        if let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] {
            return apiKey
        }
        let key = AppConfigService.shared.deepSeekAPIKey
        return key.isEmpty ? nil : key
    }
}

struct GoogleTranslateProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .google
    private let baseURL = "https://translate.googleapis.com/translate_a/single"
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        let sourceLang = request.sourceLanguage == .auto ? "auto" : request.sourceLanguage.rawValue
        let targetLang = request.targetLanguage.rawValue
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLang),
            URLQueryItem(name: "tl", value: targetLang),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: request.text)
        ]
        
        guard let url = components?.url else {
            throw TranslationError.apiError("无效的URL")
        }
        
        do {
            let data = try await NetworkService.shared.getRaw(url: url)
            return try parseGoogleResponse(data: data)
        } catch let error as NetworkError {
            throw TranslationError.networkError(error)
        }
    }
    
    private func parseGoogleResponse(data: Data) throws -> TranslationResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let translations = json.first as? [[Any]] else {
            throw TranslationError.apiError("解析响应失败")
        }
        
        var translatedText = ""
        for part in translations {
            if let text = part.first as? String {
                translatedText += text
            }
        }
        
        let responseStatus = TranslationResponse.ResponseStatus(code: 200, message: nil)
        let responseData = TranslationResponse.ResponseData(translatedText: translatedText, match: nil)
        
        return TranslationResponse(
            responseStatus: responseStatus,
            responseData: responseData,
            matches: nil
        )
    }
}

struct OpenAIProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .openai
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        guard let apiKey = getOpenAIAPIKey() else {
            throw TranslationError.apiError("OpenAI API Key 未配置")
        }
        
        let endpoint = getOpenAIEndpoint()
        let model = getOpenAIModel()
        
        let sourceLang = request.sourceLanguage == .auto ? "auto" : request.sourceLanguage.rawValue
        let targetLang = request.targetLanguage.rawValue
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a translation assistant. Translate the following text from \(sourceLang) to \(targetLang). Return only the translated text without any additional information."
                ],
                [
                    "role": "user",
                    "content": request.text
                ]
            ],
            "temperature": 0.1
        ]
        
        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            throw TranslationError.apiError("无效的URL")
        }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TranslationError.apiError("OpenAI API 请求失败")
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let translatedText = message["content"] as? String else {
                throw TranslationError.apiError("OpenAI API 响应解析失败")
            }
            
            let responseStatus = TranslationResponse.ResponseStatus(code: 200, message: nil)
            let responseData = TranslationResponse.ResponseData(translatedText: translatedText, match: nil)
            
            return TranslationResponse(
                responseStatus: responseStatus,
                responseData: responseData,
                matches: nil
            )
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.apiError(error.localizedDescription)
        }
    }
    
    private func getOpenAIAPIKey() -> String? {
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return apiKey
        }
        let key = AppConfigService.shared.openAIAPIKey
        return key.isEmpty ? nil : key
    }
    
    private func getOpenAIEndpoint() -> String {
        let endpoint = AppConfigService.shared.openAIEndpoint
        return endpoint.isEmpty ? TranslationServiceType.openai.defaultEndpoint : endpoint
    }
    
    private func getOpenAIModel() -> String {
        let model = AppConfigService.shared.openAIModel
        return model.isEmpty ? TranslationServiceType.openai.defaultModel : model
    }
}

struct OllamaProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .ollama
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        let endpoint = getOllamaEndpoint()
        let model = getOllamaModel()
        
        let sourceLang = request.sourceLanguage == .auto ? "auto" : request.sourceLanguage.rawValue
        let targetLang = request.targetLanguage.rawValue
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a translation assistant. Translate the following text from \(sourceLang) to \(targetLang). Return only the translated text without any additional information."
                ],
                [
                    "role": "user",
                    "content": request.text
                ]
            ],
            "stream": false
        ]
        
        guard let url = URL(string: "\(endpoint)/api/chat") else {
            throw TranslationError.apiError("无效的URL")
        }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TranslationError.apiError("Ollama API 请求失败")
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let message = json?["message"] as? [String: Any],
                  let translatedText = message["content"] as? String else {
                throw TranslationError.apiError("Ollama API 响应解析失败")
            }
            
            let responseStatus = TranslationResponse.ResponseStatus(code: 200, message: nil)
            let responseData = TranslationResponse.ResponseData(translatedText: translatedText, match: nil)
            
            return TranslationResponse(
                responseStatus: responseStatus,
                responseData: responseData,
                matches: nil
            )
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.apiError(error.localizedDescription)
        }
    }
    
    private func getOllamaEndpoint() -> String {
        let endpoint = AppConfigService.shared.ollamaEndpoint
        return endpoint.isEmpty ? TranslationServiceType.ollama.defaultEndpoint : endpoint
    }
    
    private func getOllamaModel() -> String {
        let model = AppConfigService.shared.ollamaModel
        return model.isEmpty ? TranslationServiceType.ollama.defaultModel : model
    }
}


