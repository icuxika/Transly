import Foundation

struct TranslationRequest {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
}

struct TranslationResponse: Codable {
    let responseStatus: ResponseStatus
    let responseData: ResponseData?
    let matches: [Match]?
    
    struct ResponseStatus: Codable {
        let code: Int
        let message: String?
    }
    
    struct ResponseData: Codable {
        let translatedText: String
        let match: Double?
    }
    
    struct Match: Codable {
        let id: String?
        let segment: String
        let translation: String
        let quality: Double?
    }
    
    var translatedText: String {
        responseData?.translatedText ?? matches?.first?.translation ?? ""
    }
    
    var isSuccess: Bool {
        responseStatus.code == 200
    }
    
    var errorMessage: String {
        responseStatus.message ?? "翻译失败"
    }
}
