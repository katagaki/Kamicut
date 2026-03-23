import SwiftUI

// MARK: - Space Number Editor View

struct SpaceNumberEditorView: View {
    @Binding var spaceNumber: SpaceNumberInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Space / Booth Number") {
                    TextField("e.g. 東A-01a", text: $spaceNumber.text)
                        .autocorrectionDisabled()
                }

                Section("Position") {
                    Picker("Position", selection: $spaceNumber.position) {
                        ForEach(SpaceNumberPosition.allCases, id: \.self) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Style") {
                    FontPickerRow(selectedFontName: $spaceNumber.fontName, label: "Font")
                    HStack {
                        Text("Size")
                        Spacer()
                        Stepper("\(Int(spaceNumber.fontSize)) pt", value: $spaceNumber.fontSize, in: 6...72, step: 1)
                    }
                    ColorPickerRow(title: "Color", color: $spaceNumber.color)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Space Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() }
                }
            }
        }
    }
}
