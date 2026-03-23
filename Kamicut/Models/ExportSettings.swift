import Foundation

// MARK: - Export Format

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case png = "PNG"
    case jpg = "JPEG"

    var id: String { rawValue }
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpg: return "jpg"
        }
    }
}

// MARK: - Export Color Mode

enum ExportColorMode: String, Codable, CaseIterable, Identifiable {
    case color = "Color"
    case blackAndWhite = "Black & White"

    var id: String { rawValue }
}

// MARK: - Export Resolution

enum ExportResolution: Int, Codable, CaseIterable, Identifiable {
    case low = 150
    case medium = 300
    case high = 350
    case ultra = 600

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .low: return "150 dpi (screen)"
        case .medium: return "300 dpi (print)"
        case .high: return "350 dpi (high print)"
        case .ultra: return "600 dpi (ultra)"
        }
    }
}

// MARK: - Export Settings

struct ExportSettings: Codable {
    var format: ExportFormat = .png
    var colorMode: ExportColorMode = .color
    var resolution: ExportResolution = .high
    var jpegQuality: Double = 0.9

}
