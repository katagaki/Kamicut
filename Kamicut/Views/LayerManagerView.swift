import SwiftUI

// MARK: - Layer Manager View

struct LayerManagerView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Layers in reverse order (top layer first)
                ForEach(Array(vm.document.layers.enumerated().reversed()), id: \.element.id) { index, layer in
                    layerRow(layer: layer, index: index)
                }
                .onMove { source, destination in
                    // Convert reversed indices back to actual indices
                    let count = vm.document.layers.count
                    let actualSource = IndexSet(source.map { count - 1 - $0 })
                    let actualDestination = count - destination
                    vm.moveLayers(from: actualSource, to: actualDestination)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "Layers.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private func layerRow(layer: CanvasLayer, index: Int) -> some View {
        let isSelected: Bool = {
            switch layer {
            case .image: return vm.selectedImageID == layer.id
            case .text: return vm.selectedTextID == layer.id
            }
        }()

        return Button {
            vm.selectLayer(id: layer.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: layer.systemImage)
                    .frame(width: 24)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                Text(layer.label)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                vm.removeLayer(id: layer.id)
            } label: {
                Label("Common.Delete", systemImage: "trash")
            }
        }
    }
}
