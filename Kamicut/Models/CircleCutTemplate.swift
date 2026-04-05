import SwiftUI

// MARK: - Text Area Position

nonisolated enum TextAreaPosition: String, Codable, CaseIterable {
    case top
    case bottom

    var localizedName: String {
        switch self {
        case .top: return String(localized: "TextArea.Position.Top")
        case .bottom: return String(localized: "TextArea.Position.Bottom")
        }
    }
}

// MARK: - Template

nonisolated struct CircleCutTemplate: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var displayName: String

    // Canvas size in pixels
    var canvasSize: CGSize

    // Borders
    var outerBorderThickness: CGFloat
    var outerBorderColor: CodableColor
    var innerBorderThickness: CGFloat
    var innerBorderColor: CodableColor

    // Checkbox area (space number area)
    var checkboxAreaEnabled: Bool
    var checkboxAreaSize: CGSize

    // Text area
    var textAreaEnabled: Bool
    var textAreaHeight: CGFloat
    var textAreaPosition: TextAreaPosition
    var textAreaTransparent: Bool
    var textAreaBorderThickness: CGFloat
    var textAreaHasTopBorder: Bool

    // Header font name
    var headerFontName: String

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        canvasSize: CGSize,
        outerBorderThickness: CGFloat,
        outerBorderColor: CodableColor = CodableColor(color: UIColor.black),
        innerBorderThickness: CGFloat,
        innerBorderColor: CodableColor = CodableColor(color: UIColor.black),
        checkboxAreaEnabled: Bool,
        checkboxAreaSize: CGSize,
        textAreaEnabled: Bool,
        textAreaHeight: CGFloat,
        textAreaPosition: TextAreaPosition,
        textAreaTransparent: Bool,
        textAreaBorderThickness: CGFloat,
        textAreaHasTopBorder: Bool,
        headerFontName: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.canvasSize = canvasSize
        self.outerBorderThickness = outerBorderThickness
        self.outerBorderColor = outerBorderColor
        self.innerBorderThickness = innerBorderThickness
        self.innerBorderColor = innerBorderColor
        self.checkboxAreaEnabled = checkboxAreaEnabled
        self.checkboxAreaSize = checkboxAreaSize
        self.textAreaEnabled = textAreaEnabled
        self.textAreaHeight = textAreaHeight
        self.textAreaPosition = textAreaPosition
        self.textAreaTransparent = textAreaTransparent
        self.textAreaBorderThickness = textAreaBorderThickness
        self.textAreaHasTopBorder = textAreaHasTopBorder
        self.headerFontName = headerFontName
    }

    var localizedDisplayName: String {
        switch name {
        case "templateA": return String(localized: "Template.ComiketA")
        case "templateB": return String(localized: "Template.ComiketB")
        case "mangaReport": return String(localized: "Template.MangaReport")
        case "comitia": return String(localized: "Template.Comitia")
        case "custom": return String(localized: "Template.Custom")
        default: return displayName
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        canvasSize = try container.decode(CGSize.self, forKey: .canvasSize)
        outerBorderThickness = try container.decode(CGFloat.self, forKey: .outerBorderThickness)
        outerBorderColor = try container.decodeIfPresent(CodableColor.self, forKey: .outerBorderColor)
            ?? CodableColor(color: UIColor.black)
        innerBorderThickness = try container.decode(CGFloat.self, forKey: .innerBorderThickness)
        innerBorderColor = try container.decodeIfPresent(CodableColor.self, forKey: .innerBorderColor)
            ?? CodableColor(color: UIColor.black)
        checkboxAreaEnabled = try container.decode(Bool.self, forKey: .checkboxAreaEnabled)
        checkboxAreaSize = try container.decode(CGSize.self, forKey: .checkboxAreaSize)
        textAreaEnabled = try container.decode(Bool.self, forKey: .textAreaEnabled)
        textAreaHeight = try container.decode(CGFloat.self, forKey: .textAreaHeight)
        textAreaPosition = try container.decode(TextAreaPosition.self, forKey: .textAreaPosition)
        textAreaTransparent = try container.decode(Bool.self, forKey: .textAreaTransparent)
        textAreaBorderThickness = try container.decode(CGFloat.self, forKey: .textAreaBorderThickness)
        textAreaHasTopBorder = try container.decode(Bool.self, forKey: .textAreaHasTopBorder)
        headerFontName = try container.decode(String.self, forKey: .headerFontName)
    }

    static func == (lhs: CircleCutTemplate, rhs: CircleCutTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Predefined Templates

nonisolated extension CircleCutTemplate {
    // All sizes in pixels.

    /// Comiket サークルカットテンプレートA (635×903px)
    static let templateA = CircleCutTemplate(
        name: "templateA",
        displayName: "Comiket Template A (635×903)",
        canvasSize: CGSize(width: 635, height: 903),
        outerBorderThickness: 22,
        innerBorderThickness: 17,
        checkboxAreaEnabled: true,
        checkboxAreaSize: CGSize(width: 143, height: 143),
        textAreaEnabled: true,
        textAreaHeight: 143,
        textAreaPosition: .top,
        textAreaTransparent: false,
        textAreaBorderThickness: 17,
        textAreaHasTopBorder: true,
        headerFontName: "HiraginoSans-W3"
    )

    /// Comiket サークルカットテンプレートB (635×903px)
    static let templateB = CircleCutTemplate(
        name: "templateB",
        displayName: "Comiket Template B (635×903)",
        canvasSize: CGSize(width: 635, height: 903),
        outerBorderThickness: 22,
        innerBorderThickness: 17,
        checkboxAreaEnabled: true,
        checkboxAreaSize: CGSize(width: 143, height: 143),
        textAreaEnabled: false,
        textAreaHeight: 0,
        textAreaPosition: .top,
        textAreaTransparent: false,
        textAreaBorderThickness: 17,
        textAreaHasTopBorder: true,
        headerFontName: "HiraginoSans-W6"
    )

    /// Comiket まんがレポートテンプレート (850×1275px)
    static let mangaReport = CircleCutTemplate(
        name: "mangaReport",
        displayName: "Comiket Manga Report (850×1275)",
        canvasSize: CGSize(width: 850, height: 1275),
        outerBorderThickness: 24,
        innerBorderThickness: 24,
        checkboxAreaEnabled: false,
        checkboxAreaSize: CGSize(width: 143, height: 143),
        textAreaEnabled: true,
        textAreaHeight: 114,
        textAreaPosition: .bottom,
        textAreaTransparent: false,
        textAreaBorderThickness: 4,
        textAreaHasTopBorder: false,
        headerFontName: "HiraginoSans-W3"
    )

    /// COMITIA サークルカットテンプレート (638×945px)
    static let comitia = CircleCutTemplate(
        name: "comitia",
        displayName: "COMITIA (638×945)",
        canvasSize: CGSize(width: 638, height: 945),
        outerBorderThickness: 24,
        innerBorderThickness: 7,
        checkboxAreaEnabled: true,
        checkboxAreaSize: CGSize(width: 163, height: 163),
        textAreaEnabled: true,
        textAreaHeight: 163,
        textAreaPosition: .top,
        textAreaTransparent: false,
        textAreaBorderThickness: 7,
        textAreaHasTopBorder: true,
        headerFontName: "HiraginoSans-W3"
    )

    static let custom = CircleCutTemplate(
        name: "custom",
        displayName: "Custom",
        canvasSize: CGSize(width: 635, height: 903),
        outerBorderThickness: 22,
        innerBorderThickness: 17,
        checkboxAreaEnabled: true,
        checkboxAreaSize: CGSize(width: 143, height: 143),
        textAreaEnabled: true,
        textAreaHeight: 143,
        textAreaPosition: .top,
        textAreaTransparent: false,
        textAreaBorderThickness: 17,
        textAreaHasTopBorder: true,
        headerFontName: "HiraginoSans-W3"
    )

    static let predefined: [CircleCutTemplate] = [.templateA, .templateB, .mangaReport, .comitia]
}
