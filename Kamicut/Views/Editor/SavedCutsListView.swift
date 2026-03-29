import SwiftUI
import SwiftData

struct SavedCutsListView: View {
    @Bindable var editor: EditorState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedCut.updatedAt, order: .reverse) private var savedCuts: [SavedCut]

    @State private var newCutName: String = ""
    @State private var showingSaveAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        newCutName = editor.currentSavedCutName.isEmpty
                            ? editor.document.template.localizedDisplayName
                            : editor.currentSavedCutName
                        showingSaveAlert = true
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
            .alert(String(localized: "SavedCuts.SaveAlert.Title"), isPresented: $showingSaveAlert) {
                TextField(String(localized: "SavedCuts.SaveAlert.Placeholder"), text: $newCutName)
                Button(String(localized: "SavedCuts.SaveAlert.Save")) {
                    saveCurrent()
                }
                Button(String(localized: "SavedCuts.SaveAlert.Cancel"), role: .cancel) { }
            }
        }
    }

    // MARK: - Actions

    private func saveCurrent() {
        do {
            if let existingID = editor.currentSavedCutID,
               let existing = savedCuts.first(where: { $0.id == existingID }) {
                try existing.updateDocument(editor.document)
                existing.name = newCutName
                editor.currentSavedCutName = newCutName
            } else {
                let newCut = try SavedCut(name: newCutName, document: editor.document)
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
