import SwiftUI
import SwiftData

// MARK: - Navigation Tags

struct NewProjectTag: Hashable {
    var circleName: String = ""
}

// MARK: - Editor Destination

struct EditorDestination: View {
    let savedCut: SavedCut?
    var circleName: String = ""
    @State private var editor = EditorState()
    @State private var autoSaveTask: Task<Void, Never>?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        EditorView(editor: editor)
            .onAppear {
                if let savedCut, editor.currentSavedCutID == nil {
                    try? editor.loadSavedCut(savedCut)
                } else if savedCut == nil && !circleName.isEmpty && editor.document.circleName.isEmpty {
                    editor.document.circleName = circleName
                    editor.currentSavedCutName = circleName
                }
            }
            .onDisappear {
                autoSaveTask?.cancel()
                autoSave()
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
            let maxDimension: CGFloat = 224
            let aspect = image.size.width / image.size.height
            let thumbSize: CGSize
            if aspect > 1 {
                thumbSize = CGSize(width: maxDimension, height: maxDimension / aspect)
            } else {
                thumbSize = CGSize(width: maxDimension * aspect, height: maxDimension)
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let thumb = UIGraphicsImageRenderer(size: thumbSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: thumbSize))
            }
            return thumb.jpegData(compressionQuality: 0.7)
        }

        do {
            if let existingID = editor.currentSavedCutID {
                let predicate = #Predicate<SavedCut> { $0.id == existingID }
                let descriptor = FetchDescriptor<SavedCut>(predicate: predicate)
                if let existing = try modelContext.fetch(descriptor).first {
                    try existing.updateDocument(editor.document)
                    existing.name = editor.document.circleName.isEmpty
                        ? String(localized: "Projects.Untitled")
                        : editor.document.circleName
                    existing.thumbnailData = thumbnailData
                }
            } else if !editor.document.layers.isEmpty || editor.document.backgroundImage != nil {
                let name = editor.document.circleName.isEmpty
                    ? String(localized: "Projects.Untitled")
                    : editor.document.circleName
                let newCut = try SavedCut(name: name, document: editor.document)
                newCut.thumbnailData = thumbnailData
                modelContext.insert(newCut)
                editor.currentSavedCutID = newCut.id
                editor.currentSavedCutName = newCut.name
            }
        } catch {
            // Encoding error — unlikely
        }
    }
}
