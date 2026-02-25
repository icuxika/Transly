import Foundation

struct OllamaProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .ollama
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        let endpoint = getEndpoint()
        let model = getModel()
        
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
    
    private func getEndpoint() -> String {
        let endpoint = AppConfigService.shared.ollamaEndpoint
        return endpoint.isEmpty ? TranslationServiceType.ollama.defaultEndpoint : endpoint
    }
    
    private func getModel() -> String {
        let model = AppConfigService.shared.ollamaModel
        return model.isEmpty ? TranslationServiceType.ollama.defaultModel : model
    }
}
