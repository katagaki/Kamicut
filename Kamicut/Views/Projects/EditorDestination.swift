import SwiftUI

// MARK: - Navigation Tags

struct NewProjectTag: Hashable {
    var circleName: String = ""
}

// MARK: - Editor Destination

struct EditorDestination: View {
    let cutItem: CutListItem?
    var circleName: String = ""
    @State private var editor = EditorState()
    @State private var autoSaveTask: Task<Void, Never>?
    private let storageManager = CutStorageManager.shared

    var body: some View {
        EditorView(editor: editor)
            .onAppear {
                if let cutItem, editor.currentPackageURL == nil {
                    if let doc = try? storageManager.loadDocument(from: cutItem.packageURL) {
                        editor.document = doc
                        editor.currentPackageURL = cutItem.packageURL
                        editor.currentSavedCutName = cutItem.name
                        editor.documentRevision = 0
                    }
                } else if cutItem == nil && !circleName.isEmpty && editor.document.circleName.isEmpty {
                    editor.document.circleName = circleName
                    editor.currentSavedCutName = circleName
                }
            }
            .onDisappear {
                autoSaveTask?.cancel()
                autoSave()
                storageManager.loadAllCuts()
            }
            .onChange(of: editor.documentRevision) {
                autoSaveTask?.cancel()
                autoSaveTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    autoSave()
                }
            }
    }

    private func autoSave() {
        // Generate thumbnail
        let renderer = CircleCutRenderer()
        let thumbnailImage = renderer.render(document: editor.document)
        let thumbnailData: Data? = thumbnailImage.flatMap { image in
            let maxDimension: CGFloat = 512
            let aspect = image.size.width / image.size.height
            let thumbSize: CGSize
            if aspect > 1 {
                thumbSize = CGSize(width: maxDimension, height: (maxDimension / aspect).rounded(.down))
            } else {
                thumbSize = CGSize(width: (maxDimension * aspect).rounded(.down), height: maxDimension)
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let thumb = UIGraphicsImageRenderer(size: thumbSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: thumbSize))
            }
            return thumb.jpegData(compressionQuality: 0.7)
        }

        do {
            let name = editor.document.circleName.isEmpty
                ? String(localized: "Projects.Untitled")
                : editor.document.circleName

            if let existingURL = editor.currentPackageURL {
                _ = try storageManager.saveDocument(
                    editor.document,
                    name: name,
                    existingPackageURL: existingURL,
                    thumbnailData: thumbnailData
                )
            } else if !editor.document.layers.isEmpty || editor.document.backgroundImage != nil {
                let url = try storageManager.saveDocument(
                    editor.document,
                    name: name,
                    thumbnailData: thumbnailData
                )
                editor.currentPackageURL = url
                editor.currentSavedCutName = name
            }
        } catch {
            // Save error — unlikely
        }
    }
}
