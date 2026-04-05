import Foundation
import UIKit
import Observation

// MARK: - Cut Storage Manager

/// Used by DataMigrator to write legacy SwiftData projects as .cut packages.
@MainActor
final class CutStorageManager {

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

    /// Root folder: Documents/
    var rootDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func packageURL(for id: UUID, name: String) -> URL {
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

    // MARK: - Save Document

    @discardableResult
    func saveDocument(
        _ document: EditorDocument,
        name: String,
        existingPackageURL: URL? = nil,
        thumbnailData: Data? = nil
    ) throws -> URL {
        let pkgURL: URL
        if let existing = existingPackageURL {
            pkgURL = existing
        } else {
            pkgURL = packageURL(for: document.id, name: sanitizeFilename(name))
        }

        let assetsDir = assetsURL(in: pkgURL)
        let elementsDir = elementsURL(in: pkgURL)
        try fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: elementsDir, withIntermediateDirectories: true)

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

        // Write background, layers, and manifest
        try writeLayers(
            document: document,
            assetsDir: assetsDir,
            elementsDir: elementsDir,
            pkgURL: pkgURL
        )

        // Write Thumbnail.jpg
        if let thumbnailData {
            try thumbnailData.write(to: thumbnailURL(in: pkgURL))
        }

        return pkgURL
    }

    // MARK: - Save with preserved dates

    func saveDocument(
        _ document: EditorDocument,
        name: String,
        existingPackageURL: URL? = nil,
        thumbnailData: Data? = nil,
        createdAt: Date,
        updatedAt: Date
    ) throws -> URL {
        let pkgURL = try saveDocument(
            document, name: name,
            existingPackageURL: existingPackageURL,
            thumbnailData: thumbnailData
        )

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

    // MARK: - Write Layers

    private func writeLayers(
        document: EditorDocument,
        assetsDir: URL,
        elementsDir: URL,
        pkgURL: URL
    ) throws {
        if let backgroundImage = document.backgroundImage {
            let assetFilename = "background.png"
            try backgroundImage.imageData.write(
                to: assetsDir.appendingPathComponent(assetFilename)
            )
            let bgPayload = ElementPayload.image(
                ImageElementFile(from: backgroundImage, assetFilename: assetFilename)
            )
            try encoder.encode(bgPayload).write(
                to: elementsDir.appendingPathComponent("background.json")
            )
        }

        var layerRefs: [LayerReference] = []
        for layer in document.layers {
            switch layer {
            case .image(let img):
                let assetFilename = "\(img.id.uuidString).png"
                try img.imageData.write(
                    to: assetsDir.appendingPathComponent(assetFilename)
                )
                let payload = ElementPayload.image(
                    ImageElementFile(from: img, assetFilename: assetFilename)
                )
                try encoder.encode(payload).write(
                    to: elementsDir.appendingPathComponent("\(img.id.uuidString).json")
                )
                layerRefs.append(LayerReference(elementID: img.id, type: .image))
            case .text(let txt):
                let payload = ElementPayload.text(txt)
                try encoder.encode(payload).write(
                    to: elementsDir.appendingPathComponent("\(txt.id.uuidString).json")
                )
                layerRefs.append(LayerReference(elementID: txt.id, type: .text))
            case .shape(let shp):
                let payload = ElementPayload.shape(shp)
                try encoder.encode(payload).write(
                    to: elementsDir.appendingPathComponent("\(shp.id.uuidString).json")
                )
                layerRefs.append(LayerReference(elementID: shp.id, type: .shape))
            }
        }

        let manifest = LayersManifest(layers: layerRefs)
        try encoder.encode(manifest).write(to: layersURL(in: pkgURL))
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
