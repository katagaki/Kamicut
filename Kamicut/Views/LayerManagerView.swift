import SwiftUI
import PhotosUI

// MARK: - Layer Manager View

struct LayerManagerView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    // Background settings state
    @State private var backgroundPickerItem: PhotosPickerItem? = nil
    @State private var backgroundColor: Color = .white
    @State private var hasBackgroundColor: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Fixed layers: top to bottom rendering order (topmost first)

                // Space Number (topmost fixed layer)
                Section {
                    DisclosureGroup {
                        TextField(String(localized: "SpaceNumber.Placeholder"), text: $vm.document.spaceNumber.text)
                            .autocorrectionDisabled()
                        Picker(String(localized: "Common.Position"), selection: $vm.document.spaceNumber.position) {
                            ForEach(SpaceNumberPosition.allCases, id: \.self) { pos in
                                Text(pos.localizedName).tag(pos)
                            }
                        }
                        FontPickerRow(selectedFontName: $vm.document.spaceNumber.fontName, label: String(localized: "Common.Font"))
                        HStack {
                            Text("Common.Size")
                            Spacer()
                            Stepper("\(Int(vm.document.spaceNumber.fontSize)) pt", value: $vm.document.spaceNumber.fontSize, in: 6...72, step: 1)
                        }
                        ColorPickerRow(title: String(localized: "Common.Color"), color: $vm.document.spaceNumber.color)
                    } label: {
                        fixedLayerLabel(
                            systemImage: "number.square",
                            label: String(localized: "Layers.SpaceNumber"),
                            enabled: !vm.document.spaceNumber.text.isEmpty
                        )
                    }
                }

                // Top Left Box
                Section {
                    DisclosureGroup {
                        Toggle(String(localized: "Layers.TopLeftBox.Enabled"), isOn: $vm.document.template.topLeftBoxEnabled)
                        if vm.document.template.topLeftBoxEnabled {
                            HStack {
                                Text("Common.Width")
                                Spacer()
                                TextField("Common.Width", value: $vm.document.template.topLeftBoxSize.width, format: FloatingPointFormatStyle<CGFloat>())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("Common.Px")
                            }
                            HStack {
                                Text("Common.Height")
                                Spacer()
                                TextField("Common.Height", value: $vm.document.template.topLeftBoxSize.height, format: FloatingPointFormatStyle<CGFloat>())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("Common.Px")
                            }
                        }
                    } label: {
                        fixedLayerLabel(
                            systemImage: "square.tophalf.filled",
                            label: String(localized: "Layers.TopLeftBox"),
                            enabled: vm.document.template.topLeftBoxEnabled
                        )
                    }
                }

                // Outer Outline
                Section {
                    DisclosureGroup {
                        HStack {
                            Text(String(localized: "Layers.Thickness"))
                            Spacer()
                            TextField(String(localized: "Layers.Thickness"), value: $vm.document.template.outerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    } label: {
                        fixedLayerLabel(
                            systemImage: "square",
                            label: String(localized: "Layers.OuterOutline"),
                            enabled: vm.document.template.outerBorderThickness > 0
                        )
                    }
                }

                // Inner Outline
                Section {
                    DisclosureGroup {
                        HStack {
                            Text(String(localized: "Layers.Thickness"))
                            Spacer()
                            TextField(String(localized: "Layers.Thickness"), value: $vm.document.template.innerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    } label: {
                        fixedLayerLabel(
                            systemImage: "square.dashed",
                            label: String(localized: "Layers.InnerOutline"),
                            enabled: vm.document.template.innerBorderThickness > 0
                        )
                    }
                }

                // Text Area
                Section {
                    DisclosureGroup {
                        Toggle(String(localized: "Layers.TextArea.Enabled"), isOn: $vm.document.template.textAreaEnabled)
                        if vm.document.template.textAreaEnabled {
                            Picker(String(localized: "Common.Position"), selection: $vm.document.template.textAreaPosition) {
                                ForEach(TextAreaPosition.allCases, id: \.self) { pos in
                                    Text(pos.localizedName).tag(pos)
                                }
                            }
                            HStack {
                                Text("Common.Height")
                                Spacer()
                                TextField("Common.Height", value: $vm.document.template.textAreaHeight, format: FloatingPointFormatStyle<CGFloat>())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("Common.Px")
                            }
                            Toggle(String(localized: "Layers.TextArea.Transparent"), isOn: $vm.document.template.textAreaTransparent)
                        }
                    } label: {
                        fixedLayerLabel(
                            systemImage: "text.below.photo",
                            label: String(localized: "Layers.TextArea"),
                            enabled: vm.document.template.textAreaEnabled
                        )
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
                    DisclosureGroup {
                        // Color
                        Toggle(String(localized: "Toolbar.Background.SetColor"), isOn: $hasBackgroundColor.animation(.smooth.speed(2.0)))
                            .onChange(of: hasBackgroundColor) { _, enabled in
                                if enabled {
                                    vm.setBackgroundColor(backgroundColor)
                                } else {
                                    vm.removeBackgroundColor()
                                }
                            }
                        if hasBackgroundColor {
                            ColorPicker(String(localized: "Common.Color"), selection: $backgroundColor)
                                .onChange(of: backgroundColor) { _, newColor in
                                    vm.setBackgroundColor(newColor)
                                }
                        }

                        // Image
                        PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                            Label(String(localized: "Toolbar.Background.SelectImage"), systemImage: "photo")
                        }
                        .onChange(of: backgroundPickerItem) { _, item in
                            Task { await loadBackgroundImage(item: item) }
                        }
                        if vm.document.backgroundImage != nil {
                            Button(role: .destructive) {
                                vm.removeBackgroundImage()
                            } label: {
                                Label(String(localized: "Common.Delete"), systemImage: "trash")
                            }
                        }

                        // Bleed
                        Picker(String(localized: "Toolbar.Background.Bleed"), selection: $vm.document.bleedOption) {
                            ForEach(BleedOption.allCases, id: \.self) { option in
                                Text(option.localizedName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    } label: {
                        fixedLayerLabel(
                            systemImage: "photo.artframe",
                            label: String(localized: "Layers.Background"),
                            enabled: vm.document.backgroundColor != nil || vm.document.backgroundImage != nil
                        )
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
        .onAppear {
            if let existing = vm.document.backgroundColor {
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

    // MARK: - Helpers

    private func loadBackgroundImage(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        vm.setBackgroundImage(image)
    }
}
