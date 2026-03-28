import SwiftUI
import SwiftData

// MARK: - Navigation Tags

struct NewProjectTag: Hashable {}

// MARK: - Editor Destination

struct EditorDestination: View {
    let savedCut: SavedCut?
    @State private var vm = EditorState()
    @State private var autoSaveTask: Task<Void, Never>?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        EditorView(vm: vm)
            .onAppear {
                guard let savedCut, vm.currentSavedCutID == nil else { return }
                try? vm.loadSavedCut(savedCut)
            }
            .onDisappear {
                autoSaveTask?.cancel()
                autoSave()
            }
            .onChange(of: vm.documentRevision) {
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
        let thumbnailImage = renderer.render(document: vm.document)
        let thumbnailData = thumbnailImage?
            .preparingThumbnail(of: CGSize(width: 112, height: 112))?
            .jpegData(compressionQuality: 0.7)

        do {
            if let existingID = vm.currentSavedCutID {
                let predicate = #Predicate<SavedCut> { $0.id == existingID }
                let descriptor = FetchDescriptor<SavedCut>(predicate: predicate)
                if let existing = try modelContext.fetch(descriptor).first {
                    try existing.updateDocument(vm.document)
                    existing.thumbnailData = thumbnailData
                }
            } else if !vm.document.layers.isEmpty || vm.document.backgroundImage != nil {
                let name = vm.currentSavedCutName.isEmpty
                    ? vm.document.template.localizedDisplayName
                    : vm.currentSavedCutName
                let newCut = try SavedCut(name: name, document: vm.document)
                newCut.thumbnailData = thumbnailData
                modelContext.insert(newCut)
                vm.currentSavedCutID = newCut.id
                vm.currentSavedCutName = newCut.name
            }
        } catch {
            // Encoding error — unlikely
        }
    }
}
