import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Nhà", systemImage: "house") }
            LibraryView()
                .tabItem { Label("Thư viện", systemImage: "books.vertical") }
            SettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape") }
        }
    }
}
