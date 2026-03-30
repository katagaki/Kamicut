import SwiftUI

// MARK: - Project Settings View

/// Shows document-level settings: circle info, space number, canvas size, and layout.
struct ProjectSettingsView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Circle Info
                Section(String(localized: "Document.CircleInfo")) {
                    TextField(String(localized: "Document.CircleName"), text: $editor.document.circleName)
                        .autocorrectionDisabled()
                    TextField(String(localized: "SpaceNumber.Placeholder"), text: $editor.document.spaceNumber.text)
                        .autocorrectionDisabled()
                }

                // Space Number Style
                Section(String(localized: "SpaceNumber.Style")) {
                    Picker(String(localized: "Common.Position"), selection: $editor.document.spaceNumber.position) {
                        ForEach(SpaceNumberPosition.allCases, id: \.self) { pos in
                            Text(pos.localizedName).tag(pos)
                        }
                    }
                    FontPickerRow(
                        selectedFontName: $editor.document.spaceNumber.fontName,
                        label: String(localized: "Common.Font")
                    )
                    HStack {
                        Text("Common.Size")
                        Spacer()
                        Stepper(
                            "\(Int(editor.document.spaceNumber.fontSize)) pt",
                            value: $editor.document.spaceNumber.fontSize,
                            in: 6...72, step: 1
                        )
                    }
                    ColorPickerRow(title: String(localized: "Common.Color"), color: $editor.document.spaceNumber.color)
                }

                // Canvas Size
                Section(String(localized: "Project.CanvasSize")) {
                    HStack {
                        Text("Common.Width")
                        Spacer()
                        TextField(
                            "Common.Width",
                            value: $editor.document.template.canvasSize.width,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    HStack {
                        Text("Common.Height")
                        Spacer()
                        TextField(
                            "Common.Height",
                            value: $editor.document.template.canvasSize.height,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Outer Outline
                Section(String(localized: "Layers.OuterOutline")) {
                    HStack {
                        Text(String(localized: "Layers.Thickness"))
                        Spacer()
                        TextField(
                            String(localized: "Layers.Thickness"),
                            value: $editor.document.template.outerBorderThickness,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Inner Outline
                Section(String(localized: "Layers.InnerOutline")) {
                    HStack {
                        Text(String(localized: "Layers.Thickness"))
                        Spacer()
                        TextField(
                            String(localized: "Layers.Thickness"),
                            value: $editor.document.template.innerBorderThickness,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Checkbox Area
                Section(String(localized: "Layers.CheckboxArea")) {
                    Toggle(
                        String(localized: "Layers.CheckboxArea.Enabled"),
                        isOn: $editor.document.template.checkboxAreaEnabled
                    )
                    if editor.document.template.checkboxAreaEnabled {
                        HStack {
                            Text("Common.Width")
                            Spacer()
                            TextField(
                                "Common.Width",
                                value: $editor.document.template.checkboxAreaSize.width,
                                format: FloatingPointFormatStyle<CGFloat>()
                            )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        HStack {
                            Text("Common.Height")
                            Spacer()
                            TextField(
                                "Common.Height",
                                value: $editor.document.template.checkboxAreaSize.height,
                                format: FloatingPointFormatStyle<CGFloat>()
                            )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    }
                }

                // Text Area
                Section(String(localized: "Layers.TextArea")) {
                    Toggle(
                        String(localized: "Layers.TextArea.Enabled"),
                        isOn: $editor.document.template.textAreaEnabled
                    )
                    if editor.document.template.textAreaEnabled {
                        Picker(
                        String(localized: "Common.Position"),
                        selection: $editor.document.template.textAreaPosition
                    ) {
                            ForEach(TextAreaPosition.allCases, id: \.self) { pos in
                                Text(pos.localizedName).tag(pos)
                            }
                        }
                        HStack {
                            Text("Common.Height")
                            Spacer()
                            TextField(
                                "Common.Height",
                                value: $editor.document.template.textAreaHeight,
                                format: FloatingPointFormatStyle<CGFloat>()
                            )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        Toggle(
                            String(localized: "Layers.TextArea.Transparent"),
                            isOn: $editor.document.template.textAreaTransparent
                        )
                    }
                }
            }
            .listSectionSpacing(.compact)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "Document.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) { dismiss() }
                }
            }
        }
    }
}
