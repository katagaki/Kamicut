import SwiftUI
import PhotosUI

// MARK: - Layer Manager View

struct LayerManagerView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss

    // Background settings state
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var backgroundColor: Color = .white
    @State private var hasBackgroundColor: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // User layers (reorderable)
                Section {
                    ForEach(Array(editor.document.layers.enumerated().reversed()), id: \.element.id) { index, layer in
                        elementRow(layer: layer, index: index)
                    }
                    .onMove { source, destination in
                        let count = editor.document.layers.count
                        let actualSource = IndexSet(source.map { count - 1 - $0 })
                        let actualDestination = count - destination
                        editor.moveLayers(from: actualSource, to: actualDestination)
                    }
                } header: {
                    HStack {
                        Text(String(localized: "Layers.Elements"))
                        Spacer()
                        EditButton()
                            .textCase(nil)
                    }
                }

                // Background (bottom-most)
                Section {
                    DisclosureGroup {
                        // Color
                        Toggle(
                            String(localized: "Toolbar.Background.SetColor"),
                            isOn: $hasBackgroundColor.animation(.smooth.speed(2.0))
                        )
                            .onChange(of: hasBackgroundColor) { _, enabled in
                                if enabled {
                                    editor.setBackgroundColor(backgroundColor)
                                } else {
                                    editor.removeBackgroundColor()
                                }
                            }
                        if hasBackgroundColor {
                            ColorPicker(String(localized: "Common.Color"), selection: $backgroundColor)
                                .onChange(of: backgroundColor) { _, newColor in
                                    editor.setBackgroundColor(newColor)
                                }
                        }

                        // Image
                        PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                            Label(String(localized: "Toolbar.Background.SelectImage"), systemImage: "photo")
                        }
                        .onChange(of: backgroundPickerItem) { _, item in
                            Task { await loadBackgroundImage(item: item) }
                        }
                        if editor.document.backgroundImage != nil {
                            Button(role: .destructive) {
                                editor.removeBackgroundImage()
                            } label: {
                                Label(String(localized: "Common.Delete"), systemImage: "trash")
                            }
                        }

                        // Bleed
                        Picker(String(localized: "Toolbar.Background.Bleed"), selection: $editor.document.bleedOption) {
                            ForEach(BleedOption.allCases, id: \.self) { option in
                                Text(option.localizedName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    } label: {
                        fixedLayerLabel(
                            systemImage: "photo.artframe",
                            label: String(localized: "Layers.Background"),
                            enabled: true
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle(String(localized: "Layers.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) { dismiss() }
                }
            }
        }
        .onAppear {
            if let existing = editor.document.backgroundColor {
                hasBackgroundColor = true
                backgroundColor = existing.color
            }
        }
    }

    // MARK: - Fixed Layer Label

    private func fixedLayerLabel(systemImage: String, label: String, enabled: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 24)
                .foregroundStyle(enabled ? .primary : .tertiary)

            Text(label)
                .foregroundStyle(enabled ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Element Row

    private func elementRow(layer: CanvasLayer, index: Int) -> some View {
        let isSelected: Bool = {
            switch layer {
            case .image: return editor.selectedImageID == layer.id
            case .text: return editor.selectedTextID == layer.id
            case .shape: return editor.selectedShapeID == layer.id
            }
        }()

        return Button {
            editor.selectLayer(id: layer.id)
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
                editor.removeLayer(id: layer.id)
            } label: {
                Label("Common.Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func loadBackgroundImage(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        editor.setBackgroundImage(image)
    }
}
