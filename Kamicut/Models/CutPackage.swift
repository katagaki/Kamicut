import Foundation
import UIKit

// MARK: - Meta.json

struct CutMeta: Codable {
    var id: UUID
    var name: String
    var circleName: String
    var createdAt: Date
    var updatedAt: Date
    var template: CircleCutTemplate
    var bleedOption: BleedOption
    var backgroundColor: CodableColor?
    var spaceNumber: SpaceNumberInfo
    var exportSettings: ExportSettings
}

// MARK: - Layers.json

struct LayerReference: Codable {
    var elementID: UUID
    var type: CanvasElementType
}

struct LayersManifest: Codable {
    var layers: [LayerReference]
}

// MARK: - Element JSON (stored as {UUID}.json in Elements/)

enum ElementPayload: Codable {
    case image(ImageElementFile)
    case text(TextElement)
    case shape(ShapeElement)

    private enum CodingKeys: String, CodingKey {
        case type, data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let img):
            try container.encode(CanvasElementType.image, forKey: .type)
            try container.encode(img, forKey: .data)
        case .text(let txt):
            try container.encode(CanvasElementType.text, forKey: .type)
            try container.encode(txt, forKey: .data)
        case .shape(let shp):
            try container.encode(CanvasElementType.shape, forKey: .type)
            try container.encode(shp, forKey: .data)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CanvasElementType.self, forKey: .type)
        switch type {
        case .image:
            self = .image(try container.decode(ImageElementFile.self, forKey: .data))
        case .text:
            self = .text(try container.decode(TextElement.self, forKey: .data))
        case .shape:
            self = .shape(try container.decode(ShapeElement.self, forKey: .data))
        }
    }
}

/// Image element metadata stored in JSON; actual image data is in Assets/
struct ImageElementFile: Codable {
    var id: UUID
    var assetFilename: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: CGFloat
    var isBackground: Bool
    var shadow: TextShadowStyle

    init(from element: ImageElement, assetFilename: String) {
        self.id = element.id
        self.assetFilename = assetFilename
        self.position = element.position
        self.scale = element.scale
        self.rotation = element.rotation
        self.isBackground = element.isBackground
        self.shadow = element.shadow
    }
}
