import Foundation

// MARK: - Editor Document

/// Top-level model representing the full state of a circle cut document.
struct EditorDocument: Codable {
    var id: UUID = UUID()
    var template: CircleCutTemplate = .templateA
    var bleedOption: BleedOption = .none
    var backgroundImage: ImageElement?
    var layers: [CanvasLayer] = []
    var spaceNumber: SpaceNumberInfo = SpaceNumberInfo()
    var exportSettings: ExportSettings = ExportSettings()
}
