import Foundation

enum TranslationServiceType: String, CaseIterable, Identifiable, Codable {
    case google = "google"
    case apple = "apple"
    case deepseek = "deepseek"
    case openai = "openai"
    case ollama = "ollama"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .google: return "Google 翻译"
        case .apple: return "Apple 翻译"
        case .deepseek: return "DeepSeek"
        case .openai: return "OpenAI"
        case .ollama: return "Ollama"
        }
    }
    
    var description: String {
        switch self {
        case .google: return "免费接口，无需API Key"
        case .apple: return "系统原生翻译，离线可用"
        case .deepseek: return "需要配置API Key"
        case .openai: return "兼容OpenAI接口，需要配置API Key"
        case .ollama: return "本地模型，需要运行Ollama服务"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .google, .deepseek, .openai, .ollama:
            return true
        case .apple:
            if #available(macOS 15.0, *) {
                return true
            }
            return false
        }
    }
    
    var isEnabledByDefault: Bool {
        switch self {
        case .google, .apple, .deepseek:
            return true
        case .openai, .ollama:
            return false
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .deepseek, .openai:
            return true
        default:
            return false
        }
    }
    
    var requiresEndpoint: Bool {
        switch self {
        case .openai, .ollama:
            return true
        default:
            return false
        }
    }
    
    var requiresModel: Bool {
        switch self {
        case .openai, .ollama:
            return true
        default:
            return false
        }
    }
    
    var defaultEndpoint: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1"
        case .ollama:
            return "http://localhost:11434"
        default:
            return ""
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openai:
            return "gpt-4o-mini"
        case .ollama:
            return "llama3.2"
        default:
            return ""
        }
    }
    
    static var availableServices: [TranslationServiceType] {
        allCases.filter { $0.isAvailable }
    }
}
