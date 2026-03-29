import Foundation
import UIKit
import Observation

// MARK: - Cut Storage Manager

@Observable
@MainActor
final class CutStorageManager {

    private(set) var cuts: [CutListItem] = []

    static let shared = CutStorageManager()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    private init() {}

    // MARK: - Paths

    /// Root folder: Documents/Kamicut/
    var rootDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Kamicut", isDirectory: true)
    }

    func packageURL(for id: UUID, name: String) -> URL {
        rootDirectory.appendingPathComponent("\(name)_\(id.uuidString).cut", isDirectory: true)
    }

    private func assetsURL(in packageURL: URL) -> URL {
        packageURL.appendingPathComponent("Assets", isDirectory: true)
    }

    private func elementsURL(in packageURL: URL) -> URL {
        packageURL.appendingPathComponent("Elements", isDirectory: true)
    }

    private func metaURL(in packageURL: URL) -> URL {
        packageURL.appendingPathComponent("Meta.json")
    }

    private func layersURL(in packageURL: URL) -> URL {
        packageURL.appendingPathComponent("Layers.json")
    }

    private func thumbnailURL(in packageURL: URL) -> URL {
        packageURL.appendingPathComponent("Thumbnail.jpg")
    }

    // MARK: - Load All Projects

    func loadAllCuts() {
        let root = rootDirectory
        guard fileManager.fileExists(atPath: root.path) else {
            cuts = []
            return
        }

        var items: [CutListItem] = []
        guard let contents = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            cuts = []
            return
        }

        for url in contents where url.pathExtension == "cut" {
            let metaFile = metaURL(in: url)
            guard let data = try? Data(contentsOf: metaFile),
                  let meta = try? decoder.decode(CutMeta.self, from: data) else {
                continue
            }
            let thumbURL = thumbnailURL(in: url)
            let thumbnailData = try? Data(contentsOf: thumbURL)
            items.append(CutListItem(
                id: meta.id,
                name: meta.name,
                createdAt: meta.createdAt,
                updatedAt: meta.updatedAt,
                thumbnailData: thumbnailData,
                packageURL: url
            ))
        }

        cuts = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Load Full Document

    func loadDocument(from packageURL: URL) throws -> EditorDocument {
        let metaData = try Data(contentsOf: metaURL(in: packageURL))
        let meta = try decoder.decode(CutMeta.self, from: metaData)

        let layersData = try Data(contentsOf: layersURL(in: packageURL))
        let manifest = try decoder.decode(LayersManifest.self, from: layersData)

        let elementsDir = elementsURL(in: packageURL)
        let assetsDir = assetsURL(in: packageURL)

        // Load background image if present
        var backgroundImage: ImageElement?
        let bgAssetPath = assetsDir.appendingPathComponent("background.png")
        let bgElementPath = elementsDir.appendingPathComponent("background.json")
        if let bgPayloadData = try? Data(contentsOf: bgElementPath),
           let bgPayload = try? decoder.decode(ElementPayload.self, from: bgPayloadData),
           case .image(let bgFile) = bgPayload,
           let imageData = try? Data(contentsOf: assetsDir.appendingPathComponent(bgFile.assetFilename)) {
            backgroundImage = ImageElement(
                id: bgFile.id,
                imageData: imageData,
                position: bgFile.position,
                scale: bgFile.scale,
                rotation: bgFile.rotation,
                isBackground: true,
                shadow: bgFile.shadow
            )
        }

        // Load layer elements
        var layers: [CanvasLayer] = []
        for ref in manifest.layers {
            let elementFile = elementsDir.appendingPathComponent("\(ref.elementID.uuidString).json")
            guard let elementData = try? Data(contentsOf: elementFile),
                  let payload = try? decoder.decode(ElementPayload.self, from: elementData) else {
                continue
            }

            switch payload {
            case .image(let imgFile):
                let assetPath = assetsDir.appendingPathComponent(imgFile.assetFilename)
                guard let imageData = try? Data(contentsOf: assetPath) else { continue }
                let element = ImageElement(
                    id: imgFile.id,
                    imageData: imageData,
                    position: imgFile.position,
                    scale: imgFile.scale,
                    rotation: imgFile.rotation,
                    isBackground: false,
                    shadow: imgFile.shadow
                )
                layers.append(.image(element))
            case .text(let txt):
                layers.append(.text(txt))
            case .shape(let shp):
                layers.append(.shape(shp))
            }
        }

        var doc = EditorDocument()
        doc.id = meta.id
        doc.circleName = meta.circleName
        doc.template = meta.template
        doc.bleedOption = meta.bleedOption
        doc.backgroundColor = meta.backgroundColor
        doc.backgroundImage = backgroundImage
        doc.layers = layers
        doc.spaceNumber = meta.spaceNumber
        doc.exportSettings = meta.exportSettings
        return doc
    }

    // MARK: - Save Document

    @discardableResult
    func saveDocument(_ document: EditorDocument, name: String, existingPackageURL: URL? = nil, thumbnailData: Data? = nil) throws -> URL {
        // Determine package URL
        let pkgURL: URL
        if let existing = existingPackageURL {
            pkgURL = existing
        } else {
            pkgURL = packageURL(for: document.id, name: sanitizeFilename(name))
        }

        // Create directory structure
        let assetsDir = assetsURL(in: pkgURL)
        let elementsDir = elementsURL(in: pkgURL)
        try fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: elementsDir, withIntermediateDirectories: true)

        // Clean existing elements and assets to avoid stale files
        cleanDirectory(elementsDir)
        cleanDirectory(assetsDir)

        // Write Meta.json
        let meta = CutMeta(
            id: document.id,
            name: name,
            circleName: document.circleName,
            createdAt: Date(),
            updatedAt: Date(),
            template: document.template,
            bleedOption: document.bleedOption,
            backgroundColor: document.backgroundColor,
            spaceNumber: document.spaceNumber,
            exportSettings: document.exportSettings
        )
        try encoder.encode(meta).write(to: metaURL(in: pkgURL))

        // Write background image if present
        if let bg = document.backgroundImage {
            let assetFilename = "background.png"
            try bg.imageData.write(to: assetsDir.appendingPathComponent(assetFilename))
            let bgPayload = ElementPayload.image(ImageElementFile(from: bg, assetFilename: assetFilename))
            try encoder.encode(bgPayload).write(to: elementsDir.appendingPathComponent("background.json"))
        }

        // Write layer elements
        var layerRefs: [LayerReference] = []
        for layer in document.layers {
            switch layer {
            case .image(let img):
                let assetFilename = "\(img.id.uuidString).png"
                try img.imageData.write(to: assetsDir.appendingPathComponent(assetFilename))
                let payload = ElementPayload.image(ImageElementFile(from: img, assetFilename: assetFilename))
                try encoder.encode(payload).write(to: elementsDir.appendingPathComponent("\(img.id.uuidString).json"))
                layerRefs.append(LayerReference(elementID: img.id, type: .image))
            case .text(let txt):
                let payload = ElementPayload.text(txt)
                try encoder.encode(payload).write(to: elementsDir.appendingPathComponent("\(txt.id.uuidString).json"))
                layerRefs.append(LayerReference(elementID: txt.id, type: .text))
            case .shape(let shp):
                let payload = ElementPayload.shape(shp)
                try encoder.encode(payload).write(to: elementsDir.appendingPathComponent("\(shp.id.uuidString).json"))
                layerRefs.append(LayerReference(elementID: shp.id, type: .shape))
            }
        }

        // Write Layers.json
        let manifest = LayersManifest(layers: layerRefs)
        try encoder.encode(manifest).write(to: layersURL(in: pkgURL))

        // Write Thumbnail.jpg
        if let thumbnailData {
            try thumbnailData.write(to: thumbnailURL(in: pkgURL))
        }

        return pkgURL
    }

    // MARK: - Save with preserved dates

    func saveDocument(_ document: EditorDocument, name: String, existingPackageURL: URL? = nil, thumbnailData: Data? = nil, createdAt: Date, updatedAt: Date) throws -> URL {
        let pkgURL = try saveDocument(document, name: name, existingPackageURL: existingPackageURL, thumbnailData: thumbnailData)

        // Re-read and update dates in Meta.json
        let metaFile = metaURL(in: pkgURL)
        var metaData = try Data(contentsOf: metaFile)
        var meta = try decoder.decode(CutMeta.self, from: metaData)
        meta.createdAt = createdAt
        meta.updatedAt = updatedAt
        metaData = try encoder.encode(meta)
        try metaData.write(to: metaFile)

        return pkgURL
    }

    // MARK: - Update thumbnail only

    func updateThumbnail(at packageURL: URL, thumbnailData: Data?) {
        let thumbURL = thumbnailURL(in: packageURL)
        if let thumbnailData {
            try? thumbnailData.write(to: thumbURL)
        }
    }

    // MARK: - Delete

    func deleteCut(at packageURL: URL) {
        try? fileManager.removeItem(at: packageURL)
        cuts.removeAll { $0.packageURL == packageURL }
    }

    // MARK: - Rename

    func renameCut(at packageURL: URL, newName: String) throws {
        let metaFile = metaURL(in: packageURL)
        let data = try Data(contentsOf: metaFile)
        var meta = try decoder.decode(CutMeta.self, from: data)
        meta.name = newName
        meta.circleName = newName
        meta.updatedAt = Date()
        try encoder.encode(meta).write(to: metaFile)
    }

    // MARK: - Duplicate

    func duplicateCut(from packageURL: URL, newName: String) throws -> URL {
        let document = try loadDocument(from: packageURL)
        var newDoc = document
        newDoc.id = UUID()
        newDoc.circleName = newName

        let thumbURL = thumbnailURL(in: packageURL)
        let thumbnailData = try? Data(contentsOf: thumbURL)

        return try saveDocument(newDoc, name: newName, thumbnailData: thumbnailData)
    }

    // MARK: - Helpers

    private func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let sanitized = name.unicodeScalars.filter { allowed.contains($0) }.map { Character($0) }
        let result = String(sanitized).trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "Untitled" : result
    }

    private func cleanDirectory(_ url: URL) {
        guard let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
}

// MARK: - Cut List Item

struct CutListItem: Identifiable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var thumbnailData: Data?
    var packageURL: URL

    static func == (lhs: CutListItem, rhs: CutListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
