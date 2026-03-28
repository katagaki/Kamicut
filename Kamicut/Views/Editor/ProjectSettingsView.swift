import SwiftUI

// MARK: - Project Settings View

/// Shows document-level settings: circle info, space number, canvas size, and layout.
struct ProjectSettingsView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Circle Info
                Section(String(localized: "Document.CircleInfo")) {
                    TextField(String(localized: "Document.CircleName"), text: $vm.document.circleName)
                        .autocorrectionDisabled()
                    TextField(String(localized: "SpaceNumber.Placeholder"), text: $vm.document.spaceNumber.text)
                        .autocorrectionDisabled()
                }

                // Space Number Style
                Section(String(localized: "SpaceNumber.Style")) {
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
                }

                // Canvas Size
                Section(String(localized: "Project.CanvasSize")) {
                    HStack {
                        Text("Common.Width")
                        Spacer()
                        TextField("Common.Width", value: $vm.document.template.canvasSize.width, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                    HStack {
                        Text("Common.Height")
                        Spacer()
                        TextField("Common.Height", value: $vm.document.template.canvasSize.height, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Checkbox Area
                Section(String(localized: "Layers.CheckboxArea")) {
                    Toggle(String(localized: "Layers.CheckboxArea.Enabled"), isOn: $vm.document.template.checkboxAreaEnabled)
                    if vm.document.template.checkboxAreaEnabled {
                        HStack {
                            Text("Common.Width")
                            Spacer()
                            TextField("Common.Width", value: $vm.document.template.checkboxAreaSize.width, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                        HStack {
                            Text("Common.Height")
                            Spacer()
                            TextField("Common.Height", value: $vm.document.template.checkboxAreaSize.height, format: FloatingPointFormatStyle<CGFloat>())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("Common.Px")
                        }
                    }
                }

                // Outer Outline
                Section(String(localized: "Layers.OuterOutline")) {
                    HStack {
                        Text(String(localized: "Layers.Thickness"))
                        Spacer()
                        TextField(String(localized: "Layers.Thickness"), value: $vm.document.template.outerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
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
                        TextField(String(localized: "Layers.Thickness"), value: $vm.document.template.innerBorderThickness, format: FloatingPointFormatStyle<CGFloat>())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("Common.Px")
                    }
                }

                // Text Area
                Section(String(localized: "Layers.TextArea")) {
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
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "Document.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button(String(localized: "Common.Close")) { dismiss() }
                    }
                }
            }
        }
    }
}
