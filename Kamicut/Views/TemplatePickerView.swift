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
                Section("Predefined Templates") {
                    ForEach(CircleCutTemplate.predefined) { tmpl in
                        templateRow(tmpl)
                    }
                    templateRow(.custom)
                }

                // Canvas Size
                Section("Canvas Size (px)") {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("Width", value: $editingTemplate.canvasSize.width, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("px")
                    }
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", value: $editingTemplate.canvasSize.height, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("px")
                    }
                }

                // Border
                Section("Border") {
                    HStack {
                        Text("Outer")
                        Spacer()
                        TextField("Outer", value: $editingTemplate.outerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("px")
                    }
                    HStack {
                        Text("Inner")
                        Spacer()
                        TextField("Inner", value: $editingTemplate.innerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("px")
                    }
                }

                // Text Area
                Section("Text Area") {
                    Toggle("Enable Text Area", isOn: $editingTemplate.textAreaEnabled)
                    if editingTemplate.textAreaEnabled {
                        Picker("Position", selection: $editingTemplate.textAreaPosition) {
                            ForEach(TextAreaPosition.allCases, id: \.self) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $editingTemplate.textAreaHeight, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("px")
                        }
                        Toggle("Transparent Background", isOn: $editingTemplate.textAreaTransparent)
                    }
                }

                // Top-Left Box
                Section("Top-Left Box (Space Number)") {
                    Toggle("Enable Top-Left Box", isOn: $editingTemplate.topLeftBoxEnabled)
                    if editingTemplate.topLeftBoxEnabled {
                        HStack {
                            Text("Width")
                            Spacer()
                            TextField("Width", value: $editingTemplate.topLeftBoxSize.width, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("px")
                        }
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $editingTemplate.topLeftBoxSize.height, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("px")
                        }
                    }
                }

                // Header Font
                Section("Header Font") {
                    FontPickerRow(selectedFontName: $editingTemplate.headerFontName, label: "Font")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: { Text("Cancel") }
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
                    Text(tmpl.displayName)
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
