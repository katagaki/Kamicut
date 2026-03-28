import SwiftUI

// MARK: - Space Number Editor View

struct SpaceNumberEditorView: View {
    @Binding var spaceNumber: SpaceNumberInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("SpaceNumber.BoothNumber") {
                    TextField(String(localized: "SpaceNumber.Placeholder"), text: $spaceNumber.text)
                        .autocorrectionDisabled()
                }

                Section("Common.Position") {
                    Picker("Common.Position", selection: $spaceNumber.position) {
                        ForEach(SpaceNumberPosition.allCases, id: \.self) { pos in
                            Text(pos.localizedName).tag(pos)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("SpaceNumber.Style") {
                    FontPickerRow(selectedFontName: $spaceNumber.fontName, label: String(localized: "Common.Font"))
                    HStack {
                        Text("Common.Size")
                        Spacer()
                        Stepper("\(Int(spaceNumber.fontSize)) pt", value: $spaceNumber.fontSize, in: 6...72, step: 1)
                    }
                    ColorPickerRow(title: String(localized: "Common.Color"), color: $spaceNumber.color)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "SpaceNumber.Title"))
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
