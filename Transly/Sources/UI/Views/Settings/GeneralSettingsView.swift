import SwiftUI

struct SettingsWindowView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
                .tag(0)
            
            TranslationServicesSettingsView()
                .tabItem {
                    Label("翻译服务", systemImage: "globe")
                }
                .tag(1)
        }
        .frame(minWidth: 450, minHeight: 400)
    }
}

struct GeneralSettingsView: View {
    @Bindable var config = AppConfigService.shared
    
    var body: some View {
        Form {
            Section("快捷键") {
                HStack {
                    Text("输入翻译")
                    Spacer()
                    Text("⌥A")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("划词翻译")
                    Spacer()
                    Text("⌥D")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("OCR翻译")
                    Spacer()
                    Text("⌥S")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("剪贴翻译")
                    Spacer()
                    Text("⌥V")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Section("翻译设置") {
                Picker("默认源语言", selection: $config.sourceLanguage) {
                    ForEach(Language.sourceLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                
                Picker("默认目标语言", selection: $config.targetLanguage) {
                    ForEach(Language.targetLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                
                Toggle("自动复制翻译结果", isOn: $config.autoCopy)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
