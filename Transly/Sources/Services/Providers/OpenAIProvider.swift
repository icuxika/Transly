import Foundation

struct OpenAIProvider: TranslationProvider {
    let serviceType: TranslationServiceType = .openai
    
    func translate(request: TranslationRequest) async throws -> TranslationResponse {
        guard let apiKey = getAPIKey() else {
            throw TranslationError.apiError("OpenAI API Key 未配置")
        }
        
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
    
    private func getAPIKey() -> String? {
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return apiKey
        }
        let key = AppConfigService.shared.openAIAPIKey
        return key.isEmpty ? nil : key
    }
    
    private func getEndpoint() -> String {
        let endpoint = AppConfigService.shared.openAIEndpoint
        return endpoint.isEmpty ? TranslationServiceType.openai.defaultEndpoint : endpoint
    }
    
    private func getModel() -> String {
        let model = AppConfigService.shared.openAIModel
        return model.isEmpty ? TranslationServiceType.openai.defaultModel : model
    }
}
