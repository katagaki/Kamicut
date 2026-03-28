import Foundation

// MARK: - Editor Document

/// Top-level model representing the full state of a circle cut document.
struct EditorDocument: Codable {
    var id: UUID = UUID()
    var circleName: String = ""
    var template: CircleCutTemplate = .templateA
    var bleedOption: BleedOption = .none
    var backgroundColor: CodableColor?
    var backgroundImage: ImageElement?
    var layers: [CanvasLayer] = []
    var spaceNumber: SpaceNumberInfo = SpaceNumberInfo()
    var exportSettings: ExportSettings = ExportSettings()
}
