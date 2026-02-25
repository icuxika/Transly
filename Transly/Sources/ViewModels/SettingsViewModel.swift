import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    private let config = AppConfigService.shared
    
    var sourceLanguage: Language {
        get { config.sourceLanguage }
        set { config.sourceLanguage = newValue }
    }
    
    var targetLanguage: Language {
        get { config.targetLanguage }
        set { config.targetLanguage = newValue }
    }
    
    var autoCopy: Bool {
        get { config.autoCopy }
        set { config.autoCopy = newValue }
    }
    
    var deepSeekAPIKey: String {
        get { config.deepSeekAPIKey }
        set { config.deepSeekAPIKey = newValue }
    }
    
    var enabledTranslationServices: Set<TranslationServiceType> {
        get { config.enabledTranslationServices }
        set { config.enabledTranslationServices = newValue }
    }
    
    func isServiceEnabled(_ service: TranslationServiceType) -> Bool {
        config.isServiceEnabled(service)
    }
    
    func toggleService(_ service: TranslationServiceType) {
        config.toggleService(service)
    }
}
