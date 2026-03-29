import Foundation
import SwiftData

// MARK: - Legacy SwiftData Model (kept for migration only)

@Model
final class LegacySavedCut {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var documentData: Data
    var thumbnailData: Data?

    init(name: String, document: EditorDocument) throws {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.documentData = try JSONEncoder().encode(document)
    }

    func loadDocument() throws -> EditorDocument {
        try JSONDecoder().decode(EditorDocument.self, from: documentData)
    }
}
