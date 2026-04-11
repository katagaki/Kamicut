import SwiftUI
import PhotosUI

// MARK: - Layer Manager View

struct LayerManagerView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isInspectorPresentation) private var isInspector

    // Background settings state
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var backgroundColor: Color = .white
    @State private var hasBackgroundColor: Bool = false

    // Rename state
    @State private var renamingLayerID: UUID?
    @State private var renameText: String = ""
    @FocusState private var renameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            layerContent
                .navigationBarBackButtonHidden(isInspector)
        }
        .onAppear { loadBackgroundState() }
    }

    private var layerContent: some View {
        List {
                // User layers (reorderable)
                Section {
                    if editor.document.layers.isEmpty {
                        Text(String(localized: "Layers.Empty.Description"))
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(
                            Array(editor.document.layers.enumerated().reversed()),
                            id: \.element.id
                        ) { index, layer in
                            elementRow(layer: layer, index: index)
                        }
                        .onMove { source, destination in
                            let count = editor.document.layers.count
                            let actualSource = IndexSet(source.map { count - 1 - $0 })
                            let actualDestination = count - destination
                            editor.moveLayers(from: actualSource, to: actualDestination)
                        }
                    }
                } header: {
                    HStack {
                        Text(String(localized: "Layers.Elements"))
                        Spacer()
                        if !editor.document.layers.isEmpty {
                            EditButton()
                                .textCase(nil)
                        }
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

    private func loadBackgroundState() {
        if let existing = editor.document.backgroundColor {
            hasBackgroundColor = true
            backgroundColor = existing.color
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
            elementRowLabel(layer: layer, isSelected: isSelected)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                editor.removeLayer(id: layer.id)
            } label: {
                Label("Common.Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                renameText = layer.customName ?? ""
                renamingLayerID = layer.id
            } label: {
                Label(String(localized: "Common.Rename"), systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private func elementRowLabel(layer: CanvasLayer, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            layerPreview(layer: layer)

            if renamingLayerID == layer.id {
                TextField(layer.label, text: $renameText)
                    .textFieldStyle(.plain)
                    .tint(.primary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .onSubmit {
                        editor.renameLayer(id: layer.id, name: renameText)
                        renamingLayerID = nil
                    }
                    .focused($renameFieldFocused)
                    .onAppear { renameFieldFocused = true }
            } else {
                Text(layer.label)
                    .tint(.primary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
            }
        }
    }

    // MARK: - Layer Preview

    @ViewBuilder
    private func layerPreview(layer: CanvasLayer) -> some View {
        Canvas { context, size in
            let cellSize: CGFloat = 8
            let cols = Int(ceil(size.width / cellSize))
            let rows = Int(ceil(size.height / cellSize))
            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col).isMultiple(of: 2)
                    context.fill(
                        Path(CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )),
                        with: .color(isLight ? Color(.systemGray6) : Color(.systemGray5))
                    )
                }
            }
        }
        .frame(width: 32, height: 32)
        .overlay {
            layerPreviewContent(layer: layer)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private func layerPreviewContent(layer: CanvasLayer) -> some View {
        switch layer {
        case .image(let img):
            if let uiImage = img.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(2)
                    .rotationEffect(.degrees(img.rotation))
            }
        case .text(let txt):
            let display = txt.content.isEmpty ? "T" : String(txt.content.prefix(2))
            Text(display)
                .font(.custom(txt.fontName, size: 16))
                .foregroundStyle(txt.color.color)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .padding(2)
                .rotationEffect(.degrees(txt.rotation))
        case .shape(let shp):
            shapePreview(element: shp)
                .padding(4)
                .rotationEffect(.degrees(shp.rotation))
        }
    }

    @ViewBuilder
    private func shapePreview(element: ShapeElement) -> some View {
        let fill = element.fillColor.color
        let stroke = element.strokeColor.color
        let lineWidth = max(element.strokeWidth * 0.3, 0.5)

        switch element.shapeKind {
        case .square, .rectangle:
            Rectangle()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .circle:
            Circle()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .ellipse:
            Ellipse()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .star:
            StarShape()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .pentagon:
            PolygonShape(sides: 5)
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .hexagon:
            PolygonShape(sides: 6)
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
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
