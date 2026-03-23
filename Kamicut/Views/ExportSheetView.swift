import SwiftUI

// MARK: - Export Sheet View

struct ExportSheetView: View {
    @Bindable var vm: EditorState
    @Environment(\.dismiss) private var dismiss

    private let renderer = CircleCutRenderer()

    var body: some View {
        NavigationStack {
            Form {
                // Format
                Section("Format") {
                    Picker("File Format", selection: $vm.document.exportSettings.format) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if vm.document.exportSettings.format == .jpg {
                        HStack {
                            Text("JPEG Quality")
                            Spacer()
                            Text("\(Int(vm.document.exportSettings.jpegQuality * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $vm.document.exportSettings.jpegQuality, in: 0.1...1.0, step: 0.05)
                    }
                }

                // Color Mode
                Section("Color Mode") {
                    Picker("Color Mode", selection: $vm.document.exportSettings.colorMode) {
                        ForEach(ExportColorMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Resolution
                Section("Resolution") {
                    Picker("Resolution", selection: $vm.document.exportSettings.resolution) {
                        ForEach(ExportResolution.allCases) { res in
                            Text(res.label).tag(res)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // Export size info
                Section {
                    let w = Int(vm.document.template.canvasSize.width)
                    let h = Int(vm.document.template.canvasSize.height)
                    HStack {
                        Label("Output size", systemImage: "ruler")
                        Spacer()
                        Text("\(w) × \(h) px")
                            .foregroundColor(.secondary)
                    }
                }

                // Export button
                Section {
                    Button {
                        Task { await doExport() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Rendering…")
                            } else {
                                Label("Export & Share", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(vm.isExporting)
                }

                // Preview
                if let exported = vm.exportedImage {
                    Section("Preview") {
                        Image(uiImage: exported)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(4)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: { Text("Close") }
                }
            }
        }
    }

    private func doExport() async {
        guard let image = await vm.exportImage(renderer: renderer) else { return }
        let settings = vm.exportSettings
        let activityItems: [Any]
        if settings.format == .jpg {
            let data = image.jpegData(compressionQuality: settings.jpegQuality) ?? Data()
            activityItems = [data]
        } else {
            activityItems = [image]
        }
        await MainActor.run {
            let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                var presenter = root
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                vc.popoverPresentationController?.sourceView = presenter.view
                presenter.present(vc, animated: true)
            }
        }
    }
}
