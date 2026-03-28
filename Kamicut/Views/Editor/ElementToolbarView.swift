import SwiftUI

// MARK: - Floating Element Toolbar

/// Small liquid glass capsule toolbar centered above the main toolbar,
/// with rotate, scale, and delete controls for the selected element.
struct ElementToolbarView: View {
    @Bindable var vm: EditorState

    var body: some View {
        if let selectedID = vm.selectedImageID ?? vm.selectedTextID ?? vm.selectedShapeID,
           let layerIdx = vm.document.layers.firstIndex(where: { $0.id == selectedID }) {
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
                        vm.removeLayer(id: selectedID)
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
        guard index < vm.document.layers.count else { return }
        switch mutation() {
        case .rotate(let degrees):
            switch vm.document.layers[index] {
            case .image(var el):
                el.rotation += degrees
                vm.document.layers[index] = .image(el)
            case .text(var el):
                el.rotation += degrees
                vm.document.layers[index] = .text(el)
            case .shape(var el):
                el.rotation += degrees
                vm.document.layers[index] = .shape(el)
            }
        case .scale(let delta):
            switch vm.document.layers[index] {
            case .image(var el):
                el.scale = max(0.1, el.scale + delta)
                vm.document.layers[index] = .image(el)
            case .text(var el):
                el.fontSize = max(4, el.fontSize + delta * 10)
                vm.document.layers[index] = .text(el)
            case .shape(var el):
                el.scale = max(0.1, el.scale + delta)
                vm.document.layers[index] = .shape(el)
            }
        }
    }
}
