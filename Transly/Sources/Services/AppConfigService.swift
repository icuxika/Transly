import Foundation

@Observable
final class AppConfigService {
    static let shared = AppConfigService()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    private enum Keys {
        static let hasCompletedSetup = "HasCompletedSetup"
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let autoCopy = "autoCopy"
        static let enabledTranslationServices = "EnabledTranslationServices"
        static let deepSeekAPIKey = "DeepSeekAPIKey"
        static let openAIAPIKey = "OpenAIAPIKey"
        static let openAIEndpoint = "OpenAIEndpoint"
        static let openAIModel = "OpenAIModel"
        static let ollamaEndpoint = "OllamaEndpoint"
        static let ollamaModel = "OllamaModel"
    }
    
    var hasCompletedSetup: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedSetup) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedSetup) }
    }
    
    var sourceLanguage: Language {
        get {
            if let rawValue = defaults.string(forKey: Keys.sourceLanguage),
               let language = Language(rawValue: rawValue) {
                return language
            }
            return .auto
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.sourceLanguage) }
    }
    
    var targetLanguage: Language {
        get {
            if let rawValue = defaults.string(forKey: Keys.targetLanguage),
               let language = Language(rawValue: rawValue) {
                return language
            }
            return .chinese
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.targetLanguage) }
    }
    
    var autoCopy: Bool {
        get { defaults.object(forKey: Keys.autoCopy) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoCopy) }
    }
    
    var enabledTranslationServices: Set<TranslationServiceType> {
        get {
            if let saved = defaults.array(forKey: Keys.enabledTranslationServices) as? [String] {
                let services = saved.compactMap { TranslationServiceType(rawValue: $0) }
                return services.isEmpty ? Set(TranslationServiceType.availableServices.filter { $0.isEnabledByDefault }) : Set(services)
            }
            return Set(TranslationServiceType.availableServices.filter { $0.isEnabledByDefault })
        }
        set {
            let array = Array(newValue.map { $0.rawValue })
            defaults.set(array, forKey: Keys.enabledTranslationServices)
        }
    }
    
    var deepSeekAPIKey: String {
        get { defaults.string(forKey: Keys.deepSeekAPIKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.deepSeekAPIKey) }
    }
    
    var openAIAPIKey: String {
        get { defaults.string(forKey: Keys.openAIAPIKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.openAIAPIKey) }
    }
    
    var openAIEndpoint: String {
        get { defaults.string(forKey: Keys.openAIEndpoint) ?? TranslationServiceType.openai.defaultEndpoint }
        set { defaults.set(newValue, forKey: Keys.openAIEndpoint) }
    }
    
    var openAIModel: String {
        get { defaults.string(forKey: Keys.openAIModel) ?? TranslationServiceType.openai.defaultModel }
        set { defaults.set(newValue, forKey: Keys.openAIModel) }
    }
    
    var ollamaEndpoint: String {
        get { defaults.string(forKey: Keys.ollamaEndpoint) ?? TranslationServiceType.ollama.defaultEndpoint }
        set { defaults.set(newValue, forKey: Keys.ollamaEndpoint) }
    }
    
    var ollamaModel: String {
        get { defaults.string(forKey: Keys.ollamaModel) ?? TranslationServiceType.ollama.defaultModel }
        set { defaults.set(newValue, forKey: Keys.ollamaModel) }
    }
    
    func isServiceEnabled(_ service: TranslationServiceType) -> Bool {
        enabledTranslationServices.contains(service)
    }
    
    func toggleService(_ service: TranslationServiceType) {
        if enabledTranslationServices.contains(service) {
            if enabledTranslationServices.count > 1 {
                enabledTranslationServices.remove(service)
            }
        } else {
            enabledTranslationServices.insert(service)
        }
    }
    
    func getAPIKey(for service: TranslationServiceType) -> String {
        switch service {
        case .deepseek:
            return deepSeekAPIKey
        case .openai:
            return openAIAPIKey
        default:
            return ""
        }
    }
    
    func setAPIKey(_ key: String, for service: TranslationServiceType) {
        switch service {
        case .deepseek:
            deepSeekAPIKey = key
        case .openai:
            openAIAPIKey = key
        default:
            break
        }
    }
    
    func getEndpoint(for service: TranslationServiceType) -> String {
        switch service {
        case .openai:
            return openAIEndpoint
        case .ollama:
            return ollamaEndpoint
        default:
            return ""
        }
    }
    
    func setEndpoint(_ endpoint: String, for service: TranslationServiceType) {
        switch service {
        case .openai:
            openAIEndpoint = endpoint
        case .ollama:
            ollamaEndpoint = endpoint
        default:
            break
        }
    }
    
    func getModel(for service: TranslationServiceType) -> String {
        switch service {
        case .openai:
            return openAIModel
        case .ollama:
            return ollamaModel
        default:
            return ""
        }
    }
    
    func setModel(_ model: String, for service: TranslationServiceType) {
        switch service {
        case .openai:
            openAIModel = model
        case .ollama:
            ollamaModel = model
        default:
            break
        }
    }
}
