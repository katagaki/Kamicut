import Foundation

// MARK: - Export Format

nonisolated enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case png
    case jpg

    var id: String { rawValue }
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpg: return "jpg"
        }
    }
    var localizedName: String {
        switch self {
        case .png: return String(localized: "Export.Format.Png")
        case .jpg: return String(localized: "Export.Format.Jpeg")
        }
    }
}

// MARK: - Export Color Mode

nonisolated enum ExportColorMode: String, Codable, CaseIterable, Identifiable {
    case color
    case blackAndWhite

    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .color: return String(localized: "Export.ColorMode.Color")
        case .blackAndWhite: return String(localized: "Export.ColorMode.BlackAndWhite")
        }
    }
}

// MARK: - Export Resolution

nonisolated enum ExportResolution: Int, Codable, CaseIterable, Identifiable {
    case low = 150
    case medium = 300
    case high = 350
    case ultra = 600

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .low: return String(localized: "Export.Resolution.Low")
        case .medium: return String(localized: "Export.Resolution.Medium")
        case .high: return String(localized: "Export.Resolution.High")
        case .ultra: return String(localized: "Export.Resolution.Ultra")
        }
    }
}

// MARK: - Export Settings

nonisolated struct ExportSettings: Codable {
    var format: ExportFormat = .png
    var colorMode: ExportColorMode = .color
    var resolution: ExportResolution = .high
    var jpegQuality: Double = 0.9

}
