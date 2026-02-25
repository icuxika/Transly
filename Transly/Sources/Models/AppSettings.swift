import Foundation

struct AppSettings: Codable, Equatable {
    var sourceLanguage: Language
    var targetLanguage: Language
    var autoCopy: Bool
    
    static let `default` = AppSettings(
        sourceLanguage: .auto,
        targetLanguage: .chinese,
        autoCopy: true
    )
}
