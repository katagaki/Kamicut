import SwiftUI
import SwiftData

// MARK: - Navigation Tags

struct NewProjectTag: Hashable {}

// MARK: - Editor Destination

struct EditorDestination: View {
    let savedCut: SavedCut?
    @State private var editor = EditorState()
    @State private var autoSaveTask: Task<Void, Never>?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        EditorView(editor: editor)
            .onAppear {
                guard let savedCut, editor.currentSavedCutID == nil else { return }
                try? editor.loadSavedCut(savedCut)
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
        let thumbnailData = thumbnailImage?
            .preparingThumbnail(of: CGSize(width: 112, height: 112))?
            .jpegData(compressionQuality: 0.7)

        do {
            if let existingID = editor.currentSavedCutID {
                let predicate = #Predicate<SavedCut> { $0.id == existingID }
                let descriptor = FetchDescriptor<SavedCut>(predicate: predicate)
                if let existing = try modelContext.fetch(descriptor).first {
                    try existing.updateDocument(editor.document)
                    existing.thumbnailData = thumbnailData
                }
            } else if !editor.document.layers.isEmpty || editor.document.backgroundImage != nil {
                let name = editor.currentSavedCutName.isEmpty
                    ? editor.document.template.localizedDisplayName
                    : editor.currentSavedCutName
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
