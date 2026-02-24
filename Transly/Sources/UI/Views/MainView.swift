import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TranslationView()
                .tabItem {
                    Label("翻译", systemImage: "character.bubble")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    MainView()
}
