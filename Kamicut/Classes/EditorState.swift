import SwiftUI
import Observation

// MARK: - Editor State

@Observable
@MainActor
final class EditorState {

    // MARK: Document State

    var document: EditorDocument = EditorDocument() {
        didSet { documentRevision += 1 }
    }

    // MARK: Selection State

    var selectedImageID: UUID?
    var selectedTextID: UUID?
    var selectedShapeID: UUID?

    // MARK: UI State

    var showTemplatePicker: Bool = false
    var showProjectSettings: Bool = false
    var showExportSheet: Bool = false
    var showSpaceNumberEditor: Bool = false
    var showLayerManager: Bool = false
var showBackgroundSettings: Bool = false
    var showSquiggleEditor: Bool = false

    // MARK: Auto-Save Tracking

    /// Incremented on every document mutation to drive debounced auto-save.
    var documentRevision: Int = 0

    // MARK: Export State

    var exportedImage: UIImage?
    var isExporting: Bool = false

    // MARK: - Template

    var template: CircleCutTemplate {
        get { document.template }
        set { document.template = newValue }
    }

    // MARK: - Bleed

    var bleedOption: BleedOption {
        get { document.bleedOption }
        set { document.bleedOption = newValue }
    }

    // MARK: - Background Color

    func setBackgroundColor(_ color: Color) {
        document.backgroundColor = CodableColor(color: color)
    }

    func removeBackgroundColor() {
        document.backgroundColor = nil
    }

    // MARK: - Background Image

    func setBackgroundImage(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        document.backgroundImage = ImageElement(imageData: data, isBackground: true)
    }

    func removeBackgroundImage() {
        document.backgroundImage = nil
    }

    // MARK: - Overlay Images

    func addOverlayImage(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        let element = ImageElement(imageData: data, isBackground: false)
        document.layers.append(.image(element))
        selectedImageID = element.id
        selectedTextID = nil
        selectedShapeID = nil
    }

    func removeOverlayImage(id: UUID) {
        document.layers.removeAll { $0.id == id }
        if selectedImageID == id { selectedImageID = nil }
    }

    // MARK: - Text Elements

    func addTextElement() -> UUID {
        var element = TextElement()
        element.content = String(localized: "DefaultText.Content")
        element.position = CGPoint(x: 0.5, y: 0.5)
        document.layers.append(.text(element))
        selectedTextID = element.id
        selectedImageID = nil
        selectedShapeID = nil
        return element.id
    }

    func removeTextElement(id: UUID) {
        document.layers.removeAll { $0.id == id }
        if selectedTextID == id { selectedTextID = nil }
    }

    // MARK: - Shape Elements

    func addShapeElement(_ kind: ShapeKind) -> UUID {
        // Default to a visually square shape on the canvas
        let canvas = document.template.canvasSize
        let sideInPoints: CGFloat = min(canvas.width, canvas.height) * 0.2
        let normalizedW = sideInPoints / canvas.width
        let normalizedH = sideInPoints / canvas.height
        var element = ShapeElement(shapeKind: kind)
        element.size = CGSize(width: normalizedW, height: normalizedH)
        document.layers.append(.shape(element))
        selectedShapeID = element.id
        selectedImageID = nil
        selectedTextID = nil
        return element.id
    }

    // MARK: - Layer Management

    func removeLayer(id: UUID) {
        document.layers.removeAll { $0.id == id }
        if selectedImageID == id { selectedImageID = nil }
        if selectedTextID == id { selectedTextID = nil }
        if selectedShapeID == id { selectedShapeID = nil }
    }

    var selectedLayerLabel: String {
        let id = selectedTextID ?? selectedShapeID ?? selectedImageID
        guard let id, let layer = document.layers.first(where: { $0.id == id }) else { return "" }
        return layer.label
    }

    func selectLayer(id: UUID) {
        guard let layer = document.layers.first(where: { $0.id == id }) else { return }
        selectedImageID = nil
        selectedTextID = nil
        selectedShapeID = nil
        switch layer {
        case .image:
            selectedImageID = id
        case .text:
            selectedTextID = id
        case .shape:
            selectedShapeID = id
        }
    }

    func moveLayers(from source: IndexSet, to destination: Int) {
        document.layers.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Space Number

    var spaceNumber: SpaceNumberInfo {
        get { document.spaceNumber }
        set { document.spaceNumber = newValue }
    }

    // MARK: - Export Settings

    var exportSettings: ExportSettings {
        get { document.exportSettings }
        set { document.exportSettings = newValue }
    }

    // MARK: - Canvas Geometry

    var canvasMM: CGSize { document.template.canvasSize }

    func imageAreaMM() -> CGRect {
        let template = document.template
        let textH = template.textAreaEnabled ? template.textAreaHeight : 0
        let imageY = (template.textAreaEnabled && template.textAreaPosition == .top) ? textH : 0.0
        return CGRect(x: 0, y: imageY, width: template.canvasSize.width, height: template.canvasSize.height - textH)
    }

    func textAreaMM() -> CGRect? {
        let template = document.template
        guard template.textAreaEnabled else { return nil }
        let textY = template.textAreaPosition == .top ? 0.0 : template.canvasSize.height - template.textAreaHeight
        return CGRect(
            x: 0,
            y: textY,
            width: template.canvasSize.width,
            height: template.textAreaHeight
        )
    }

    func checkboxAreaMM() -> CGRect? {
        let template = document.template
        guard template.checkboxAreaEnabled else { return nil }
        return CGRect(origin: .zero, size: template.checkboxAreaSize)
    }

    // MARK: - Export

    func exportImage(renderer: CircleCutRenderer) async -> UIImage? {
        isExporting = true
        defer { isExporting = false }
        let image = renderer.render(document: document)
        exportedImage = image
        return image
    }

    // MARK: - Reset

    func reset() {
        document = EditorDocument()
        selectedImageID = nil
        selectedTextID = nil
        selectedShapeID = nil
        exportedImage = nil
    }
}
