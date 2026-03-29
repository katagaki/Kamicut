import SwiftUI

// MARK: - Floating Element Toolbar

/// Small liquid glass capsule toolbar centered above the main toolbar,
/// with rotate, scale, and delete controls for the selected element.
struct ElementToolbarView: View {
    @Bindable var editor: EditorState

    var body: some View {
        if let selectedID = editor.selectedImageID ?? editor.selectedTextID ?? editor.selectedShapeID,
           let layerIdx = editor.document.layers.firstIndex(where: { $0.id == selectedID }) {
            HStack(spacing: 16) {
                Button {
                    mutateLayer(at: layerIdx) { .rotate(-15) }
                } label: {
                    Image(systemName: "rotate.left")
                }

                Divider().frame(height: 24)

                Button {
                    mutateLayer(at: layerIdx) { .rotate(15) }
                } label: {
                    Image(systemName: "rotate.right")
                }

                Divider().frame(height: 24)

                Button {
                    mutateLayer(at: layerIdx) { .scale(-0.1) }
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }

                Button {
                    mutateLayer(at: layerIdx) { .scale(0.1) }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }

                Divider().frame(height: 24)

                Button(role: .destructive) {
                    withAnimation(.smooth.speed(2.0)) {
                        editor.removeLayer(id: selectedID)
                    }
                } label: {
                    Image(systemName: "trash")
                        .tint(.red)
                }
            }
            .font(.system(size: 20))
            .tint(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private enum LayerMutation {
        case rotate(CGFloat)
        case scale(CGFloat)
    }

    private func mutateLayer(at index: Int, _ mutation: () -> LayerMutation) {
        guard index < editor.document.layers.count else { return }
        switch mutation() {
        case .rotate(let degrees):
            switch editor.document.layers[index] {
            case .image(var img):
                img.rotation += degrees
                editor.document.layers[index] = .image(img)
            case .text(var txt):
                txt.rotation += degrees
                editor.document.layers[index] = .text(txt)
            case .shape(var shp):
                shp.rotation += degrees
                editor.document.layers[index] = .shape(shp)
            }
        case .scale(let delta):
            switch editor.document.layers[index] {
            case .image(var img):
                img.scale = max(0.1, img.scale + delta)
                editor.document.layers[index] = .image(img)
            case .text(var txt):
                txt.fontSize = max(4, txt.fontSize + delta * 10)
                editor.document.layers[index] = .text(txt)
            case .shape(var shp):
                shp.scale = max(0.1, shp.scale + delta)
                editor.document.layers[index] = .shape(shp)
            }
        }
    }
}
