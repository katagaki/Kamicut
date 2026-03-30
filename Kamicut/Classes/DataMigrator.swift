import Foundation
import SwiftData
import UIKit

// MARK: - Data Migrator

/// One-time migration from SwiftData (LegacySavedCut) to file-based .cut packages.
/// Only runs if the current date is before April 20, 2026.
enum DataMigrator {

    private static let migrationKey = "hasCompletedSwiftDataToFileMigration"

    /// The migration cutoff date: April 20, 2026.
    private static var cutoffDate: Date {
        DateComponents(calendar: .init(identifier: .gregorian), year: 2026, month: 4, day: 20).date!
    }

    @MainActor
    static func migrateIfNeeded() {
        // Skip if already migrated
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Skip if past cutoff date
        guard Date() < cutoffDate else { return }

        do {
            let container = try ModelContainer(for: LegacySavedCut.self)
            let context = container.mainContext
            let descriptor = FetchDescriptor<LegacySavedCut>()
            let legacyCuts = try context.fetch(descriptor)

            guard !legacyCuts.isEmpty else {
                UserDefaults.standard.set(true, forKey: migrationKey)
                return
            }

            let storageManager = CutStorageManager.shared

            for legacyCut in legacyCuts {
                let document = try legacyCut.loadDocument()
                _ = try storageManager.saveDocument(
                    document,
                    name: legacyCut.name,
                    thumbnailData: legacyCut.thumbnailData,
                    createdAt: legacyCut.createdAt,
                    updatedAt: legacyCut.updatedAt
                )
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Migration failed — will retry on next launch
        }
    }
}
