import SwiftUI

// MARK: - Document Editor View

/// Bridges the CutDocument (ReferenceFileDocument) to the EditorView.
struct DocumentEditorView: View {
    @ObservedObject var document: CutDocument
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        EditorView(editor: document.editorState)
            .onChange(of: document.editorState.documentRevision) {
                // Register a change with the undo manager so DocumentGroup
                // knows the document is dirty and triggers a save.
                undoManager?.registerUndo(withTarget: document) { _ in }
            }
    }
}
