import SwiftUI

// MARK: - Project Settings View

/// Shows canvas size and other project-level settings.
struct ProjectSettingsView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
                    Text("\(Int(vm.document.template.canvasSize.width)) \u{00D7} \(Int(vm.document.template.canvasSize.height)) px")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "Project.Title"))
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
