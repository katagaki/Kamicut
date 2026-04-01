import Photos
import SwiftUI

// MARK: - Export Sheet View

struct ExportSheetView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss

    @State private var isSavingToPhotos = false
    @State private var savedToPhotos = false
    @State private var saveToPhotosError = false

    private let renderer = CircleCutRenderer()

    var body: some View {
        NavigationStack {
            Form {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        if let exported = editor.exportedImage {
                            Image(uiImage: exported)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(4)
                        } else {
                            let preview = renderer.render(document: editor.document)
                            if let preview {
                                Image(uiImage: preview)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(4)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // Export buttons
                Section {
                    Button {
                        Task { await doExport() }
                    } label: {
                        HStack {
                            Spacer()
                            if editor.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Export.Rendering")
                            } else {
                                Label("Export.Export", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(editor.isExporting || isSavingToPhotos)

                    Button {
                        Task { await saveToPhotos() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSavingToPhotos {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Export.Rendering")
                            } else if savedToPhotos {
                                Label("Export.SavedToPhotos", systemImage: "checkmark.circle.fill")
                                    .fontWeight(.semibold)
                            } else {
                                Label("Export.SaveToPhotos", systemImage: "photo.on.rectangle.angled")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(editor.isExporting || isSavingToPhotos || savedToPhotos)
                }

                // Format
                Section("Export.Format") {
                    Picker("Export.FileFormat", selection: $editor.document.exportSettings.format) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.localizedName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if editor.document.exportSettings.format == .jpg {
                        HStack {
                            Text("Export.JpegQuality")
                            Spacer()
                            Text("\(Int(editor.document.exportSettings.jpegQuality * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $editor.document.exportSettings.jpegQuality, in: 0.1...1.0, step: 0.05)
                    }
                }

                // Color Mode
                Section("Export.ColorMode") {
                    Picker("Export.ColorMode", selection: $editor.document.exportSettings.colorMode) {
                        ForEach(ExportColorMode.allCases) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Resolution
                Section("Export.Resolution") {
                    Picker("Export.Resolution", selection: $editor.document.exportSettings.resolution) {
                        ForEach(ExportResolution.allCases) { res in
                            Text(res.label).tag(res)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "Toolbar.Export"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button(role: .cancel) { dismiss() } label: { Text("Common.Close") }
                    }
                }
            }
        }
        .alert("Export.SaveToPhotosFailed", isPresented: $saveToPhotosError) {
            Button("OK") { }
        }
    }

    private func saveToPhotos() async {
        isSavingToPhotos = true
        defer { isSavingToPhotos = false }

        guard let image = await editor.exportImage(renderer: renderer) else {
            saveToPhotosError = true
            return
        }

        let settings = editor.exportSettings
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                if settings.format == .jpg {
                    let data = image.jpegData(compressionQuality: settings.jpegQuality) ?? Data()
                    request.addResource(with: .photo, data: data, options: nil)
                } else {
                    let data = image.pngData() ?? Data()
                    request.addResource(with: .photo, data: data, options: nil)
                }
            }
            savedToPhotos = true
        } catch {
            saveToPhotosError = true
        }
    }

    private func doExport() async {
        guard let image = await editor.exportImage(renderer: renderer) else { return }
        let settings = editor.exportSettings
        let activityItems: [Any]
        if settings.format == .jpg {
            let data = image.jpegData(compressionQuality: settings.jpegQuality) ?? Data()
            activityItems = [data]
        } else {
            activityItems = [image]
        }
        await MainActor.run {
            let activityController = UIActivityViewController(
                activityItems: activityItems, applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                var presenter = root
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                activityController.popoverPresentationController?.sourceView = presenter.view
                presenter.present(activityController, animated: true)
            }
        }
    }
}
