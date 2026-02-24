import Foundation

enum Language: String, CaseIterable, Identifiable, Codable {
    case auto = "auto"
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case russian = "ru"
    case portuguese = "pt"
    case italian = "it"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "自动检测"
        case .chinese: return "中文"
        case .english: return "英语"
        case .japanese: return "日语"
        case .korean: return "韩语"
        case .french: return "法语"
        case .german: return "德语"
        case .spanish: return "西班牙语"
        case .russian: return "俄语"
        case .portuguese: return "葡萄牙语"
        case .italian: return "意大利语"
        }
    }
    
    static var sourceLanguages: [Language] {
        [.auto] + allCases.filter { $0 != .auto }
    }
    
    static var targetLanguages: [Language] {
        allCases.filter { $0 != .auto }
    }
}
