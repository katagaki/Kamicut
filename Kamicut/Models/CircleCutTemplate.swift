import SwiftUI

// MARK: - Text Area Position

enum TextAreaPosition: String, Codable, CaseIterable {
    case top = "Top"
    case bottom = "Bottom"

    var localizedName: String {
        switch self {
        case .top: return String(localized: "TextArea.Position.Top")
        case .bottom: return String(localized: "TextArea.Position.Bottom")
        }
    }
}

// MARK: - Template

struct CircleCutTemplate: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var displayName: String

    // Canvas size in pixels
    var canvasSize: CGSize

    // Borders
    var outerBorderThickness: CGFloat
    var innerBorderThickness: CGFloat

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

    static func == (lhs: CircleCutTemplate, rhs: CircleCutTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Predefined Templates

extension CircleCutTemplate {
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
