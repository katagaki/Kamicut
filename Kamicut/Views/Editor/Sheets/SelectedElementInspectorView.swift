import SwiftUI

// MARK: - Selected Element Inspector

/// Inline inspector panel for element properties.
/// Appears when any element (text, shape, or image) is selected.
struct SelectedElementInspectorView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isInspectorPresentation) private var isInspector
    @State private var showDeleteConfirmation = false

    private var selectedID: UUID? {
        editor.selectedTextID ?? editor.selectedShapeID ?? editor.selectedImageID
    }

    var body: some View {
        NavigationStack {
            inspectorContent
                .toolbarRole(isInspector ? .editor : .navigationStack)
                .navigationBarBackButtonHidden(isInspector)
        }
    }

    private var inspectorContent: some View {
        Group {
            if let id = editor.selectedTextID,
               let layerIdx = editor.document.layers.firstIndex(where: { $0.id == id }),
               case .text = editor.document.layers[layerIdx] {
                textInspector(layerIdx: layerIdx)
            } else if let id = editor.selectedShapeID,
                      let layerIdx = editor.document.layers.firstIndex(where: { $0.id == id }),
                      case .shape = editor.document.layers[layerIdx] {
                shapeInspector(layerIdx: layerIdx)
            } else if let id = editor.selectedImageID,
                      let layerIdx = editor.document.layers.firstIndex(where: { $0.id == id }),
                      case .image = editor.document.layers[layerIdx] {
                imageInspector(layerIdx: layerIdx)
            }
        }
        .navigationTitle(editor.selectedLayerLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) { dismiss() }
            }
        }
        .alert(String(localized: "Inspector.DeleteElement"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "Common.Delete"), role: .destructive) {
                if let id = selectedID {
                    withAnimation(.smooth.speed(2.0)) {
                        editor.removeLayer(id: id)
                    }
                    dismiss()
                }
            }
            Button(String(localized: "Common.Cancel"), role: .cancel) {}
        } message: {
            Text("Inspector.DeleteConfirmation")
        }
    }

    // MARK: - Text Inspector (inline settings list)

    private func textInspector(layerIdx: Int) -> some View {
        let textBinding = Binding<TextElement>(
            get: {
                if case .text(let txt) = editor.document.layers[safe: layerIdx] { return txt }
                return TextElement()
            },
            set: { editor.document.layers[layerIdx] = .text($0) }
        )

        return Form {
            TextPropertiesSections(element: textBinding)
        }
        .formStyle(.grouped)
        .listSectionSpacing(.compact)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Shape Inspector

    private func shapeInspector(layerIdx: Int) -> some View {
        let shapeBinding = Binding<ShapeElement>(
            get: {
                if case .shape(let shp) = editor.document.layers[safe: layerIdx] { return shp }
                return ShapeElement()
            },
            set: { editor.document.layers[layerIdx] = .shape($0) }
        )

        return Form {
            ShapePropertiesSections(element: shapeBinding)
        }
        .formStyle(.grouped)
        .listSectionSpacing(.compact)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Image Inspector

    private func imageInspector(layerIdx: Int) -> some View {
        let imageBinding = Binding<ImageElement>(
            get: {
                if case .image(let img) = editor.document.layers[safe: layerIdx] { return img }
                return ImageElement(imageData: Data())
            },
            set: { editor.document.layers[layerIdx] = .image($0) }
        )

        return Form {
            ImagePropertiesSections(element: imageBinding)
        }
        .formStyle(.grouped)
        .listSectionSpacing(.compact)
    }
}

// MARK: - Image Properties Sections

struct ImagePropertiesSections: View {
    @Binding var element: ImageElement

    var body: some View {
        // Scale
        Section(String(localized: "Common.Size")) {
            HStack {
                Text("Image.Scale")
                Spacer()
                Stepper("\(element.scale, specifier: "%.1f")×",
                        value: $element.scale, in: 0.1...10, step: 0.1)
            }
        }

        // Rotation
        Section(String(localized: "TextEditor.Rotation")) {
            HStack {
                Text("TextEditor.Angle")
                Spacer()
                Text("\(Int(element.rotation))°")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.rotation, in: -180...180, step: 1)
        }

        // Shadow
        Section(String(localized: "TextEditor.Shadow")) {
            Toggle("TextEditor.Shadow", isOn: $element.shadow.enabled.animation(.smooth.speed(2.0)))
            if element.shadow.enabled {
                ColorPickerRow(title: String(localized: "TextEditor.ShadowColor"), color: $element.shadow.color)
                HStack {
                    Text("TextEditor.Radius")
                    Spacer()
                    Stepper("\(element.shadow.radius, specifier: "%.1f")",
                            value: $element.shadow.radius, in: 0...20, step: 0.5)
                }
                HStack {
                    Text("TextEditor.OffsetX")
                    Spacer()
                    Stepper("\(element.shadow.offsetX, specifier: "%.1f")",
                            value: $element.shadow.offsetX, in: -20...20, step: 0.5)
                }
                HStack {
                    Text("TextEditor.OffsetY")
                    Spacer()
                    Stepper("\(element.shadow.offsetY, specifier: "%.1f")",
                            value: $element.shadow.offsetY, in: -20...20, step: 0.5)
                }
            }
        }
    }
}

// MARK: - Shape Properties Sections

struct ShapePropertiesSections: View {
    @Binding var element: ShapeElement

    var body: some View {
        // Shape type
        Section(String(localized: "Shape.Type")) {
            Picker(String(localized: "Shape.Type"), selection: $element.shapeKind) {
                ForEach(ShapeKind.allCases) { kind in
                    Label(kind.localizedName, systemImage: kind.systemImage)
                        .tag(kind)
                }
            }
            .pickerStyle(.menu)
        }

        // Fill
        Section(String(localized: "Shape.Fill")) {
            ColorPickerRow(title: String(localized: "Shape.FillColor"), color: $element.fillColor)
        }

        // Stroke
        Section(String(localized: "Shape.Stroke")) {
            ColorPickerRow(title: String(localized: "Shape.StrokeColor"), color: $element.strokeColor)
            HStack {
                Text("Common.Width")
                Spacer()
                Stepper("\(element.strokeWidth, specifier: "%.1f") pt",
                        value: $element.strokeWidth, in: 0...20, step: 0.5)
            }
        }

        // Size
        Section(String(localized: "Common.Size")) {
            HStack {
                Text("Common.Width")
                Spacer()
                TextField("Common.Width", value: $element.size.width, format: FloatingPointFormatStyle<CGFloat>())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            HStack {
                Text("Common.Height")
                Spacer()
                TextField("Common.Height", value: $element.size.height, format: FloatingPointFormatStyle<CGFloat>())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
        }

        // Rotation
        Section(String(localized: "TextEditor.Rotation")) {
            HStack {
                Text("TextEditor.Angle")
                Spacer()
                Text("\(Int(element.rotation))\u{00B0}")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.rotation, in: -180...180, step: 1)
        }
    }
}
