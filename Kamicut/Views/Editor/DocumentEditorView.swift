import SwiftUI

// MARK: - Document Editor View

/// Bridges the CutDocument (ReferenceFileDocument) to the EditorView.
struct DocumentEditorView: View {
    @ObservedObject var document: CutDocument
    @Environment(\.undoManager) private var undoManager
    @State private var showCircleNameAlert = false
    @State private var circleNameInput = ""
    @State private var hasPromptedForName = false

    var body: some View {
        EditorView(editor: document.editorState)
            .onAppear {
                if !hasPromptedForName && document.editorState.document.circleName.isEmpty {
                    circleNameInput = ""
                    showCircleNameAlert = true
                    hasPromptedForName = true
                }
            }
            .onChange(of: document.editorState.documentRevision) {
                undoManager?.registerUndo(withTarget: document) { _ in }
            }
            .alert(String(localized: "Projects.NewProject"), isPresented: $showCircleNameAlert) {
                TextField(String(localized: "Document.CircleName"), text: $circleNameInput)
                Button(String(localized: "Common.Create")) {
                    let trimmed = circleNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        document.editorState.document.circleName = trimmed
                    }
                }
            } message: {
                Text(String(localized: "Projects.EnterCircleName"))
            }
            .navigationTitle(document.editorState.document.circleName.isEmpty
                ? String(localized: "App.Name")
                : document.editorState.document.circleName)
    }
}
