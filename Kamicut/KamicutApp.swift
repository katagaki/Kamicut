import SwiftUI
import SwiftData

@main
struct KamicutApp: App {

    init() {
        DataMigrator.migrateIfNeeded()
    }

    var body: some Scene {
        DocumentGroup(
            newDocument: CutDocument.init,
            editor: { file in
                DocumentEditorView(document: file.document)
            }
        )
        // Keep SwiftData container available for migration reads only
        .modelContainer(for: LegacySavedCut.self)
    }
}
