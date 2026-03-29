import SwiftUI
import SwiftData

@main
struct KamicutApp: App {
    @State private var storageManager = CutStorageManager.shared

    var body: some Scene {
        WindowGroup {
            ProjectsListView()
                .onAppear {
                    DataMigrator.migrateIfNeeded()
                    storageManager.loadAllCuts()
                }
        }
        // Keep SwiftData container available for migration reads only
        .modelContainer(for: LegacySavedCut.self)
    }
}
