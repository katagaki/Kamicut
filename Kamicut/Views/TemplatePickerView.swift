import SwiftUI

// MARK: - Template Picker View

struct TemplatePickerView: View {
    var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    @State private var editingTemplate: CircleCutTemplate

    init(vm: EditorState) {
        self.vm = vm
        _editingTemplate = State(initialValue: vm.document.template)
    }

    var body: some View {
        NavigationStack {
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
                        TextField("Common.Width", value: $editingTemplate.canvasSize.width, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    HStack {
                        Text("Common.Height")
                        Spacer()
                        TextField("Common.Height", value: $editingTemplate.canvasSize.height, format: FloatingPointFormatStyle<CGFloat>())
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
                        TextField("Template.Outer", value: $editingTemplate.outerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    HStack {
                        Text("Template.Inner")
                        Spacer()
                        TextField("Template.Inner", value: $editingTemplate.innerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
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
                            TextField("Common.Height", value: $editingTemplate.textAreaHeight, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        Toggle("Template.TransparentBackground", isOn: $editingTemplate.textAreaTransparent)
                    }
                }

                // Top-Left Box
                Section("Template.TopLeftBox") {
                    Toggle("Template.EnableTopLeftBox", isOn: $editingTemplate.topLeftBoxEnabled)
                    if editingTemplate.topLeftBoxEnabled {
                        HStack {
                            Text("Common.Width")
                            Spacer()
                            TextField("Common.Width", value: $editingTemplate.topLeftBoxSize.width, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        HStack {
                            Text("Common.Height")
                            Spacer()
                            TextField("Common.Height", value: $editingTemplate.topLeftBoxSize.height, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    }
                }

                // Header Font
                Section("Template.HeaderFont") {
                    FontPickerRow(selectedFontName: $editingTemplate.headerFontName, label: String(localized: "Common.Font"))
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "Toolbar.Template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: { Text("Common.Cancel") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        vm.document.template = editingTemplate
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
