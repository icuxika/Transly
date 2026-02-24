import Foundation

enum TranslationServiceType: String, CaseIterable, Identifiable, Codable {
    case myMemory = "mymemory"
    case google = "google"
    case apple = "apple"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .myMemory: return "MyMemory"
        case .google: return "Google 翻译"
        case .apple: return "Apple 翻译"
        }
    }
    
    var description: String {
        switch self {
        case .myMemory: return "免费API，每天10000字符限额"
        case .google: return "免费接口，无需API Key"
        case .apple: return "系统原生翻译，离线可用"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .myMemory, .google:
            return true
        case .apple:
            if #available(macOS 12.0, *) {
                return true
            }
            return false
        }
    }
    
    static var availableServices: [TranslationServiceType] {
        allCases.filter { $0.isAvailable }
    }
}
