import SwiftUI
import SwiftData

struct SavedCutsListView: View {
    @Bindable var editor: EditorState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedCut.updatedAt, order: .reverse) private var savedCuts: [SavedCut]

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

                if !savedCuts.isEmpty {
                    Section(String(localized: "SavedCuts.Title")) {
                        ForEach(savedCuts) { cut in
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
            if let existingID = editor.currentSavedCutID,
               let existing = savedCuts.first(where: { $0.id == existingID }) {
                try existing.updateDocument(editor.document)
                existing.name = name
                editor.currentSavedCutName = name
            } else {
                let newCut = try SavedCut(name: name, document: editor.document)
                modelContext.insert(newCut)
                editor.currentSavedCutID = newCut.id
                editor.currentSavedCutName = newCut.name
            }
        } catch {
            // Encoding error — unlikely given existing Codable conformance
        }
    }

    private func loadCut(_ cut: SavedCut) {
        do {
            try editor.loadSavedCut(cut)
            dismiss()
        } catch {
            // Decoding error
        }
    }

    private func deleteCuts(at offsets: IndexSet) {
        for index in offsets {
            let cut = savedCuts[index]
            if editor.currentSavedCutID == cut.id {
                editor.currentSavedCutID = nil
                editor.currentSavedCutName = ""
            }
            modelContext.delete(cut)
        }
    }
}
