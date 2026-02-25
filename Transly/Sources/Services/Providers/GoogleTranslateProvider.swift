import Foundation

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
