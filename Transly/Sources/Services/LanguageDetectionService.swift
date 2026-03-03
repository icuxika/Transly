import Foundation
import NaturalLanguage

enum LanguageDetectionService {
    static func detectLanguage(from text: String) -> Language {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .auto
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return .auto
        }
        
        return mapNLLanguageToLanguage(language)
    }
    
    static func detectAndSuggestTarget(from text: String, defaultSource: Language = .english, defaultTarget: Language = .chinese) -> (source: Language, target: Language) {
        let detectedSource = detectLanguage(from: text)
        
        if detectedSource == .auto {
            return (.auto, defaultTarget)
        }
        
        var target = detectedSource.smartTargetLanguage(defaultSource: defaultSource, defaultTarget: defaultTarget)
        
        if target == detectedSource {
            if detectedSource == defaultTarget {
                target = defaultSource == defaultTarget ? .english : defaultSource
            } else {
                target = defaultTarget == detectedSource ? .chinese : defaultTarget
            }
        }
        
        return (detectedSource, target)
    }
    
    private static func mapNLLanguageToLanguage(_ nlLanguage: NLLanguage) -> Language {
        switch nlLanguage {
        case .simplifiedChinese, .traditionalChinese:
            return .chinese
        case .english:
            return .english
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        case .french:
            return .french
        case .german:
            return .german
        case .spanish:
            return .spanish
        case .russian:
            return .russian
        case .portuguese:
            return .portuguese
        case .italian:
            return .italian
        default:
            return .auto
        }
    }
}
