import SwiftUI
import SwiftData

@main
struct KamicutApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedCut.self)
    }
}
