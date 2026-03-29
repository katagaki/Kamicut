import SwiftUI

// MARK: - Canvas Element Base

enum CanvasElementType: String, Codable {
    case image
    case text
    case shape
}

// MARK: - Image Element

struct ImageElement: Identifiable, Codable {
    var id: UUID = UUID()
    var imageData: Data
    /// Position as fraction of canvas (0–1)
    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)
    /// Scale multiplier
    var scale: CGFloat = 1.0
    /// Rotation in degrees
    var rotation: CGFloat = 0.0
    /// Whether this is the main background image
    var isBackground: Bool = false
    var shadow: TextShadowStyle = TextShadowStyle()

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }
}

// MARK: - Text Style

struct TextShadowStyle: Codable, Hashable {
    var enabled: Bool = false
    var color: CodableColor = CodableColor(color: UIColor.black)
    var radius: CGFloat = 2
    var offsetX: CGFloat = 1
    var offsetY: CGFloat = 1
}

struct TextOutlineStyle: Codable, Hashable {
    var enabled: Bool = false
    var color: CodableColor = CodableColor(color: UIColor.white)
    var width: CGFloat = 1.5
}

struct TextElement: Identifiable, Codable {
    var id: UUID = UUID()
    var content: String = ""
    var fontName: String = "HiraginoSans-W3"
    var fontSize: CGFloat = 32
    var color: CodableColor = CodableColor(color: UIColor.black)
    var outline: TextOutlineStyle = TextOutlineStyle()
    var shadow: TextShadowStyle = TextShadowStyle()
    var alignment: TextAlignment = .center
    /// Position as fraction of canvas (0–1)
    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var rotation: CGFloat = 0.0
}

// MARK: - Shape Element

enum ShapeKind: String, Codable, CaseIterable, Identifiable {
    case square
    case rectangle
    case circle
    case ellipse
    case triangle
    case star
    case pentagon
    case hexagon

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .square: return String(localized: "Shape.Square")
        case .rectangle: return String(localized: "Shape.Rectangle")
        case .circle: return String(localized: "Shape.Circle")
        case .ellipse: return String(localized: "Shape.Ellipse")
        case .triangle: return String(localized: "Shape.Triangle")
        case .star: return String(localized: "Shape.Star")
        case .pentagon: return String(localized: "Shape.Pentagon")
        case .hexagon: return String(localized: "Shape.Hexagon")
        }
    }

    var systemImage: String {
        switch self {
        case .square: return "square.fill"
        case .rectangle: return "rectangle.fill"
        case .circle: return "circle.fill"
        case .ellipse: return "oval.fill"
        case .triangle: return "triangle.fill"
        case .star: return "star.fill"
        case .pentagon: return "pentagon.fill"
        case .hexagon: return "hexagon.fill"
        }
    }

    var aspectLocked: Bool {
        switch self {
        case .square, .circle: return true
        default: return false
        }
    }
}

struct ShapeElement: Identifiable, Codable {
    var id: UUID = UUID()
    var shapeKind: ShapeKind = .rectangle
    /// Position as fraction of canvas (0–1)
    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)
    /// Scale multiplier
    var scale: CGFloat = 1.0
    /// Rotation in degrees
    var rotation: CGFloat = 0.0
    /// Size as fraction of canvas (0–1)
    var size: CGSize = CGSize(width: 0.2, height: 0.2)
    var fillColor: CodableColor = CodableColor(color: UIColor.black)
    var strokeColor: CodableColor = CodableColor(color: UIColor.black)
    var strokeWidth: CGFloat = 2.0
}

// MARK: - Canvas Layer

enum CanvasLayer: Identifiable, Codable {
    case image(ImageElement)
    case text(TextElement)
    case shape(ShapeElement)

    var id: UUID {
        switch self {
        case .image(let img): return img.id
        case .text(let txt): return txt.id
        case .shape(let shp): return shp.id
        }
    }

    var label: String {
        switch self {
        case .image: return String(localized: "Layers.Image")
        case .text(let txt):
            return txt.content.isEmpty
                ? String(localized: "Layers.Text")
                : String(txt.content.prefix(20))
        case .shape(let shp): return shp.shapeKind.localizedName
        }
    }

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .text: return "textformat"
        case .shape(let shp): return shp.shapeKind.systemImage
        }
    }
}

// MARK: - Space Number

enum SpaceNumberPosition: String, Codable, CaseIterable {
    case textArea = "Text area"
    case textAreaLeading = "Text area (leading)"
    case textAreaTrailing = "Text area (trailing)"
    case imageTopLeft = "Image (top-left)"
    case imageTopRight = "Image (top-right)"
    case imageBottomLeft = "Image (bottom-left)"
    case imageBottomRight = "Image (bottom-right)"

    var localizedName: String {
        switch self {
        case .textArea: return String(localized: "SpaceNumber.Position.TextArea")
        case .textAreaLeading: return String(localized: "SpaceNumber.Position.TextAreaLeading")
        case .textAreaTrailing: return String(localized: "SpaceNumber.Position.TextAreaTrailing")
        case .imageTopLeft: return String(localized: "SpaceNumber.Position.ImageTopLeft")
        case .imageTopRight: return String(localized: "SpaceNumber.Position.ImageTopRight")
        case .imageBottomLeft: return String(localized: "SpaceNumber.Position.ImageBottomLeft")
        case .imageBottomRight: return String(localized: "SpaceNumber.Position.ImageBottomRight")
        }
    }
}

struct SpaceNumberInfo: Codable {
    var text: String = ""
    var position: SpaceNumberPosition = .textArea
    var fontName: String = "HiraginoSans-W6"
    var fontSize: CGFloat = 10
    var color: CodableColor = CodableColor(color: UIColor.black)
}

// MARK: - Bleed Option

enum BleedOption: String, Codable, CaseIterable {
    case none = "No Bleed"
    case full = "Full Bleed"

    var localizedName: String {
        switch self {
        case .none: return String(localized: "Bleed.None")
        case .full: return String(localized: "Bleed.Full")
        }
    }
}

// MARK: - CodableColor helper

struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(color: UIColor) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Double(red); self.green = Double(green); self.blue = Double(blue); self.alpha = Double(alpha)
    }

    init(color: Color) {
        self.init(color: UIColor(color))
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - TextAlignment Codable

extension TextAlignment: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "leading": self = .leading
        case "trailing": self = .trailing
        default: self = .center
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .leading: try container.encode("leading")
        case .trailing: try container.encode("trailing")
        default: try container.encode("center")
        }
    }
}
