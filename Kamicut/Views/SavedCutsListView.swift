import SwiftUI
import SwiftData

struct SavedCutsListView: View {
    @Bindable var vm: EditorState
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
                        newCutName = vm.currentSavedCutName.isEmpty
                            ? vm.document.template.localizedDisplayName
                            : vm.currentSavedCutName
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Shared.Close")) {
                        dismiss()
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
            if let existingID = vm.currentSavedCutID,
               let existing = savedCuts.first(where: { $0.id == existingID }) {
                try existing.updateDocument(vm.document)
                existing.name = newCutName
                vm.currentSavedCutName = newCutName
            } else {
                let newCut = try SavedCut(name: newCutName, document: vm.document)
                modelContext.insert(newCut)
                vm.currentSavedCutID = newCut.id
                vm.currentSavedCutName = newCut.name
            }
        } catch {
            // Encoding error — unlikely given existing Codable conformance
        }
    }

    private func loadCut(_ cut: SavedCut) {
        do {
            try vm.loadSavedCut(cut)
            dismiss()
        } catch {
            // Decoding error
        }
    }

    private func deleteCuts(at offsets: IndexSet) {
        for index in offsets {
            let cut = savedCuts[index]
            if vm.currentSavedCutID == cut.id {
                vm.currentSavedCutID = nil
                vm.currentSavedCutName = ""
            }
            modelContext.delete(cut)
        }
    }
}
