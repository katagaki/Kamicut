import SwiftUI

// MARK: - Inline Text Properties List

/// Inline settings-style list for editing a text element's properties.
/// Embed this directly in a `List` or `Form` — it emits sections.
struct TextPropertiesSections: View {
    @Binding var element: TextElement

    var body: some View {
        // Content
        Section("Content") {
            TextField("Text", text: $element.content, axis: .vertical)
                .lineLimit(1...5)
        }

        // Font & Size
        Section("Font") {
            FontPickerRow(selectedFontName: $element.fontName, label: "Font")
            HStack {
                Text("Size")
                Spacer()
                TextField("Size", value: $element.fontSize, format: FloatingPointFormatStyle<CGFloat>())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("px")
                    .foregroundStyle(.secondary)
                Stepper("", value: $element.fontSize, in: 1...999, step: 1)
                    .labelsHidden()
            }
        }

        // Color
        Section("Color") {
            ColorPickerRow(title: "Text Color", color: $element.color)
        }

        // Outline
        Section("Outline") {
            Toggle("Outline", isOn: $element.outline.enabled.animation(.smooth.speed(2.0)))
            if element.outline.enabled {
                ColorPickerRow(title: "Outline Color", color: $element.outline.color)
                HStack {
                    Text("Width")
                    Spacer()
                    Stepper("\(element.outline.width, specifier: "%.1f") pt",
                            value: $element.outline.width, in: 0.5...10, step: 0.5)
                }
            }
        }

        // Shadow
        Section("Shadow") {
            Toggle("Shadow", isOn: $element.shadow.enabled.animation(.smooth.speed(2.0)))
            if element.shadow.enabled {
                ColorPickerRow(title: "Shadow Color", color: $element.shadow.color)
                HStack {
                    Text("Radius")
                    Spacer()
                    Stepper("\(element.shadow.radius, specifier: "%.1f")",
                            value: $element.shadow.radius, in: 0...20, step: 0.5)
                }
                HStack {
                    Text("Offset X")
                    Spacer()
                    Stepper("\(element.shadow.offsetX, specifier: "%.1f")",
                            value: $element.shadow.offsetX, in: -20...20, step: 0.5)
                }
                HStack {
                    Text("Offset Y")
                    Spacer()
                    Stepper("\(element.shadow.offsetY, specifier: "%.1f")",
                            value: $element.shadow.offsetY, in: -20...20, step: 0.5)
                }
            }
        }

        // Rotation
        Section("Rotation") {
            HStack {
                Text("Angle")
                Spacer()
                Text("\(Int(element.rotation))°")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.rotation, in: -180...180, step: 1)
        }
    }
}

// MARK: - Font Picker Row

struct FontPickerRow: View {
    @Binding var selectedFontName: String
    let label: String

    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Text(displayName(for: selectedFontName))
                    .font(.custom(selectedFontName, size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .tint(.primary)
        .sheet(isPresented: $showPicker) {
            FontPickerSheet(selectedFontName: $selectedFontName)
                .presentationDetents([.height(200), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
    }

    private func displayName(for fontName: String) -> String {
        if let font = UIFont(name: fontName, size: 12) {
            return font.familyName + " " + styleName(from: fontName, family: font.familyName)
        }
        return fontName
    }

    private func styleName(from fontName: String, family: String) -> String {
        let stripped = fontName
            .replacingOccurrences(of: family.replacingOccurrences(of: " ", with: ""), with: "")
            .replacingOccurrences(of: "-", with: "")
        return stripped.isEmpty ? "Regular" : stripped
    }
}

// MARK: - Font Picker Sheet

struct FontPickerSheet: View {
    @Binding var selectedFontName: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var fontFamilies: [(family: String, fonts: [String])] {
        UIFont.familyNames.sorted().compactMap { family in
            let fonts = UIFont.fontNames(forFamilyName: family).sorted()
            guard !fonts.isEmpty else { return nil }
            return (family: family, fonts: fonts)
        }
    }

    private var filteredFamilies: [(family: String, fonts: [String])] {
        if searchText.isEmpty { return fontFamilies }
        return fontFamilies.filter { $0.family.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFamilies, id: \.family) { family in
                    Section(family.family) {
                        ForEach(family.fonts, id: \.self) { fontName in
                            Button {
                                selectedFontName = fontName
                                dismiss()
                            } label: {
                                HStack {
                                    Text(styleName(from: fontName, family: family.family))
                                        .font(.custom(fontName, size: 17))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedFontName == fontName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search fonts")
            .navigationTitle("Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() }
                }
            }
        }
    }

    private func styleName(from fontName: String, family: String) -> String {
        let stripped = fontName
            .replacingOccurrences(of: family.replacingOccurrences(of: " ", with: ""), with: "")
            .replacingOccurrences(of: "-", with: "")
        return stripped.isEmpty ? "Regular" : stripped
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    let title: String
    @Binding var color: CodableColor

    var body: some View {
        ColorPicker(title, selection: Binding(
            get: { color.color },
            set: { color = CodableColor(color: $0) }
        ))
    }
}
