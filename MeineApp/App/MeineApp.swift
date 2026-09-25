import SwiftUI

@main
struct MeineApp: App {
    @State private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .tint(Palette.accent)
        }
    }
}
