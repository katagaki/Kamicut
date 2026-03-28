import SwiftUI
import Observation

// MARK: - Editor State

@Observable
@MainActor
final class EditorState {

    // MARK: Document State

    var document: EditorDocument = EditorDocument()

    // MARK: Selection State

    var selectedImageID: UUID? = nil
    var selectedTextID: UUID? = nil
    var selectedShapeID: UUID? = nil

    // MARK: Saved Cut Tracking

    var currentSavedCutID: UUID? = nil
    var currentSavedCutName: String = ""

    // MARK: UI State

    var showTemplatePicker: Bool = false
    var showProjectSettings: Bool = false
    var showExportSheet: Bool = false
    var showSpaceNumberEditor: Bool = false
    var showLayerManager: Bool = false
    var showSavedCutsList: Bool = false
    var showBackgroundSettings: Bool = false
    var showSquiggleEditor: Bool = false

    // MARK: Export State

    var exportedImage: UIImage? = nil
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
        let element = ShapeElement(shapeKind: kind)
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
        let t = document.template
        let textH = t.textAreaEnabled ? t.textAreaHeight : 0
        let imageY = (t.textAreaEnabled && t.textAreaPosition == .top) ? textH : 0.0
        return CGRect(x: 0, y: imageY, width: t.canvasSize.width, height: t.canvasSize.height - textH)
    }

    func textAreaMM() -> CGRect? {
        let t = document.template
        guard t.textAreaEnabled else { return nil }
        let textY = t.textAreaPosition == .top ? 0.0 : t.canvasSize.height - t.textAreaHeight
        return CGRect(
            x: 0,
            y: textY,
            width: t.canvasSize.width,
            height: t.textAreaHeight
        )
    }

    func topLeftBoxMM() -> CGRect? {
        let t = document.template
        guard t.topLeftBoxEnabled else { return nil }
        return CGRect(origin: .zero, size: t.topLeftBoxSize)
    }

    // MARK: - Export

    func exportImage(renderer: CircleCutRenderer) async -> UIImage? {
        isExporting = true
        defer { isExporting = false }
        let image = await renderer.render(document: document)
        exportedImage = image
        return image
    }

    // MARK: - Load Saved Cut

    func loadSavedCut(_ savedCut: SavedCut) throws {
        self.document = try savedCut.loadDocument()
        self.currentSavedCutID = savedCut.id
        self.currentSavedCutName = savedCut.name
        self.selectedImageID = nil
        self.selectedTextID = nil
        self.selectedShapeID = nil
        self.exportedImage = nil
    }

    // MARK: - Reset

    func reset() {
        document = EditorDocument()
        currentSavedCutID = nil
        currentSavedCutName = ""
        selectedImageID = nil
        selectedTextID = nil
        selectedShapeID = nil
        exportedImage = nil
    }
}
