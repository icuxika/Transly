import Foundation

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
        case .myMemory:
            return try await MyMemoryProvider().translate(request: request)
        case .google:
            return try await GoogleTranslateProvider().translate(request: request)
        case .apple:
            return try await AppleTranslationProvider().translate(request: request)
        }
    }
    
    func translate(text: String, from source: Language, to target: Language, service: TranslationServiceType = .google) async throws -> String {
        let request = TranslationRequest(text: text, sourceLanguage: source, targetLanguage: target, serviceType: service)
        let response = try await translate(request: request)
        return response.translatedText
    }
}

struct MyMemoryProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .myMemory
    private let baseURL = "https://api.mymemory.translated.net/get"
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        let sourceLang = request.sourceLanguage == .auto ? "autodetect" : request.sourceLanguage.rawValue
        let langPair = "\(sourceLang)|\(request.targetLanguage.rawValue)"
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: request.text),
            URLQueryItem(name: "langpair", value: langPair)
        ]
        
        guard let url = components?.url else {
            throw TranslationError.apiError("无效的URL")
        }
        
        do {
            let response: TranslationResponse = try await NetworkService.shared.get(url: url)
            
            if !response.isSuccess {
                throw TranslationError.apiError(response.errorMessage)
            }
            
            return response
        } catch let error as NetworkError {
            throw TranslationError.networkError(error)
        }
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

struct AppleTranslationProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .apple
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        throw TranslationError.serviceUnavailable
    }
}
