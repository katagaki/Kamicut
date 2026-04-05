import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - UTType for .cut

extension UTType {
    static let circleCut = UTType(exportedAs: "com.tsubuzaki.kamicut.cut")
}

// MARK: - CutDocument (ReferenceFileDocument)

/// File document that reads/writes .cut package directories.
/// Used with DocumentGroup to provide the system document browser.
final class CutDocument: @preconcurrency ReferenceFileDocument, ObservableObject, @unchecked Sendable {

    /// The parsed document, stored nonisolated for init, then consumed by editorState.
    private var _initialDocument: EditorDocument?

    /// Must be accessed on MainActor. Lazily created from _initialDocument if needed.
    @MainActor lazy var editorState: EditorState = {
        let state = EditorState()
        if let doc = _initialDocument {
            state.document = doc
            state.documentRevision = 0
            _initialDocument = nil
        }
        return state
    }()

    static var readableContentTypes: [UTType] { [.circleCut] }
    static var writableContentTypes: [UTType] { [.circleCut] }

    nonisolated init() {
        self._initialDocument = nil
    }

    /// Read an existing .cut package from disk.
    nonisolated init(configuration: ReadConfiguration) throws {
        self._initialDocument = try Self.parseFileWrapper(configuration.file)
    }

    private nonisolated static func parseFileWrapper(_ fileWrapper: FileWrapper) throws -> EditorDocument {
        guard fileWrapper.isDirectory else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let metaWrapper = fileWrapper.fileWrappers?["Meta.json"],
              let metaData = metaWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let meta = try decoder.decode(CutMeta.self, from: metaData)

        guard let layersWrapper = fileWrapper.fileWrappers?["Layers.json"],
              let layersData = layersWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let manifest = try decoder.decode(LayersManifest.self, from: layersData)

        let elementsDir = fileWrapper.fileWrappers?["Elements"]
        let assetsDir = fileWrapper.fileWrappers?["Assets"]

        let backgroundImage = loadBackgroundImage(
            decoder: decoder, elementsDir: elementsDir, assetsDir: assetsDir
        )
        let layers = loadLayers(
            manifest: manifest, decoder: decoder,
            elementsDir: elementsDir, assetsDir: assetsDir
        )

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

    private nonisolated static func loadBackgroundImage(
        decoder: JSONDecoder,
        elementsDir: FileWrapper?,
        assetsDir: FileWrapper?
    ) -> ImageElement? {
        guard let bgElementWrapper = elementsDir?.fileWrappers?["background.json"],
              let bgData = bgElementWrapper.regularFileContents,
              let bgPayload = try? decoder.decode(ElementPayload.self, from: bgData),
              case .image(let bgFile) = bgPayload,
              let bgAssetWrapper = assetsDir?.fileWrappers?[bgFile.assetFilename],
              let imageData = bgAssetWrapper.regularFileContents else {
            return nil
        }
        return ImageElement(
            id: bgFile.id,
            imageData: imageData,
            position: bgFile.position,
            scale: bgFile.scale,
            rotation: bgFile.rotation,
            isBackground: true,
            shadow: bgFile.shadow
        )
    }

    private nonisolated static func loadLayers(
        manifest: LayersManifest,
        decoder: JSONDecoder,
        elementsDir: FileWrapper?,
        assetsDir: FileWrapper?
    ) -> [CanvasLayer] {
        var layers: [CanvasLayer] = []
        for ref in manifest.layers {
            let filename = "\(ref.elementID.uuidString).json"
            guard let elementWrapper = elementsDir?.fileWrappers?[filename],
                  let elementData = elementWrapper.regularFileContents,
                  let payload = try? decoder.decode(ElementPayload.self, from: elementData) else {
                continue
            }

            switch payload {
            case .image(let imgFile):
                guard let assetWrapper = assetsDir?.fileWrappers?[imgFile.assetFilename],
                      let imageData = assetWrapper.regularFileContents else { continue }
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
        return layers
    }

    /// Produce a FileWrapper representing the .cut package.
    @MainActor
    func snapshot(contentType: UTType) throws -> FileWrapper {
        try buildFileWrapper()
    }

    nonisolated func fileWrapper(
        snapshot: FileWrapper,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        snapshot
    }

    // MARK: - Build FileWrapper

    @MainActor
    private func buildFileWrapper() throws -> FileWrapper {
        let document = editorState.document
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        var children: [String: FileWrapper] = [:]

        let name = document.circleName.isEmpty
            ? String(localized: "Projects.Untitled")
            : document.circleName

        children["Meta.json"] = try buildMetaWrapper(document: document, name: name, encoder: encoder)

        var assetChildren: [String: FileWrapper] = [:]
        var elementChildren: [String: FileWrapper] = [:]
        var layerRefs: [LayerReference] = []
        try buildLayerWrappers(
            document: document, encoder: encoder,
            assetChildren: &assetChildren,
            elementChildren: &elementChildren,
            layerRefs: &layerRefs
        )
        children["Assets"] = FileWrapper(directoryWithFileWrappers: assetChildren)
        children["Elements"] = FileWrapper(directoryWithFileWrappers: elementChildren)

        let manifest = LayersManifest(layers: layerRefs)
        children["Layers.json"] = FileWrapper(
            regularFileWithContents: try encoder.encode(manifest)
        )

        if let thumbnailWrapper = buildThumbnailWrapper(document: document) {
            children["Thumbnail.jpg"] = thumbnailWrapper
        }

        let root = FileWrapper(directoryWithFileWrappers: children)
        root.preferredFilename = "\(name).cut"
        return root
    }

    @MainActor
    private func buildMetaWrapper(
        document: EditorDocument, name: String, encoder: JSONEncoder
    ) throws -> FileWrapper {
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
        return FileWrapper(regularFileWithContents: try encoder.encode(meta))
    }

    @MainActor
    private func buildLayerWrappers(
        document: EditorDocument, encoder: JSONEncoder,
        assetChildren: inout [String: FileWrapper],
        elementChildren: inout [String: FileWrapper],
        layerRefs: inout [LayerReference]
    ) throws {

        if let backgroundImage = document.backgroundImage {
            let assetFilename = "background.png"
            assetChildren[assetFilename] = FileWrapper(
                regularFileWithContents: backgroundImage.imageData
            )
            let bgPayload = ElementPayload.image(
                ImageElementFile(from: backgroundImage, assetFilename: assetFilename)
            )
            elementChildren["background.json"] = FileWrapper(
                regularFileWithContents: try encoder.encode(bgPayload)
            )
        }

        for layer in document.layers {
            switch layer {
            case .image(let img):
                let assetFilename = "\(img.id.uuidString).png"
                assetChildren[assetFilename] = FileWrapper(
                    regularFileWithContents: img.imageData
                )
                let payload = ElementPayload.image(
                    ImageElementFile(from: img, assetFilename: assetFilename)
                )
                elementChildren["\(img.id.uuidString).json"] = FileWrapper(
                    regularFileWithContents: try encoder.encode(payload)
                )
                layerRefs.append(LayerReference(elementID: img.id, type: .image))
            case .text(let txt):
                let payload = ElementPayload.text(txt)
                elementChildren["\(txt.id.uuidString).json"] = FileWrapper(
                    regularFileWithContents: try encoder.encode(payload)
                )
                layerRefs.append(LayerReference(elementID: txt.id, type: .text))
            case .shape(let shp):
                let payload = ElementPayload.shape(shp)
                elementChildren["\(shp.id.uuidString).json"] = FileWrapper(
                    regularFileWithContents: try encoder.encode(payload)
                )
                layerRefs.append(LayerReference(elementID: shp.id, type: .shape))
            }
        }

    }

    @MainActor
    private func buildThumbnailWrapper(document: EditorDocument) -> FileWrapper? {
        let renderer = CircleCutRenderer()
        guard let rendered = renderer.render(document: document) else { return nil }
        let maxDimension: CGFloat = 512
        let aspect = rendered.size.width / rendered.size.height
        let thumbSize: CGSize
        if aspect > 1 {
            thumbSize = CGSize(
                width: maxDimension,
                height: (maxDimension / aspect).rounded(.down)
            )
        } else {
            thumbSize = CGSize(
                width: (maxDimension * aspect).rounded(.down),
                height: maxDimension
            )
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let thumb = UIGraphicsImageRenderer(size: thumbSize, format: format).image { _ in
            rendered.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
        guard let jpegData = thumb.jpegData(compressionQuality: 0.7) else { return nil }
        return FileWrapper(regularFileWithContents: jpegData)
    }
}
