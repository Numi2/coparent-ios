import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView {
            Text("Discover")
                .tabItem {
                    Label("Discover", systemImage: "flame.fill")
                }
            
            Text("Messages")
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
