import SwiftUI

// MARK: - Canvas Element Base

enum CanvasElementType: String, Codable {
    case image
    case text
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

// MARK: - Canvas Layer

enum CanvasLayer: Identifiable, Codable {
    case image(ImageElement)
    case text(TextElement)

    var id: UUID {
        switch self {
        case .image(let el): return el.id
        case .text(let el): return el.id
        }
    }

    var label: String {
        switch self {
        case .image: return "Image"
        case .text(let el): return el.content.isEmpty ? "Text" : String(el.content.prefix(20))
        }
    }

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .text: return "textformat"
        }
    }
}

// MARK: - Space Number

enum SpaceNumberPosition: String, Codable, CaseIterable {
    case topLeftBox = "Top-left box"
    case textArea = "Text area"
    case textAreaLeading = "Text area (leading)"
    case textAreaTrailing = "Text area (trailing)"
    case imageTopLeft = "Image (top-left)"
    case imageTopRight = "Image (top-right)"
    case imageBottomLeft = "Image (bottom-left)"
    case imageBottomRight = "Image (bottom-right)"
}

struct SpaceNumberInfo: Codable {
    var text: String = ""
    var position: SpaceNumberPosition = .topLeftBox
    var fontName: String = "HiraginoSans-W6"
    var fontSize: CGFloat = 10
    var color: CodableColor = CodableColor(color: UIColor.black)
}

// MARK: - Bleed Option

enum BleedOption: String, Codable, CaseIterable {
    case none = "No Bleed"
    case full = "Full Bleed"
}

// MARK: - CodableColor helper

struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); alpha = Double(a)
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
