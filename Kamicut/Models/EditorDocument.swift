import Foundation

// MARK: - Editor Document

/// Top-level model representing the full state of a circle cut document.
nonisolated struct EditorDocument: Codable, Sendable {
    var id: UUID = UUID()
    var circleName: String = ""
    var template: CircleCutTemplate = .templateA
    var bleedOption: BleedOption = .none
    var backgroundColor: CodableColor?
    var backgroundImage: ImageElement?
    var layers: [CanvasLayer] = []
    var spaceNumber: SpaceNumberInfo = SpaceNumberInfo()
    var exportSettings: ExportSettings = ExportSettings()

    init() {}

    private enum CodingKeys: String, CodingKey {
        case id, circleName, template, bleedOption, backgroundColor
        case backgroundImage, layers, spaceNumber, exportSettings
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        circleName = try container.decode(String.self, forKey: .circleName)
        template = try container.decode(CircleCutTemplate.self, forKey: .template)
        bleedOption = try container.decode(BleedOption.self, forKey: .bleedOption)
        backgroundColor = try container.decodeIfPresent(CodableColor.self, forKey: .backgroundColor)
        backgroundImage = try container.decodeIfPresent(ImageElement.self, forKey: .backgroundImage)
        layers = try container.decode([CanvasLayer].self, forKey: .layers)
        spaceNumber = try container.decode(SpaceNumberInfo.self, forKey: .spaceNumber)
        exportSettings = try container.decode(ExportSettings.self, forKey: .exportSettings)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(circleName, forKey: .circleName)
        try container.encode(template, forKey: .template)
        try container.encode(bleedOption, forKey: .bleedOption)
        try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
        try container.encodeIfPresent(backgroundImage, forKey: .backgroundImage)
        try container.encode(layers, forKey: .layers)
        try container.encode(spaceNumber, forKey: .spaceNumber)
        try container.encode(exportSettings, forKey: .exportSettings)
    }
}
