import SwiftUI

// MARK: - Document Editor View

/// Bridges the CutDocument (ReferenceFileDocument) to the EditorView.
struct DocumentEditorView: View {
    @ObservedObject var document: CutDocument
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        EditorView(editor: document.editorState)
            .onChange(of: document.editorState.documentRevision) {
                undoManager?.registerUndo(withTarget: document) { _ in }
            }
    }
}
