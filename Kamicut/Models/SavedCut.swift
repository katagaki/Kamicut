import Foundation
import SwiftData

@Model
final class SavedCut {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    /// The full EditorDocument, JSON-encoded.
    var documentData: Data

    /// Small JPEG thumbnail for list display.
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

    func updateDocument(_ document: EditorDocument) throws {
        self.documentData = try JSONEncoder().encode(document)
        self.updatedAt = Date()
    }
}
