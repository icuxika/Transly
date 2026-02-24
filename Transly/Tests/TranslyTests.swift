import Testing
@testable import Transly

struct TranslyTests {
    
    @Test func languageDisplayNames() async throws {
        #expect(Language.auto.displayName == "自动检测")
        #expect(Language.chinese.displayName == "中文")
        #expect(Language.english.displayName == "英语")
        #expect(Language.japanese.displayName == "日语")
    }
    
    @Test func languageSourceTargetSeparation() async throws {
        let sourceLanguages = Language.sourceLanguages
        let targetLanguages = Language.targetLanguages
        
        #expect(sourceLanguages.contains(.auto))
        #expect(!targetLanguages.contains(.auto))
    }
    
    @Test func translationHistoryInit() async throws {
        let history = TranslationHistory(
            sourceText: "Hello",
            translatedText: "你好",
            sourceLanguage: .english,
            targetLanguage: .chinese
        )
        
        #expect(history.sourceText == "Hello")
        #expect(history.translatedText == "你好")
        #expect(history.sourceLanguage == .english)
        #expect(history.targetLanguage == .chinese)
    }
    
    @Test func appSettingsDefault() async throws {
        let settings = AppSettings.default
        
        #expect(settings.sourceLanguage == .auto)
        #expect(settings.targetLanguage == .chinese)
        #expect(settings.autoCopy == true)
        #expect(settings.showInMenuBar == true)
        #expect(settings.launchAtLogin == false)
    }
    
}
