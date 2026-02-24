import SwiftUI

struct LanguagePicker: View {
    let title: String
    @Binding var selectedLanguage: Language
    let languages: [Language]
    
    var body: some View {
        Picker(title, selection: $selectedLanguage) {
            ForEach(languages) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: 100)
    }
}

#Preview {
    HStack {
        LanguagePicker(
            title: "源语言",
            selectedLanguage: .constant(.auto),
            languages: Language.sourceLanguages
        )
        LanguagePicker(
            title: "目标语言",
            selectedLanguage: .constant(.chinese),
            languages: Language.targetLanguages
        )
    }
    .padding()
}
