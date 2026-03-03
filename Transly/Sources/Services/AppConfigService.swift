import Foundation

@Observable
final class AppConfigService {
    static let shared = AppConfigService()
    
    private let defaults = UserDefaults.standard
    
    private init() {
        sourceLanguage = Self.loadSourceLanguage()
        targetLanguage = Self.loadTargetLanguage()
        autoCopy = Self.loadAutoCopy()
        enabledTranslationServices = Self.loadEnabledTranslationServices()
        deepSeekAPIKey = Self.loadDeepSeekAPIKey()
        openAIAPIKey = Self.loadOpenAIAPIKey()
        openAIEndpoint = Self.loadOpenAIEndpoint()
        openAIModel = Self.loadOpenAIModel()
        ollamaEndpoint = Self.loadOllamaEndpoint()
        ollamaModel = Self.loadOllamaModel()
    }
    
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
        didSet { defaults.set(sourceLanguage.rawValue, forKey: Keys.sourceLanguage) }
    }
    
    var targetLanguage: Language {
        didSet { defaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage) }
    }
    
    var autoCopy: Bool {
        didSet { defaults.set(autoCopy, forKey: Keys.autoCopy) }
    }
    
    var enabledTranslationServices: Set<TranslationServiceType> {
        didSet {
            let array = Array(enabledTranslationServices.map { $0.rawValue })
            defaults.set(array, forKey: Keys.enabledTranslationServices)
        }
    }
    
    var deepSeekAPIKey: String {
        didSet { defaults.set(deepSeekAPIKey, forKey: Keys.deepSeekAPIKey) }
    }
    
    var openAIAPIKey: String {
        didSet { defaults.set(openAIAPIKey, forKey: Keys.openAIAPIKey) }
    }
    
    var openAIEndpoint: String {
        didSet { defaults.set(openAIEndpoint, forKey: Keys.openAIEndpoint) }
    }
    
    var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: Keys.openAIModel) }
    }
    
    var ollamaEndpoint: String {
        didSet { defaults.set(ollamaEndpoint, forKey: Keys.ollamaEndpoint) }
    }
    
    var ollamaModel: String {
        didSet { defaults.set(ollamaModel, forKey: Keys.ollamaModel) }
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
    
    private static func loadSourceLanguage() -> Language {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.sourceLanguage),
           let language = Language(rawValue: rawValue) {
            return language
        }
        return .auto
    }
    
    private static func loadTargetLanguage() -> Language {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.targetLanguage),
           let language = Language(rawValue: rawValue) {
            return language
        }
        return .chinese
    }
    
    private static func loadAutoCopy() -> Bool {
        UserDefaults.standard.object(forKey: Keys.autoCopy) as? Bool ?? true
    }
    
    private static func loadEnabledTranslationServices() -> Set<TranslationServiceType> {
        if let saved = UserDefaults.standard.array(forKey: Keys.enabledTranslationServices) as? [String] {
            let services = saved.compactMap { TranslationServiceType(rawValue: $0) }
            return services.isEmpty ? Set(TranslationServiceType.availableServices.filter { $0.isEnabledByDefault }) : Set(services)
        }
        return Set(TranslationServiceType.availableServices.filter { $0.isEnabledByDefault })
    }
    
    private static func loadDeepSeekAPIKey() -> String {
        UserDefaults.standard.string(forKey: Keys.deepSeekAPIKey) ?? ""
    }
    
    private static func loadOpenAIAPIKey() -> String {
        UserDefaults.standard.string(forKey: Keys.openAIAPIKey) ?? ""
    }
    
    private static func loadOpenAIEndpoint() -> String {
        UserDefaults.standard.string(forKey: Keys.openAIEndpoint) ?? TranslationServiceType.openai.defaultEndpoint
    }
    
    private static func loadOpenAIModel() -> String {
        UserDefaults.standard.string(forKey: Keys.openAIModel) ?? TranslationServiceType.openai.defaultModel
    }
    
    private static func loadOllamaEndpoint() -> String {
        UserDefaults.standard.string(forKey: Keys.ollamaEndpoint) ?? TranslationServiceType.ollama.defaultEndpoint
    }
    
    private static func loadOllamaModel() -> String {
        UserDefaults.standard.string(forKey: Keys.ollamaModel) ?? TranslationServiceType.ollama.defaultModel
    }
}
