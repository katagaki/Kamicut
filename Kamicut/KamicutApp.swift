import SwiftUI
import SwiftData

@main
struct KamicutApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectsListView()
        }
        .modelContainer(for: SavedCut.self)
    }
}
