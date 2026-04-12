import SwiftUI

// MARK: - Template Picker View

struct TemplatePickerView: View {
    var editor: EditorState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isInspectorPresentation) private var isInspector

    @State private var editingTemplate: CircleCutTemplate

    init(editor: EditorState) {
        self.editor = editor
        _editingTemplate = State(initialValue: editor.document.template)
    }

    var body: some View {
        if isInspector {
            templateContent
                .onChange(of: editingTemplate) { _, newValue in
                    editor.document.template = newValue
                }
        } else {
            NavigationStack {
                templateContent
                    .toolbarRole(.navigationStack)
            }
        }
    }

    private var templateContent: some View {
        Form {
                // Predefined templates
                Section("Template.PredefinedTemplates") {
                    ForEach(CircleCutTemplate.predefined) { tmpl in
                        templateRow(tmpl)
                    }
                    templateRow(.custom)
                }

                // Canvas Size
                Section("Template.CanvasSize") {
                    HStack {
                        Text("Common.Width")
                        Spacer()
                        TextField(
                            "Common.Width",
                            value: $editingTemplate.canvasSize.width,
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
                            value: $editingTemplate.canvasSize.height,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Border
                Section("Template.Border") {
                    HStack {
                        Text("Template.Outer")
                        Spacer()
                        TextField(
                            "Template.Outer",
                            value: $editingTemplate.outerBorderThickness,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    ColorPickerRow(
                        title: String(localized: "Common.Color"),
                        color: $editingTemplate.outerBorderColor
                    )
                    HStack {
                        Text("Template.Inner")
                        Spacer()
                        TextField(
                            "Template.Inner",
                            value: $editingTemplate.innerBorderThickness,
                            format: FloatingPointFormatStyle<CGFloat>()
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    ColorPickerRow(
                        title: String(localized: "Common.Color"),
                        color: $editingTemplate.innerBorderColor
                    )
                }

                // Text Area
                Section("Template.TextArea") {
                    Toggle("Template.EnableTextArea", isOn: $editingTemplate.textAreaEnabled)
                    if editingTemplate.textAreaEnabled {
                        Picker("Common.Position", selection: $editingTemplate.textAreaPosition) {
                            ForEach(TextAreaPosition.allCases, id: \.self) { pos in
                                Text(pos.localizedName).tag(pos)
                            }
                        }
                        HStack {
                            Text("Common.Height")
                            Spacer()
                            TextField(
                                "Common.Height",
                                value: $editingTemplate.textAreaHeight,
                                format: FloatingPointFormatStyle<CGFloat>()
                            )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        Toggle("Template.TransparentBackground", isOn: $editingTemplate.textAreaTransparent)
                    }
                }

                // Checkbox Area
                Section("Template.CheckboxArea") {
                    Toggle("Template.EnableCheckboxArea", isOn: $editingTemplate.checkboxAreaEnabled)
                    if editingTemplate.checkboxAreaEnabled {
                        HStack {
                            Text("Common.Width")
                            Spacer()
                            TextField(
                                "Common.Width",
                                value: $editingTemplate.checkboxAreaSize.width,
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
                                value: $editingTemplate.checkboxAreaSize.height,
                                format: FloatingPointFormatStyle<CGFloat>()
                            )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    }
                }

                // Header Font
                Section("Template.HeaderFont") {
                    FontPickerRow(
                        selectedFontName: $editingTemplate.headerFontName,
                        label: String(localized: "Common.Font")
                    )
                }
            }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(String(localized: "Toolbar.Template"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26, *) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                } else {
                    Button(String(localized: "Common.Cancel")) {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26, *) {
                    Button(role: .confirm) {
                        editor.document.template = editingTemplate
                        dismiss()
                    }
                } else {
                    Button(String(localized: "Common.Close")) {
                        editor.document.template = editingTemplate
                        dismiss()
                    }
                }
            }
        }
    }

    private func templateRow(_ tmpl: CircleCutTemplate) -> some View {
        Button {
            editingTemplate = tmpl
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tmpl.localizedDisplayName)
                        .foregroundColor(.primary)
                    Text("\(Int(tmpl.canvasSize.width))×\(Int(tmpl.canvasSize.height))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if editingTemplate.name == tmpl.name {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
