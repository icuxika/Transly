import AVFoundation
import Foundation

@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, language: Language) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.voiceLanguageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

extension Language {
    var voiceLanguageCode: String {
        switch self {
        case .auto:
            return "zh-CN"
        case .chinese:
            return "zh-CN"
        case .english:
            return "en-US"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .spanish:
            return "es-ES"
        case .russian:
            return "ru-RU"
        case .portuguese:
            return "pt-BR"
        case .italian:
            return "it-IT"
        }
    }
}
