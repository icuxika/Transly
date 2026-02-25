import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InputTranslationView()
                .tabItem {
                    Label("翻译", systemImage: "character.bubble")
                }
                .tag(0)
            
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "camera.viewfinder")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock")
                }
                .tag(2)
        }
        .frame(minWidth: 420, minHeight: 500)
    }
}

#Preview {
    MainView()
}
