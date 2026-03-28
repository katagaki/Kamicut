import SwiftUI

// MARK: - Selected Element Inspector

/// Inline inspector panel for text and shape element properties.
/// Only appears when a text or shape element is selected.
struct SelectedElementInspectorView: View {
    @Bindable var vm: EditorState

    var body: some View {
        if let id = vm.selectedTextID,
           let layerIdx = vm.document.layers.firstIndex(where: { $0.id == id }),
           case .text = vm.document.layers[layerIdx] {
            textInspector(layerIdx: layerIdx)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let id = vm.selectedShapeID,
                  let layerIdx = vm.document.layers.firstIndex(where: { $0.id == id }),
                  case .shape = vm.document.layers[layerIdx] {
            shapeInspector(layerIdx: layerIdx)
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

    // MARK: - Shape Inspector

    private func shapeInspector(layerIdx: Int) -> some View {
        let shapeBinding = Binding<ShapeElement>(
            get: {
                if case .shape(let el) = vm.document.layers[safe: layerIdx] { return el }
                return ShapeElement()
            },
            set: { vm.document.layers[layerIdx] = .shape($0) }
        )

        return VStack(spacing: 0) {
            Divider()

            Form {
                ShapePropertiesSections(element: shapeBinding)
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
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
