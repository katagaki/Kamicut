import SwiftUI

// MARK: - Selected Element Inspector

/// Inline inspector panel for text element properties.
/// Only appears when a text element is selected.
struct SelectedElementInspectorView: View {
    @Bindable var vm: EditorState

    var body: some View {
        if let id = vm.selectedTextID,
           let layerIdx = vm.document.layers.firstIndex(where: { $0.id == id }),
           case .text = vm.document.layers[layerIdx] {
            textInspector(layerIdx: layerIdx)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Text Inspector (inline settings list)

    private func textInspector(layerIdx: Int) -> some View {
        let textBinding = Binding<TextElement>(
            get: {
                if case .text(let el) = vm.document.layers[safe: layerIdx] { return el }
                return TextElement()
            },
            set: { vm.document.layers[layerIdx] = .text($0) }
        )

        return VStack(spacing: 0) {
            Divider()

            Form {
                TextPropertiesSections(element: textBinding)
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
