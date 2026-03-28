import SwiftUI

// MARK: - Layer Manager View

struct LayerManagerView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Fixed layers: top to bottom rendering order (topmost first)

                // Space Number (topmost fixed layer)
                Section {
                    fixedLayerRow(
                        systemImage: "number.square",
                        label: String(localized: "Layers.SpaceNumber"),
                        enabled: !vm.document.spaceNumber.text.isEmpty
                    ) {
                        vm.showSpaceNumberEditor = true
                        dismiss()
                    }
                }

                // Top Left Box
                if vm.document.template.topLeftBoxEnabled {
                    Section {
                        fixedLayerRow(
                            systemImage: "square.tophalf.filled",
                            label: String(localized: "Layers.TopLeftBox"),
                            enabled: true
                        ) {
                            vm.showTemplatePicker = true
                            dismiss()
                        }
                    }
                }

                // Outer Outline
                Section {
                    fixedLayerRow(
                        systemImage: "square",
                        label: String(localized: "Layers.OuterOutline"),
                        enabled: vm.document.template.outerBorderThickness > 0
                    ) {
                        vm.showTemplatePicker = true
                        dismiss()
                    }
                }

                // Inner Outline
                Section {
                    fixedLayerRow(
                        systemImage: "square.dashed",
                        label: String(localized: "Layers.InnerOutline"),
                        enabled: vm.document.template.innerBorderThickness > 0
                    ) {
                        vm.showTemplatePicker = true
                        dismiss()
                    }
                }

                // Text Area
                if vm.document.template.textAreaEnabled {
                    Section {
                        fixedLayerRow(
                            systemImage: "text.below.photo",
                            label: String(localized: "Layers.TextArea"),
                            enabled: true
                        ) {
                            vm.showTemplatePicker = true
                            dismiss()
                        }
                    }
                }

                // User layers (reorderable)
                Section(String(localized: "Layers.Elements")) {
                    ForEach(Array(vm.document.layers.enumerated().reversed()), id: \.element.id) { index, layer in
                        elementRow(layer: layer, index: index)
                    }
                    .onMove { source, destination in
                        let count = vm.document.layers.count
                        let actualSource = IndexSet(source.map { count - 1 - $0 })
                        let actualDestination = count - destination
                        vm.moveLayers(from: actualSource, to: actualDestination)
                    }
                }

                // Background (bottom-most)
                Section {
                    fixedLayerRow(
                        systemImage: "photo.artframe",
                        label: String(localized: "Layers.Background"),
                        enabled: vm.document.backgroundColor != nil || vm.document.backgroundImage != nil
                    ) {
                        vm.showBackgroundSettings = true
                        dismiss()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "Layers.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button(String(localized: "Common.Close")) { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    // MARK: - Fixed Layer Row

    private func fixedLayerRow(systemImage: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 24)
                    .foregroundStyle(enabled ? .primary : .tertiary)

                Text(label)
                    .foregroundStyle(enabled ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .tint(.primary)
    }

    // MARK: - Element Row

    private func elementRow(layer: CanvasLayer, index: Int) -> some View {
        let isSelected: Bool = {
            switch layer {
            case .image: return vm.selectedImageID == layer.id
            case .text: return vm.selectedTextID == layer.id
            case .shape: return vm.selectedShapeID == layer.id
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
