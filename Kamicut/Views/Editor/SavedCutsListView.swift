import SwiftUI

struct SavedCutsListView: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss
    private let storageManager = CutStorageManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        saveCurrent()
                    } label: {
                        Label(String(localized: "SavedCuts.SaveCurrent"), systemImage: "square.and.arrow.down")
                    }
                }

                if !storageManager.cuts.isEmpty {
                    Section(String(localized: "SavedCuts.Title")) {
                        ForEach(storageManager.cuts) { cut in
                            Button {
                                loadCut(cut)
                            } label: {
                                HStack(spacing: 12) {
                                    if let thumbData = cut.thumbnailData,
                                       let img = UIImage(data: thumbData) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    } else {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                Image(systemName: "doc.richtext")
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cut.name)
                                            .foregroundStyle(.primary)
                                        Text(cut.updatedAt, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteCuts)
                    }
                }
            }
            .navigationTitle(String(localized: "SavedCuts.Title"))
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

    // MARK: - Actions

    private func saveCurrent() {
        let name = editor.document.circleName.isEmpty
            ? String(localized: "Projects.Untitled")
            : editor.document.circleName
        do {
            if let existingURL = editor.currentPackageURL {
                _ = try storageManager.saveDocument(
                    editor.document,
                    name: name,
                    existingPackageURL: existingURL
                )
                editor.currentSavedCutName = name
            } else {
                let url = try storageManager.saveDocument(
                    editor.document,
                    name: name
                )
                editor.currentPackageURL = url
                editor.currentSavedCutName = name
            }
            storageManager.loadAllCuts()
        } catch {
            // Encoding error — unlikely
        }
    }

    private func loadCut(_ cut: CutListItem) {
        do {
            let document = try storageManager.loadDocument(from: cut.packageURL)
            editor.document = document
            editor.currentPackageURL = cut.packageURL
            editor.currentSavedCutName = cut.name
            editor.selectedImageID = nil
            editor.selectedTextID = nil
            editor.selectedShapeID = nil
            editor.exportedImage = nil
            dismiss()
        } catch {
            // Decoding error
        }
    }

    private func deleteCuts(at offsets: IndexSet) {
        let cutsList = storageManager.cuts
        for index in offsets {
            let cut = cutsList[index]
            if editor.currentPackageURL == cut.packageURL {
                editor.currentPackageURL = nil
                editor.currentSavedCutName = ""
            }
            storageManager.deleteCut(at: cut.packageURL)
        }
    }
}
