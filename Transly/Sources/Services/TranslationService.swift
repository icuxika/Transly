import Foundation

enum TranslationError: Error, LocalizedError {
    case emptyText
    case sameLanguage
    case apiError(String)
    case networkError(Error)
    
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
        }
    }
}

protocol TranslationProvider {
    func translate(request: TranslationRequest) async throws -> TranslationResponse
}

actor TranslationService: TranslationProvider {
    static let shared = TranslationService()
    
    private let baseURL = "https://api.mymemory.translated.net/get"
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        guard !request.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.emptyText
        }
        
        guard request.sourceLanguage != request.targetLanguage else {
            throw TranslationError.sameLanguage
        }
        
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
            let response: TranslationResponse = try await networkService.get(url: url)
            
            if !response.isSuccess {
                throw TranslationError.apiError(response.errorMessage)
            }
            
            return response
        } catch let error as NetworkError {
            throw TranslationError.networkError(error)
        }
    }
    
    func translate(text: String, from source: Language, to target: Language) async throws -> String {
        let request = TranslationRequest(text: text, sourceLanguage: source, targetLanguage: target)
        let response = try await translate(request: request)
        return response.translatedText
    }
}
