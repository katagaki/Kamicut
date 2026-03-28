import SwiftUI
import PencilKit

// MARK: - Squiggle Editor View

/// Full-screen drawing overlay using PencilKit.
/// Users can draw continuously with pencil or eraser, then confirm to add as a layer.
struct SquiggleEditorView: View {
    var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    @State private var canvasView = PKCanvasView()
    @State private var activeTool: SquiggleTool = .pencil
    @State private var strokeColor: Color = .black
    @State private var strokeWidth: CGFloat = 3.0

    enum SquiggleTool {
        case pencil
        case eraser
    }

    var body: some View {
        NavigationStack {
            SquiggleCanvasRepresentable(
                canvasView: $canvasView,
                activeTool: $activeTool,
                strokeColor: $strokeColor,
                strokeWidth: $strokeWidth,
                canvasSize: vm.document.template.canvasSize
            )
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle(String(localized: "Squiggle.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26, *) {
                        Button(role: .cancel) { dismiss() }
                    } else {
                        Button(String(localized: "Common.Cancel")) { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Squiggle.Done")) {
                        confirmDrawing()
                    }
                    .fontWeight(.semibold)
                    .disabled(canvasView.drawing.strokes.isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    toolSelector
                }
            }
        }
    }

    // MARK: - Tool Selector

    private var toolSelector: some View {
        HStack(spacing: 20) {
            // Pencil
            Button {
                activeTool = .pencil
            } label: {
                Image(systemName: "pencil.tip")
                    .font(.title2)
                    .foregroundStyle(activeTool == .pencil ? Color.accentColor : .secondary)
            }

            // Eraser
            Button {
                activeTool = .eraser
            } label: {
                Image(systemName: "eraser")
                    .font(.title2)
                    .foregroundStyle(activeTool == .eraser ? Color.accentColor : .secondary)
            }

            Divider().frame(height: 24)

            // Stroke color
            ColorPicker("", selection: $strokeColor, supportsOpacity: true)
                .labelsHidden()

            Divider().frame(height: 24)

            // Stroke width
            HStack(spacing: 8) {
                Image(systemName: "lineweight")
                    .foregroundStyle(.secondary)
                Slider(value: $strokeWidth, in: 1...20, step: 0.5)
                    .frame(width: 100)
            }

            Spacer()

            // Undo / Redo
            Button {
                canvasView.undoManager?.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!(canvasView.undoManager?.canUndo ?? false))

            Button {
                canvasView.undoManager?.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!(canvasView.undoManager?.canRedo ?? false))
        }
    }

    // MARK: - Confirm

    private func confirmDrawing() {
        let drawing = canvasView.drawing
        guard !drawing.strokes.isEmpty else { return }

        let canvasSize = vm.document.template.canvasSize
        let image = drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 1.0)
        vm.addOverlayImage(image)
        dismiss()
    }
}

// MARK: - PencilKit Canvas Representable

struct SquiggleCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var activeTool: SquiggleEditorView.SquiggleTool
    @Binding var strokeColor: Color
    @Binding var strokeWidth: CGFloat
    let canvasSize: CGSize

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.contentSize = canvasSize
        canvasView.minimumZoomScale = 0.5
        canvasView.maximumZoomScale = 4.0
        canvasView.tool = makeTool()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = makeTool()
    }

    private func makeTool() -> PKTool {
        switch activeTool {
        case .pencil:
            return PKInkingTool(.pen, color: UIColor(strokeColor), width: strokeWidth)
        case .eraser:
            return PKEraserTool(.bitmap)
        }
    }
}
